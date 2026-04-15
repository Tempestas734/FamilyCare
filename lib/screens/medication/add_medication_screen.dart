import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({
    super.key,
    this.preselectedMemberId,
  });

  final String? preselectedMemberId;

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _nameController = TextEditingController();
  final _dosageValueController = TextEditingController();
  final _intakeAmountController = TextEditingController(text: '1');
  final _stockController = TextEditingController();
  final _thresholdController = TextEditingController();

  String _dosageUnit = 'mg';
  int _selectedMember = -1; // -1 = Famille (global), >=0 = member index
  bool _reminderEnabled = false;
  String _frequency = 'daily';
  List<TimeOfDay> _times = const [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)];
  String _intakeUnit = 'Comprime(s)';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _familyId;
  bool _saving = false;

  List<_Member> _members = const [];
  bool _loadingMembers = true;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => _loadingMembers = false);
      return;
    }

    try {
      final familyRow = await Supabase.instance.client
          .from('family_members')
          .select('family_id')
          .eq('auth_user_id', user.id)
          .limit(1)
          .maybeSingle();

      final familyId = familyRow?['family_id']?.toString();
      if (familyId == null || familyId.isEmpty) {
        if (!mounted) return;
        setState(() => _loadingMembers = false);
        return;
      }

      final rows = await Supabase.instance.client
          .from('family_members')
          .select('id, full_name, role')
          .eq('family_id', familyId)
          .order('created_at');

      final members = (rows as List)
          .cast<Map<String, dynamic>>()
          .map(
            (m) => _Member(
              id: m['id']?.toString() ?? '',
              name: (m['full_name']?.toString().trim().isNotEmpty == true)
                  ? m['full_name'].toString()
                  : 'Membre',
              avatarUrl: _roleAvatarUrl(m['role']?.toString()),
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _familyId = familyId;
        _members = members;
        final preselected = widget.preselectedMemberId;
        if (preselected != null && preselected.isNotEmpty) {
          _selectedMember =
              members.indexWhere((member) => member.id == preselected);
          if (_selectedMember < 0) {
            _selectedMember = -1;
          }
        } else {
          _selectedMember = -1;
        }
        _loadingMembers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMembers = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageValueController.dispose();
    _intakeAmountController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      _times = [..._times, picked]..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );
    });
  }

  DateTime _safeDate(DateTime? date) => date ?? DateTime.now();

  String _toYmd(DateTime? date) {
    final safe = _safeDate(date);
    final y = safe.year.toString().padLeft(4, '0');
    final m = safe.month.toString().padLeft(2, '0');
    final d = safe.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _toPgTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _safeDate(isStart ? _startDate : _endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        final end = _safeDate(_endDate);
        if (end.isBefore(_safeDate(_startDate))) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _saveMedication() async {
    if (_saving) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non connecte')),
      );
      return;
    }

    final familyId = _familyId;
    if (familyId == null || familyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Famille introuvable')),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom du medicament requis')),
      );
      return;
    }

    if (_reminderEnabled && _safeDate(_endDate).isBefore(_safeDate(_startDate))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date de fin invalide')),
      );
      return;
    }

    if (_reminderEnabled && _times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute au moins une heure de prise')),
      );
      return;
    }

    final dosageValue = _dosageValueController.text.trim();
    final dosagePerUnit = dosageValue.isEmpty ? null : '$dosageValue $_dosageUnit';
    final stockQuantity = double.tryParse(_stockController.text.trim()) ?? 0;
    final minStockAlert = double.tryParse(_thresholdController.text.trim()) ?? 0;
    final intakeAmount = double.tryParse(_intakeAmountController.text.trim());

    final targetMemberIds = _selectedMember == -1
        ? _members.map((m) => m.id).where((id) => id.isNotEmpty).toList()
        : (_selectedMember >= 0 && _selectedMember < _members.length)
            ? [_members[_selectedMember].id]
            : <String>[];

    if (_reminderEnabled && targetMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectionne au moins un membre')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final medicationRow = await Supabase.instance.client
          .from('family_medications')
          .insert({
            'family_id': familyId,
            'name': name,
            'dosage_per_unit': dosagePerUnit,
            'stock_quantity': stockQuantity,
            'stock_unit': _intakeUnit,
            'min_stock_alert': minStockAlert,
            'created_by': user.id,
          })
          .select('id')
          .single();

      final medicationId = medicationRow['id']?.toString();
      if (_reminderEnabled && medicationId != null && medicationId.isNotEmpty) {
        final plans = targetMemberIds
            .map(
              (memberId) => {
                'family_id': familyId,
                'medication_id': medicationId,
                'member_id': memberId,
                'intake_amount': intakeAmount,
                'intake_unit': _intakeUnit,
                'frequency_type': _frequency == 'weekly' ? 'weekly' : 'daily',
                'times': _times.map(_toPgTime).toList(),
                'start_date': _toYmd(_startDate),
                'end_date': _toYmd(_endDate),
                'duration_days':
                    _safeDate(_endDate).difference(_safeDate(_startDate)).inDays + 1,
                'status': 'active',
                'created_by': user.id,
              },
            )
            .toList();

        final insertedPlans = await Supabase.instance.client
            .from('family_medication_plans')
            .insert(plans)
            .select('id');

        final planIds = (insertedPlans as List)
            .map((e) => (e as Map<String, dynamic>)['id']?.toString())
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList();

        final fromDate = _toYmd(_startDate);
        final toDate = _toYmd(_endDate);
        for (final planId in planIds) {
          await Supabase.instance.client.rpc(
            'generate_doses_for_plan',
            params: {
              'p_plan_id': planId,
              'p_from': fromDate,
              'p_to': toDate,
            },
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicament enregistre')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur enregistrement: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F6F8),
      textTheme: ThemeData.light().textTheme.copyWith(
            headlineSmall: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF140D1B),
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF140D1B),
            ),
            bodyMedium: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF140D1B),
            ),
            bodySmall: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E5B7A),
            ),
          ),
    );

    return Theme(
      data: lightTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final primary = theme.colorScheme.primary;
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor:
                          theme.scaffoldBackgroundColor.withOpacity(0.9),
                      elevation: 0,
                      leadingWidth: 64,
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.chevron_left, color: primary),
                        ),
                      ),
                      title: Text(
                        'Ajouter un medicament',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D0A4E),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Nom du medicament'),
                            _InputField(
                              controller: _nameController,
                              hint: 'ex: Doliprane',
                            ),
                            const SizedBox(height: 14),
                            _Label('Dosage'),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _InputField(
                                    controller: _dosageValueController,
                                    hint: 'ex: 500',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _SelectField(
                                    value: _dosageUnit,
                                    values: const ['mg', 'ml', 'g', 'Unite(s)', 'Goutte(s)', 'Sachet(s)'],
                                    onChanged: (value) => setState(() => _dosageUnit = value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _Label('Pour qui ?'),
                            SizedBox(
                              height: 88,
                              child: _loadingMembers
                                  ? const Center(child: CircularProgressIndicator())
                                  : _members.isEmpty
                                      ? Center(
                                          child: Text(
                                            'Aucun membre de famille trouve',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        )
                                      : ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _members.length + 1,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(width: 12),
                                          itemBuilder: (context, index) {
                                            if (index == 0) {
                                              final isSelected = _selectedMember == -1;
                                              return InkWell(
                                                onTap: () =>
                                                    setState(() => _selectedMember = -1),
                                                borderRadius: BorderRadius.circular(30),
                                                child: Opacity(
                                                  opacity: isSelected ? 1 : 0.55,
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        width: 56,
                                                        height: 56,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: primary.withOpacity(0.12),
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? primary
                                                                : Colors.transparent,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        child: Icon(
                                                          Icons.groups,
                                                          color: primary,
                                                          size: 28,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        'Famille',
                                                        style: theme.textTheme.bodySmall?.copyWith(
                                                          color: isSelected
                                                              ? primary
                                                              : Colors.black54,
                                                          fontWeight: isSelected
                                                              ? FontWeight.w700
                                                              : FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }

                                            final memberIndex = index - 1;
                                            final member = _members[memberIndex];
                                            final isSelected = _selectedMember == memberIndex;
                                            return InkWell(
                                              onTap: () =>
                                                  setState(() => _selectedMember = memberIndex),
                                              borderRadius: BorderRadius.circular(30),
                                              child: Opacity(
                                                opacity: isSelected ? 1 : 0.55,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      width: 56,
                                                      height: 56,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? primary
                                                              : Colors.transparent,
                                                          width: 2,
                                                        ),
                                                        image: DecorationImage(
                                                          image: NetworkImage(member.avatarUrl),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      member.name,
                                                      style: theme.textTheme.bodySmall?.copyWith(
                                                        color: isSelected
                                                            ? primary
                                                            : Colors.black54,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                            ),
                            const SizedBox(height: 20),
                            _SectionCard(
                              icon: Icons.notifications_active,
                              title: 'Planifier un rappel',
                              subtitle: 'Activer les notifications de prise',
                              trailing: Switch(
                                value: _reminderEnabled,
                                onChanged: (v) => setState(() => _reminderEnabled = v),
                              ),
                              child: _reminderEnabled
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _SmallLabel('Frequence'),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _ChoiceButton(
                                                selected: _frequency == 'daily',
                                                label: 'Quotidien',
                                                icon: Icons.calendar_today,
                                                onTap: () => setState(() => _frequency = 'daily'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _ChoiceButton(
                                                selected: _frequency == 'weekly',
                                                label: 'Hebdomadaire',
                                                icon: Icons.date_range,
                                                onTap: () => setState(() => _frequency = 'weekly'),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        _SmallLabel('Heures de prise'),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            for (int i = 0; i < _times.length; i++)
                                              _TimeChip(
                                                time: _times[i].format(context),
                                                onRemove: () {
                                                  setState(() {
                                                    _times = [..._times]..removeAt(i);
                                                  });
                                                },
                                              ),
                                            OutlinedButton.icon(
                                              onPressed: _addTime,
                                              icon: const Icon(Icons.add, size: 16),
                                              label: const Text('Ajouter'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        _SmallLabel('Quantite par prise'),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _InputField(
                                                controller: _intakeAmountController,
                                                hint: '1',
                                                keyboardType: TextInputType.number,
                                                dense: true,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _SelectField(
                                                value: _intakeUnit,
                                                values: const [
                                                  'Comprime(s)',
                                                  'Gelule(s)',
                                                  'ml',
                                                  'Goutte(s)',
                                                  'Sachet(s)',
                                                  'Unite(s)',
                                                ],
                                                onChanged: (value) =>
                                                    setState(() => _intakeUnit = value),
                                                dense: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        _SmallLabel('Periode du traitement'),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    _pickDate(isStart: true),
                                                icon: const Icon(Icons.calendar_today, size: 16),
                                                label: Text('Debut ${_toYmd(_startDate)}'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () =>
                                                    _pickDate(isStart: false),
                                                icon: const Icon(Icons.event, size: 16),
                                                label: Text('Fin ${_toYmd(_endDate)}'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        'Rappel desactive',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            _SectionCard(
                              icon: Icons.inventory_2,
                              title: 'Stock actuel',
                              subtitle: 'Gerer l\'inventaire restant',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SmallLabel('Nombre d\'unites (pilules, sachets...)'),
                                  _InputField(
                                    controller: _stockController,
                                    hint: 'ex: 30',
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 12),
                                  _SmallLabel('Seuil d\'alerte'),
                                  _InputField(
                                    controller: _thresholdController,
                                    hint: 'Alerte si < 5',
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Vous recevrez une notification quand votre stock atteint ce seuil.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.black45,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.scaffoldBackgroundColor.withOpacity(0),
                          theme.scaffoldBackgroundColor.withOpacity(0.96),
                          theme.scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _saving ? null : _saveMedication,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Enregistrer',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Member {
  const _Member({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
  final String id;
  final String name;
  final String avatarUrl;
}

String _roleAvatarUrl(String? role) {
  switch (role) {
    case 'pere':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuCqrdt8Y2LDzW4L2OBgbaWMLUFtzv5wsTxRXsTenIk5--Sn09sN8kf5DT5ICS1y9U8cj3QfNVyf24wGEV2thzTAdGSIPCUr4594VL3QdZvIj95Fa4ANu0m2HwJER9skr5lYbnns-DBHiuWuOfG7buIYYRaMg7gtc8TfCwuhQ2q6I6yotGv-HoAGGuL_EJl2sY0IQyyKi-lNh3Dd8aY75M6Vj0IiG6Tvl19N2CKNb9NxPNbp44T75SA-jgZON8hK9EU9-kY63ujD5hX6';
    case 'mere':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBQxpRgAwFX7Yg7n0PKxM8vX2Rrgx49tPHzdT2CCM0g2eQSuRtrpCv6b0lV0YP0YJ3eu1Bp5mqjrcWJfVj56Q24-nX9q3I84JwqJu8yHI6TV8SH4rfd1k3YlTQ27nV8x4NkOnaVrkUZfP5n5W8YgC8Mdp3LRzAwLrLdm7sZ0x0T2hA9XG5x7fbFj3xjvE8xX2rA3m8V9KQ8K2c2aPpK8Yh2xW9xS0Yk5Q4Qm2qJ9a7A';
    case 'enfant':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuAY6lvv8vRlHNQMoa2s0mMoaM3skXYxHnaHvoDVleBFHpbJglmAFO7VEfP0QHrovrTAq1u3kn6U5b0SRZFWCrg1I2fz7TYylpVKPkCfJgOvnA2xPHJTtADDjIwkDAWPcdd2iKK3iXBUB2VCbV05PR2N92HQNEVJ-ASLkdakIGkKBgsqOyWyMO7brLfckgm0T_0nJOUxUjpmtxpAtJkY-jxrwkMRC_qvfEclUPcqNh2SaA4Tgfc-tLtfVUvCdCC9JQRF0Sa8jPVhw5TB';
    default:
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBdN7bnNU6TR1CS8DghMWvZEYmyFEcFM-Y2Y3Zbi6yGkt5BxqPWIqcvcsa_BEz3D7DAJFLONJiA2pOTpy01FupzCRhra6wPSCv5O74--2_2KmbgIs0-pr0dQOGNx2xiMpA2k4aMAtV84lVEWmrpgr5BE9ibi--RP_STU7IIjIHiecrDHZ7hfvPAtRTXZxw1VPqauniTeLK-eZF2GxtMoLSK1T7nIN8OAwxlap7KpqxWS_tww4z4uaqiaB6eghzdZWzzi9IEJXZHM2PT';
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D0A4E),
            ),
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.dense = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: dense ? 10 : 14,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.values,
    required this.onChanged,
    this.dense = false,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: dense ? 2 : 0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D0A4E),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black45,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing as Widget,
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.black12,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.black54,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.time, required this.onRemove});

  final String time;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
