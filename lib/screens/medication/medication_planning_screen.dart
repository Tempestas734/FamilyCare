import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import 'add_medication_screen.dart';
import '../calendar/calendar_screen.dart';
import '../home_screen.dart';
import 'manage_medications_screen.dart';
import '../settings_screen.dart';

class MedicationPlanningScreen extends StatefulWidget {
  const MedicationPlanningScreen({super.key});

  @override
  State<MedicationPlanningScreen> createState() => _MedicationPlanningScreenState();
}

class _MedicationPlanningScreenState extends State<MedicationPlanningScreen> {
  bool _showFamily = true;
  bool _loading = true;
  List<_MedicationItem> _items = const [];
  final Set<String> _togglingDoseIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadMedicationItems();
  }

  String _todayYmd() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatTodayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aout',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Aujourd\'hui, ${now.day} ${months[now.month - 1]}';
  }

  Future<void> _loadMedicationItems() async {
    try {
      if (mounted) setState(() => _loading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _items = const [];
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

      final familyId = _asText(familyRow?['family_id']);
      if (familyId == null || familyId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _items = const [];
          _loading = false;
        });
        return;
      }

      final query = Supabase.instance.client
          .from('family_medication_doses')
          .select(
              'id, scheduled_date, scheduled_time, taken, family_members!inner(id, full_name, role, auth_user_id), family_medications!inner(name, dosage_per_unit), family_medication_plans!inner(intake_amount, intake_unit, status)')
          .eq('family_id', familyId)
          .eq('scheduled_date', _todayYmd())
          .eq('family_medication_plans.status', 'active');

      final data = await (!_showFamily
          ? query.eq('family_members.auth_user_id', user.id)
          : query).order('scheduled_time');

      final items = _mapDosesForToday(data as List<dynamic>, showFamily: _showFamily)
        ..sort((a, b) => a.sortTime.compareTo(b.sortTime));

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleDoseTaken(_MedicationItem item) async {
    if (_togglingDoseIds.contains(item.doseId)) return;
    setState(() => _togglingDoseIds.add(item.doseId));

    final nextTaken = !item.taken;
    try {
      await Supabase.instance.client.from('family_medication_doses').update({
        'taken': nextTaken,
        'taken_at': nextTaken ? DateTime.now().toIso8601String() : null,
      }).eq('id', item.doseId);

      if (!mounted) return;
      setState(() {
        _items = _items
            .map((e) => e.doseId == item.doseId ? e.copyWith(taken: nextTaken) : e)
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur mise a jour prise')),
      );
    } finally {
      if (mounted) {
        setState(() => _togglingDoseIds.remove(item.doseId));
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
          final items = _items;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.9),
                      elevation: 0,
                      title: Text(
                        'Medicaments & Planning',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF2D0A4E),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: _AudienceSwitcher(
                          showFamily: _showFamily,
                          onChange: (value) {
                            setState(() => _showFamily = value);
                            _loadMedicationItems();
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: Row(
                          children: [
                            Text(
                              _formatTodayLabel(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF2D0A4E),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                                );
                              },
                              child: Text(
                                'Voir le calendrier',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_loading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else if (items.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Text(
                            'Aucun medicament planifie pour aujourd\'hui.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            return Padding(
                              padding: EdgeInsets.fromLTRB(16, index == 0 ? 4 : 0, 16, 10),
                              child: _MedicationCard(
                                item: item,
                                busy: _togglingDoseIds.contains(item.doseId),
                                onToggleTaken: () => _toggleDoseTaken(item),
                              ),
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestion Medicale',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF2D0A4E),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: _cardDecoration(theme),
                              padding: const EdgeInsets.all(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ManageMedicationsScreen(),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.medical_services,
                                        color: theme.colorScheme.primary,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          'Gerer les medicaments',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.black38),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 24,
                  bottom: 96,
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: FloatingActionButton(
                      backgroundColor: theme.colorScheme.primary,
                      onPressed: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const AddMedicationScreen()))
                            .then((_) => _loadMedicationItems());
                      },
                      child: const Icon(Icons.add, size: 32),
                    ),
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

class _AudienceSwitcher extends StatelessWidget {
  const _AudienceSwitcher({
    required this.showFamily,
    required this.onChange,
  });

  final bool showFamily;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onChange(true),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: showFamily ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Famille',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: showFamily ? theme.colorScheme.primary : Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => onChange(false),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !showFamily ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Moi',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: !showFamily ? theme.colorScheme.primary : Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.item,
    required this.onToggleTaken,
    this.busy = false,
  });

  final _MedicationItem item;
  final VoidCallback onToggleTaken;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTaken = item.taken;

    return Opacity(
      opacity: isTaken ? 0.72 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(theme),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(item.avatarUrl),
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
                          item.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D0A4E),
                            decoration: isTaken ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      _TimeBadge(time: item.time, taken: item.taken),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.details,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.person,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ActionBadge(
              taken: item.taken,
              busy: busy,
              onTap: onToggleTaken,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.time, required this.taken});

  final String time;
  final bool taken;

  @override
  Widget build(BuildContext context) {
    final bg = taken ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6);
    final fg = taken ? const Color(0xFF16A34A) : Colors.black54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        time,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({
    required this.taken,
    required this.onTap,
    this.busy = false,
  });

  final bool taken;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: taken
              ? const Color(0xFF16A34A)
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: busy
            ? const Padding(
                padding: EdgeInsets.all(7),
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(
                taken ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: taken ? Colors.white : Theme.of(context).colorScheme.primary,
              ),
      ),
    );
  }
}

class _MedicationItem {
  const _MedicationItem({
    required this.doseId,
    required this.name,
    required this.details,
    required this.person,
    required this.time,
    required this.avatarUrl,
    required this.taken,
    required this.sortTime,
  });

  final String doseId;
  final String name;
  final String details;
  final String person;
  final String time;
  final String avatarUrl;
  final bool taken;
  final int sortTime;

  _MedicationItem copyWith({bool? taken}) {
    return _MedicationItem(
      doseId: doseId,
      name: name,
      details: details,
      person: person,
      time: time,
      avatarUrl: avatarUrl,
      taken: taken ?? this.taken,
      sortTime: sortTime,
    );
  }
}

List<_MedicationItem> _mapDosesForToday(
  List<dynamic> rows, {
  required bool showFamily,
}) {
  final out = <_MedicationItem>[];

  for (final raw in rows) {
    if (raw is! Map<String, dynamic>) continue;
    final row = raw;

    final member = _extractMap(row['family_members']);
    final medication = _extractMap(row['family_medications']);
    final plan = _extractMap(row['family_medication_plans']);

    final doseId = _asText(row['id']) ?? '';
    if (doseId.isEmpty) continue;

    final medName = _asText(medication?['name']) ?? 'Medicament';
    final dosage = _asText(medication?['dosage_per_unit']);
    final intakeAmount = _asText(plan?['intake_amount']);
    final intakeUnit = _asText(plan?['intake_unit']);

    final detailsParts = <String>[
      if (dosage != null && dosage.isNotEmpty) dosage,
      if (intakeAmount != null && intakeAmount.isNotEmpty)
        if (intakeUnit != null && intakeUnit.isNotEmpty)
          '$intakeAmount $intakeUnit'
        else
          intakeAmount,
    ];

    final memberName = _asText(member?['full_name']) ?? 'Membre';
    final person = showFamily ? 'Pour $memberName' : 'Pour Moi';
    final avatarUrl = _avatarForRole(_asText(member?['role']));
    final taken = row['taken'] == true;

    final timeRaw = _asText(row['scheduled_time']);
    final parsed = timeRaw == null ? null : _parseTimeString(timeRaw);
    final time = parsed == null
        ? '--:--'
        : '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    final sortTime = parsed == null ? 24 * 60 : parsed.hour * 60 + parsed.minute;

    out.add(
      _MedicationItem(
        doseId: doseId,
        name: medName,
        details: detailsParts.isEmpty ? '-' : detailsParts.join(' • '),
        person: person,
        time: time,
        avatarUrl: avatarUrl,
        taken: taken,
        sortTime: sortTime,
      ),
    );
  }

  return out;
}

Map<String, dynamic>? _extractMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
    return raw.first as Map<String, dynamic>;
  }
  return null;
}

String? _asText(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text == 'null' || text == 'undefined') return null;
  return text;
}

TimeOfDay? _parseTimeString(String raw) {
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return TimeOfDay(hour: h, minute: m);
}

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

BoxDecoration _cardDecoration(ThemeData theme) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
    boxShadow: [
      BoxShadow(
        color: theme.colorScheme.primary.withOpacity(0.08),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
