import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/app_theme.dart';
import '../../utils/doctor_images.dart';
import '../../widgets/app_bottom_nav.dart';
import '../home_screen.dart';
import '../settings_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _showFamily = true;
  bool _loading = true;
  List<_RendezVousEvent> _events = [];
  String? _familyId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      if (mounted) {
        setState(() => _loading = true);
      }
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final familyRow = await Supabase.instance.client
          .from('family_members')
          .select('family_id')
          .eq('auth_user_id', user.id)
          .limit(1)
          .maybeSingle();
      final familyId = familyRow?['family_id']?.toString();
      if (familyId == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final rdvQuery = Supabase.instance.client
          .from('rendez_vous')
          .select(
              'id, date, heure, status, family_members!inner (id, full_name, role, auth_user_id), medecins_famille!inner (id, family_id, medecins (id, first_name, last_name, specialite, photo_url))')
          .eq('medecins_famille.family_id', familyId)
          .neq('status', 'annule');

      final rdvData = await (!_showFamily
          ? rdvQuery.eq('family_members.auth_user_id', user.id)
          : rdvQuery)
          .order('date')
          .order('heure');
      final rdvItems = (rdvData as List<dynamic>)
          .map((row) => _RendezVousEvent.fromRdvMap(row as Map<String, dynamic>))
          .where((item) => item.dateTime != null)
          .toList();

      final dosesQuery = Supabase.instance.client
          .from('family_medication_doses')
          .select(
              'id, scheduled_date, scheduled_time, taken, family_members!inner(id, full_name, role, auth_user_id), family_medications!inner(name, dosage_per_unit), family_medication_plans!inner(intake_amount, intake_unit, status)')
          .eq('family_id', familyId)
          .eq('taken', false)
          .eq('family_medication_plans.status', 'active');

      final dosesData = await (!_showFamily
          ? dosesQuery.eq('family_members.auth_user_id', user.id)
          : dosesQuery)
          .order('scheduled_date')
          .order('scheduled_time');

      final medicationItems =
          _mapMedicationDoseEvents(dosesData as List<dynamic>);
      final items = [...rdvItems, ...medicationItems]
        ..sort((a, b) => (a.dateTime ?? DateTime(1970))
            .compareTo(b.dateTime ?? DateTime(1970)));

      if (!mounted) return;
      setState(() {
        _familyId = familyId;
        _events = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Widget> _buildEventSections(ThemeData theme, DateTime selectedDay) {
    final widgets = <Widget>[];
    widgets.add(
      Text(
        _formatDateHeader(selectedDay),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    widgets.add(const SizedBox(height: 12));

    final dayEvents = _events
        .where((event) =>
            event.dateTime != null &&
            _isSameDay(event.dateTime!, selectedDay))
        .toList()
      ..sort((a, b) => a.dateTime!.compareTo(b.dateTime!));

    if (dayEvents.isEmpty) {
      widgets.add(
        Text(
          'Aucun evenement pour cette date.',
          style: theme.textTheme.bodySmall,
        ),
      );
      return widgets;
    }

    for (final event in dayEvents) {
      final time = event.dateTime == null
          ? '--:--'
          : _formatTimeOfDay(event.dateTime!);
      final name = !_showFamily
          ? 'Moi'
          : (event.memberRole.trim().isNotEmpty
              ? event.memberRole
              : event.memberName);
      final avatarUrl = event.photoUrl?.isNotEmpty == true
          ? event.photoUrl!
          : imageUrlForSpecialty(event.specialty);
      widgets.add(
        _CalendarEvent(
          time: time,
          name: name,
          title: event.title,
          avatarUrl: avatarUrl,
          onTap: () => _onEventTap(event),
        ),
      );
    }
    widgets.add(const SizedBox(height: 8));
    return widgets;
  }

  Future<void> _onEventTap(_RendezVousEvent event) async {
    if (!event.isMedication) {
      return;
    }

    final taken = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Prise du medicament'),
          content: Text('Est-ce que "${
              event.medicationName ?? 'ce medicament'
            }" est prise ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Oui'),
            ),
          ],
        );
      },
    );

    if (!mounted || taken == null) return;
    if (!taken) return;

    try {
      await Supabase.instance.client.from('family_medication_doses').update({
        'taken': true,
        'taken_at': DateTime.now().toIso8601String(),
      }).eq('id', event.id);

      if (!mounted) return;
      setState(() {
        _events = _events.where((e) => e.id != event.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicament marque comme pris.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise a jour.')),
      );
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
              fontSize: 22,
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
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Stack(
              children: [
                Positioned.fill(
                  child: SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      children: [
                      Row(
                        children: [
                          const SizedBox(width: 4),
                          Icon(
                            Icons.notifications,
                            color: theme.colorScheme.primary,
                          ),
                          const Spacer(),
                          Text(
                            'Calendrier',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.search,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ToggleChip(
                                label: 'Famille',
                                active: _showFamily,
                          onTap: () {
                            setState(() => _showFamily = true);
                            _loadEvents();
                          },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _ToggleChip(
                                label: 'Moi',
                                active: !_showFamily,
                          onTap: () {
                            setState(() => _showFamily = false);
                            _loadEvents();
                          },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CalendarCard(
                        events: _events,
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay ?? DateTime.now(),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_events.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                          'Aucun evenement pour le moment.',
                            style: theme.textTheme.bodySmall,
                          ),
                        )
                      else
                        ..._buildEventSections(
                          theme,
                          _selectedDay ?? DateTime.now(),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 90,
                  child: FloatingActionButton(
                    backgroundColor: theme.colorScheme.primary,
                    onPressed: () {},
                    child: const Icon(Icons.add, size: 30),
                  ),
                ),
                AppBottomNav(
                  activeTab: AppTab.calendar,
                  onHome: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
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

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
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
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.6),
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.events,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  final List<_RendezVousEvent> events;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;

  List<_RendezVousEvent> _eventsForDay(DateTime day) {
    return events
        .where((event) =>
            event.dateTime != null && _isSameDay(event.dateTime!, day))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TableCalendar<_RendezVousEvent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => _isSameDay(day, selectedDay),
        eventLoader: _eventsForDay,
        onDaySelected: onDaySelected,
        headerStyle: HeaderStyle(
          titleCentered: false,
          formatButtonVisible: false,
          titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ) ??
              const TextStyle(fontWeight: FontWeight.w700),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          dowTextFormatter: (date, locale) {
            const labels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
            return labels[date.weekday - 1];
          },
          weekdayStyle: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary.withOpacity(0.4),
                letterSpacing: 0.6,
              ) ??
              const TextStyle(fontWeight: FontWeight.w700),
          weekendStyle: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary.withOpacity(0.4),
                letterSpacing: 0.6,
              ) ??
              const TextStyle(fontWeight: FontWeight.w700),
        ),
        calendarStyle: CalendarStyle(
          outsideTextStyle: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black26,
                fontWeight: FontWeight.w600,
              ) ??
              const TextStyle(color: Colors.black26),
          defaultTextStyle: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ) ??
              const TextStyle(color: Colors.black87),
          weekendTextStyle: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ) ??
              const TextStyle(color: Colors.black87),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 2,
          markerSize: 5,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            return Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${events.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CalendarEvent extends StatelessWidget {
  const _CalendarEvent({
    required this.time,
    required this.name,
    required this.title,
    required this.avatarUrl,
    required this.onTap,
  });

  final String time;
  final String name;
  final String title;
  final String avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 2,
                      height: 28,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary.withOpacity(0.6),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RendezVousEvent {
  const _RendezVousEvent({
    required this.id,
    required this.dateTime,
    required this.memberName,
    required this.memberRole,
    required this.doctorName,
    required this.specialty,
    required this.photoUrl,
    required this.title,
    this.isMedication = false,
    this.medicationName,
  });

  final String id;
  final DateTime? dateTime;
  final String memberName;
  final String memberRole;
  final String doctorName;
  final String specialty;
  final String? photoUrl;
  final String title;
  final bool isMedication;
  final String? medicationName;

  factory _RendezVousEvent.fromRdvMap(Map<String, dynamic> map) {
    final dateStr = map['date']?.toString();
    final timeStr = map['heure']?.toString();
    DateTime? dateTime;
    if (dateStr != null && timeStr != null) {
      final hourMinute = timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
      dateTime = DateTime.tryParse('$dateStr $hourMinute:00');
    }

    final memberRaw = map['family_members'];
    Map<String, dynamic>? member;
    if (memberRaw is Map<String, dynamic>) {
      member = memberRaw;
    } else if (memberRaw is List && memberRaw.isNotEmpty) {
      final first = memberRaw.first;
      if (first is Map<String, dynamic>) {
        member = first;
      }
    }

    final medecinsFamRaw = map['medecins_famille'];
    Map<String, dynamic>? medecinsFam;
    if (medecinsFamRaw is Map<String, dynamic>) {
      medecinsFam = medecinsFamRaw;
    } else if (medecinsFamRaw is List && medecinsFamRaw.isNotEmpty) {
      final first = medecinsFamRaw.first;
      if (first is Map<String, dynamic>) {
        medecinsFam = first;
      }
    }

    Map<String, dynamic>? medecin;
    final medecinRaw = medecinsFam?['medecins'];
    if (medecinRaw is Map<String, dynamic>) {
      medecin = medecinRaw;
    } else if (medecinRaw is List && medecinRaw.isNotEmpty) {
      final first = medecinRaw.first;
      if (first is Map<String, dynamic>) {
        medecin = first;
      }
    }

    final firstName = medecin?['first_name']?.toString() ?? '';
    final lastName = medecin?['last_name']?.toString() ?? '';
    final doctorName = 'Dr. ${'$firstName $lastName'.trim()}'.trim();

    return _RendezVousEvent(
      id: map['id']?.toString() ?? '',
      dateTime: dateTime,
      memberName: member?['full_name']?.toString() ?? 'Membre',
      memberRole: member?['role']?.toString() ?? '',
      doctorName: doctorName.isEmpty ? 'Dr.' : doctorName,
      specialty: medecin?['specialite']?.toString() ?? 'Medecin',
      photoUrl: medecin?['photo_url']?.toString(),
      title:
          'RDV ${medecin?['specialite']?.toString() ?? 'Medecin'} - ${doctorName.isEmpty ? 'Dr.' : doctorName}',
      isMedication: false,
    );
  }
}

List<_RendezVousEvent> _mapMedicationDoseEvents(List<dynamic> rows) {
  final out = <_RendezVousEvent>[];
  for (final raw in rows) {
    if (raw is! Map<String, dynamic>) continue;
    final row = raw;

    final dateStr = row['scheduled_date']?.toString();
    final timeStr = row['scheduled_time']?.toString();
    if (dateStr == null || timeStr == null) continue;
    final hourMinute = timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
    final dateTime = DateTime.tryParse('$dateStr $hourMinute:00');
    if (dateTime == null) continue;

    final memberRaw = row['family_members'];
    Map<String, dynamic>? member;
    if (memberRaw is Map<String, dynamic>) {
      member = memberRaw;
    } else if (memberRaw is List && memberRaw.isNotEmpty) {
      final first = memberRaw.first;
      if (first is Map<String, dynamic>) member = first;
      if (first is Map) member = Map<String, dynamic>.from(first);
    } else if (memberRaw is Map) {
      member = Map<String, dynamic>.from(memberRaw);
    }

    final medRaw = row['family_medications'];
    Map<String, dynamic>? medication;
    if (medRaw is Map<String, dynamic>) {
      medication = medRaw;
    } else if (medRaw is List && medRaw.isNotEmpty) {
      final first = medRaw.first;
      if (first is Map<String, dynamic>) medication = first;
      if (first is Map) medication = Map<String, dynamic>.from(first);
    } else if (medRaw is Map) {
      medication = Map<String, dynamic>.from(medRaw);
    }

    final planRaw = row['family_medication_plans'];
    Map<String, dynamic>? plan;
    if (planRaw is Map<String, dynamic>) {
      plan = planRaw;
    } else if (planRaw is List && planRaw.isNotEmpty) {
      final first = planRaw.first;
      if (first is Map<String, dynamic>) plan = first;
      if (first is Map) plan = Map<String, dynamic>.from(first);
    } else if (planRaw is Map) {
      plan = Map<String, dynamic>.from(planRaw);
    }

    final medName = medication?['name']?.toString() ?? 'Medicament';
    final dosage = medication?['dosage_per_unit']?.toString();
    final intakeAmount = plan?['intake_amount']?.toString();
    final intakeUnit = plan?['intake_unit']?.toString();
    final intakeLabel = [
      if (intakeAmount != null && intakeAmount.isNotEmpty) intakeAmount,
      if (intakeUnit != null && intakeUnit.isNotEmpty) intakeUnit,
    ].join(' ');
    final title = [
      'Prise $medName',
      if (intakeLabel.isNotEmpty) '- $intakeLabel',
      if (dosage != null && dosage.isNotEmpty) '($dosage)',
    ].join(' ');

    out.add(
      _RendezVousEvent(
        id: row['id']?.toString() ?? '',
        dateTime: dateTime,
        memberName: member?['full_name']?.toString() ?? 'Membre',
        memberRole: member?['role']?.toString() ?? '',
        doctorName: 'Medicaments',
        specialty: 'Traitement',
        photoUrl: _avatarForRole(member?['role']?.toString()),
        title: title,
        isMedication: true,
        medicationName: medName,
      ),
    );
  }
  return out;
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

String _formatDateHeader(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(date.year, date.month, date.day);
  final diff = dateOnly.difference(today).inDays;
  if (diff == 0) {
    return 'Aujourd\'hui, ${_formatDayMonth(date)}';
  }
  if (diff == 1) {
    return 'Demain, ${_formatDayMonth(date)}';
  }
  return _formatDayMonth(date);
}

String _formatDayMonth(DateTime date) {
  const months = [
    'Janvier',
    'Fevrier',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Aout',
    'Septembre',
    'Octobre',
    'Novembre',
    'Decembre',
  ];
  final monthName = months[date.month - 1];
  return '${date.day} $monthName';
}

String _formatTimeOfDay(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
