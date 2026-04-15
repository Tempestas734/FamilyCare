import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import 'add_medication_screen.dart';
import '../calendar/calendar_screen.dart';
import '../home_screen.dart';
import '../settings_screen.dart';

class ManageMedicationsScreen extends StatefulWidget {
  const ManageMedicationsScreen({super.key});

  @override
  State<ManageMedicationsScreen> createState() => _ManageMedicationsScreenState();
}

class _ManageMedicationsScreenState extends State<ManageMedicationsScreen> {
  bool _loading = true;
  List<_MedicationRow> _rows = const [];
  List<_FamilyMember> _members = const [];
  String? _familyId;

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  Future<void> _loadRows() async {
    try {
      if (mounted) setState(() => _loading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _rows = const [];
          _members = const [];
          _loading = false;
        });
        return;
      }

      final familyRow = await Supabase.instance.client
          .from('family_members')
          .select('family_id')
          .eq('auth_user_id', user.id)
          .limit(1)
          .maybeSingle();

      final familyId = familyRow?['family_id']?.toString();
      if (familyId == null || familyId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _rows = const [];
          _members = const [];
          _loading = false;
        });
        return;
      }

      final membersData = await Supabase.instance.client
          .from('family_members')
          .select('id, full_name, role')
          .eq('family_id', familyId)
          .order('created_at');
      final members = (membersData as List)
          .cast<Map<String, dynamic>>()
          .map(
            (m) => _FamilyMember(
              id: m['id']?.toString() ?? '',
              fullName: (m['full_name']?.toString().trim().isNotEmpty == true)
                  ? m['full_name'].toString()
                  : 'Membre',
              role: m['role']?.toString(),
            ),
          )
          .where((m) => m.id.isNotEmpty)
          .toList();

      final medsData = await Supabase.instance.client
          .from('family_medications')
          .select('id, name, dosage_per_unit, is_active')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);

      final plansData = await Supabase.instance.client
          .from('family_medication_plans')
          .select('medication_id, member_id, times, status')
          .eq('family_id', familyId);

      final planRows = (plansData as List).cast<Map<String, dynamic>>();
      final medRows = (medsData as List).cast<Map<String, dynamic>>();

      final byMed = <String, List<Map<String, dynamic>>>{};
      for (final p in planRows) {
        final medId = p['medication_id']?.toString();
        if (medId == null || medId.isEmpty) continue;
        byMed.putIfAbsent(medId, () => []).add(p);
      }

      final memberById = {for (final m in members) m.id: m};
      final out = <_MedicationRow>[];
      for (final m in medRows) {
        final medId = m['id']?.toString() ?? '';
        if (medId.isEmpty) continue;
        final plans = byMed[medId] ?? const [];

        final timesSet = <String>{};
        final avatarUrls = <String>[];
        final seenMembers = <String>{};
        for (final p in plans) {
          if (p['status']?.toString() != 'active') continue;
          final rawTimes = (p['times'] is List) ? p['times'] as List : const [];
          for (final t in rawTimes) {
            final s = t.toString();
            if (s.length >= 5) timesSet.add(s.substring(0, 5));
          }
          final memberId = p['member_id']?.toString();
          if (memberId != null &&
              memberId.isNotEmpty &&
              seenMembers.add(memberId)) {
            avatarUrls.add(_avatarForRole(memberById[memberId]?.role));
          }
        }

        final sortedTimes = timesSet.toList()..sort();
        out.add(
          _MedicationRow(
            id: medId,
            name: (m['name']?.toString().trim().isNotEmpty == true)
                ? m['name'].toString()
                : 'Medicament',
            dosage: m['dosage_per_unit']?.toString(),
            isActive: m['is_active'] == true,
            times: sortedTimes,
            avatarUrls: avatarUrls.isEmpty ? [_avatarForRole(null)] : avatarUrls,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _familyId = familyId;
        _members = members;
        _rows = out;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteMedication(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce medicament ?'),
        content: const Text(
          'Cette action supprime aussi les plannings et prises liees.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await Supabase.instance.client.from('family_medications').delete().eq('id', id);
    await _loadRows();
  }

  Future<void> _reactivateMedication(String id) async {
    await Supabase.instance.client
        .from('family_medications')
        .update({'is_active': true})
        .eq('id', id);
    await _loadRows();
  }

  Future<void> _editPlanning(_MedicationRow row) async {
    final familyId = _familyId;
    final user = Supabase.instance.client.auth.currentUser;
    if (familyId == null || familyId.isEmpty || user == null) return;

    final plansData = await Supabase.instance.client
        .from('family_medication_plans')
        .select(
            'id, member_id, frequency_type, times, start_date, end_date, intake_amount, intake_unit, status')
        .eq('family_id', familyId)
        .eq('medication_id', row.id)
        .eq('status', 'active');

    final plans = (plansData as List).cast<Map<String, dynamic>>();
    final selectedMemberIds = plans
        .map((p) => p['member_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final first = plans.isNotEmpty ? plans.first : <String, dynamic>{};
    var frequency = (first['frequency_type']?.toString() == 'weekly') ? 'weekly' : 'daily';
    var times = _timesFromRaw(first['times']);
    if (times.isEmpty) {
      times = row.times
          .map(_parseHm)
          .whereType<TimeOfDay>()
          .toList();
    }
    if (times.isEmpty) {
      times = const [TimeOfDay(hour: 8, minute: 0)];
    }
    var startDate = DateTime.tryParse(first['start_date']?.toString() ?? '') ?? DateTime.now();
    var endDate = DateTime.tryParse(first['end_date']?.toString() ?? '') ??
        startDate.add(const Duration(days: 7));
    var intakeAmount = double.tryParse(first['intake_amount']?.toString() ?? '');
    var intakeUnit = first['intake_unit']?.toString() ?? 'Comprime(s)';

    final memberSelection = <String, bool>{
      for (final m in _members) m.id: selectedMemberIds.contains(m.id),
    };
    if (!memberSelection.containsValue(true) && _members.isNotEmpty) {
      memberSelection[_members.first.id] = true;
    }

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            Future<void> pickDate(bool isStart) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: isStart ? startDate : endDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked == null) return;
              setDialog(() {
                if (isStart) {
                  startDate = picked;
                  if (endDate.isBefore(startDate)) endDate = startDate;
                } else {
                  endDate = picked;
                }
              });
            }

            Future<void> addTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 12, minute: 0),
              );
              if (picked == null) return;
              setDialog(() {
                times = [...times, picked]..sort(
                    (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
                  );
              });
            }

            return AlertDialog(
              title: Text('Modifier planning - ${row.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('A qui ?', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _members
                          .map(
                            (m) => FilterChip(
                              label: Text(m.fullName),
                              selected: memberSelection[m.id] == true,
                              onSelected: (v) => setDialog(() => memberSelection[m.id] = v),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('Frequence', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Quotidien'),
                            selected: frequency == 'daily',
                            onSelected: (_) => setDialog(() => frequency = 'daily'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Hebdomadaire'),
                            selected: frequency == 'weekly',
                            onSelected: (_) => setDialog(() => frequency = 'weekly'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Heures', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < times.length; i++)
                          InputChip(
                            label: Text(_hm(times[i])),
                            onDeleted: () => setDialog(() {
                              times = [...times]..removeAt(i);
                            }),
                          ),
                        OutlinedButton.icon(
                          onPressed: addTime,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Debut / Fin', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => pickDate(true),
                            child: Text('Debut ${_ymd(startDate)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => pickDate(false),
                            child: Text('Fin ${_ymd(endDate)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Quantite par prise', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: intakeAmount?.toString() ?? '',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '1'),
                            onChanged: (v) => intakeAmount = double.tryParse(v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: intakeUnit,
                            items: const [
                              DropdownMenuItem(value: 'Comprime(s)', child: Text('Comprime(s)')),
                              DropdownMenuItem(value: 'Gelule(s)', child: Text('Gelule(s)')),
                              DropdownMenuItem(value: 'ml', child: Text('ml')),
                              DropdownMenuItem(value: 'Goutte(s)', child: Text('Goutte(s)')),
                              DropdownMenuItem(value: 'Sachet(s)', child: Text('Sachet(s)')),
                              DropdownMenuItem(value: 'Unite(s)', child: Text('Unite(s)')),
                            ],
                            onChanged: (v) => intakeUnit = v ?? intakeUnit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final targetIds = memberSelection.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();
                    if (targetIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selectionne au moins un membre')),
                      );
                      return;
                    }
                    if (times.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ajoute au moins une heure')),
                      );
                      return;
                    }

                    final existingIds = plans
                        .map((p) => p['id']?.toString())
                        .whereType<String>()
                        .where((id) => id.isNotEmpty)
                        .toList();

                    if (existingIds.isNotEmpty) {
                      await Supabase.instance.client
                          .from('family_medication_plans')
                          .delete()
                          .inFilter('id', existingIds);
                    }

                    final newPlans = targetIds
                        .map(
                          (memberId) => {
                            'family_id': familyId,
                            'medication_id': row.id,
                            'member_id': memberId,
                            'frequency_type': frequency,
                            'times': times.map((t) => '${_hm(t)}:00').toList(),
                            'start_date': _ymd(startDate),
                            'end_date': _ymd(endDate),
                            'duration_days': endDate.difference(startDate).inDays + 1,
                            'intake_amount': intakeAmount,
                            'intake_unit': intakeUnit,
                            'status': 'active',
                            'created_by': user.id,
                          },
                        )
                        .toList();

                    final inserted = await Supabase.instance.client
                        .from('family_medication_plans')
                        .insert(newPlans)
                        .select('id');

                    final fromDate = _ymd(startDate);
                    final toDate = _ymd(endDate);
                    final planIds = (inserted as List)
                        .map((e) => (e as Map<String, dynamic>)['id']?.toString())
                        .whereType<String>()
                        .where((id) => id.isNotEmpty)
                        .toList();

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

                    if (!context.mounted) return;
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (saved == true) {
      await _loadRows();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.seed),
      scaffoldBackgroundColor: const Color(0xFFFCFAFF),
    );

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final t = Theme.of(context);
          return Scaffold(
            backgroundColor: t.scaffoldBackgroundColor,
            body: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                        child: Row(
                          children: [
                            IconButton(
                              style: IconButton.styleFrom(backgroundColor: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.chevron_left, color: t.colorScheme.primary),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Gerer les medicaments',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: Color(0xFF2D0A4E),
                                ),
                              ),
                            ),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: t.colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (_) => const AddMedicationScreen(),
                                      ),
                                    )
                                    .then((_) => _loadRows());
                              },
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _rows.isEmpty
                                ? const Center(child: Text('Aucun medicament.'))
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                                    itemCount: _rows.length,
                                    itemBuilder: (context, index) {
                                      final row = _rows[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: _ManageMedicationTile(
                                          row: row,
                                          onEdit: () => _editPlanning(row),
                                          onDelete: () => _deleteMedication(row.id),
                                          onReactivate: () => _reactivateMedication(row.id),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
                AppBottomNav(
                  activeTab: AppTab.settings,
                  onHome: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  onCalendar: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                      (route) => false,
                    );
                  },
                  onSettings: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ManageMedicationTile extends StatelessWidget {
  const _ManageMedicationTile({
    required this.row,
    required this.onEdit,
    required this.onDelete,
    required this.onReactivate,
  });

  final _MedicationRow row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Opacity(
      opacity: row.isActive ? 1 : 0.65,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.colorScheme.primary.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: t.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    row.isActive ? Icons.medication : Icons.vaccines,
                    color: row.isActive ? t.colorScheme.primary : Colors.grey,
                    size: 26,
                  ),
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: _AvatarStackMini(avatars: row.avatarUrls),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: row.isActive ? const Color(0xFF2D0A4E) : Colors.grey,
                            decoration: row.isActive ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if ((row.dosage ?? '').isNotEmpty)
                        Text(
                          '• ${row.dosage}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (row.isActive)
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: t.colorScheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            row.times.isEmpty ? '-' : row.times.join(', '),
                            style: TextStyle(
                              color: t.colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'TERMINE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit, color: t.colorScheme.primary),
            ),
            if (!row.isActive)
              IconButton(
                onPressed: onReactivate,
                icon: Icon(Icons.refresh, color: t.colorScheme.primary),
              ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationRow {
  const _MedicationRow({
    required this.id,
    required this.name,
    required this.dosage,
    required this.isActive,
    required this.times,
    required this.avatarUrls,
  });

  final String id;
  final String name;
  final String? dosage;
  final bool isActive;
  final List<String> times;
  final List<String> avatarUrls;
}

class _AvatarStackMini extends StatelessWidget {
  const _AvatarStackMini({required this.avatars});

  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    final visible = avatars.take(3).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: 24 + (visible.length - 1) * 8,
      height: 24,
      child: Stack(
        children: [
          for (int i = 0; i < visible.length; i++)
            Positioned(
              left: i * 8.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(visible[i]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FamilyMember {
  const _FamilyMember({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String fullName;
  final String? role;
}

List<TimeOfDay> _timesFromRaw(dynamic raw) {
  final list = (raw is List) ? raw : const [];
  final out = <TimeOfDay>[];
  for (final t in list) {
    final p = _parseHm(t.toString());
    if (p != null) out.add(p);
  }
  return out;
}

TimeOfDay? _parseHm(String raw) {
  if (raw.length < 5) return null;
  final part = raw.substring(0, 5);
  final items = part.split(':');
  if (items.length != 2) return null;
  final h = int.tryParse(items[0]);
  final m = int.tryParse(items[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return TimeOfDay(hour: h, minute: m);
}

String _hm(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _avatarForRole(String? role) {
  switch (role) {
    case 'pere':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuCqrdt8Y2LDzW4L2OBgbaWMLUFtzv5wsTxRXsTenIk5--Sn09sN8kf5DT5ICS1y9U8cj3QfNVyf24wGEV2thzTAdGSIPCUr4594VL3QdZvIj95Fa4ANu0m2HwJER9skr5lYbnns-DBHiuWuOfG7buIYYRaMg7gtc8TfCwuhQ2q6I6yotGv-HoAGGuL_EJl2sY0IQyyKi-lNh3Dd8aY75M6Vj0IiG6Tvl19N2CKNb9NxPNbp44T75SA-jgZON8hK9EU9-kY63ujD5hX6';
    case 'mere':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuA_Oh9U81EW2PATmAxX3My-4rgugn1enxEPsQk7q_EOMvOPn8vNu_BZ-JEbrcyTOxTJq3GqhV1ZieQjzxikW8Cg1Fuew4wc1VwYihEj6vcBRFwu_vpe-a374U1IN08WYMlyR4uljQFkd9F316fyaOVTvaHcfVSE0nQQuQPR5bPQ4gCDyZQPhLYVJmR3yLEjrO17ARccCMp9hBavxp8UlLPZFEP4qG0JE-RtndAFGKkpetOuQkpFZIYCaJnoRlEbOfK6wPyikIhjYg1s';
    case 'enfant':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuAY6lvv8vRlHNQMoa2s0mMoaM3skXYxHnaHvoDVleBFHpbJglmAFO7VEfP0QHrovrTAq1u3kn6U5b0SRZFWCrg1I2fz7TYylpVKPkCfJgOvnA2xPHJTtADDjIwkDAWPcdd2iKK3iXBUB2VCbV05PR2N92HQNEVJ-ASLkdakIGkKBgsqOyWyMO7brLfckgm0T_0nJOUxUjpmtxpAtJkY-jxrwkMRC_qvfEclUPcqNh2SaA4Tgfc-tLtfVUvCdCC9JQRF0Sa8jPVhw5TB';
    default:
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBdN7bnNU6TR1CS8DghMWvZEYmyFEcFM-Y2Y3Zbi6yGkt5BxqPWIqcvcsa_BEz3D7DAJFLONJiA2pOTpy01FupzCRhra6wPSCv5O74--2_2KmbgIs0-pr0dQOGNx2xiMpA2k4aMAtV84lVEWmrpgr5BE9ibi--RP_STU7IIjIHiecrDHZ7hfvPAtRTXZxw1VPqauniTeLK-eZF2GxtMoLSK1T7nIN8OAwxlap7KpqxWS_tww4z4uaqiaB6eghzdZWzzi9IEJXZHM2PT';
  }
}
