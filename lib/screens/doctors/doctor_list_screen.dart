import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../utils/doctor_images.dart';
import '../../widgets/app_bottom_nav.dart';
import 'doctor_search_screen.dart';
import 'doctor_profile_screen.dart';
import '../home_screen.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  bool _loading = true;
  List<_DoctorFamily> _doctors = [];
  String? _familyId;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
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

      final data = await Supabase.instance.client
          .from('medecins_famille')
          .select('id, medecin_id, medecins!inner (id, first_name, last_name, telephone, specialite, email, ville, pays, photo_url, bio, clinique_nom, adresse, latitude, longitude, langues, tarif_min, tarif_max, secteur, note, disponibilite, types_consultation)')
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      final items = (data as List<dynamic>)
          .map((row) => _DoctorFamily.fromMap(row as Map<String, dynamic>))
          .where((item) => item.doctor.id.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _familyId = familyId;
        _doctors = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Ma liste de medecins',
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const DoctorSearchScreen(),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.search,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _doctors.isEmpty
                                ? Center(
                                    child: Text(
                                      'Aucun medecin disponible.',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  )
                                : ListView.separated(
                                    padding:
                                        const EdgeInsets.fromLTRB(20, 8, 20, 100),
                                    itemCount: _doctors.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      final doctor = _doctors[index];
                                      final imageUrl = doctor.doctor.photoUrl?.isNotEmpty == true
                                          ? doctor.doctor.photoUrl!
                                          : imageUrlForSpecialty(
                                              doctor.doctor.specialite,
                                            );
                                      return _DoctorListCard(
                                        name:
                                            'Dr. ${doctor.doctor.firstName} ${doctor.doctor.lastName}',
                                        specialty: doctor.doctor.specialite,
                                        location:
                                            '${doctor.doctor.ville}, ${doctor.doctor.pays}',
                                        imageUrl: imageUrl,
                                        disponibilite:
                                            doctor.doctor.disponibilite,
                                        medecinFamilleId: doctor.id,
                                        onRemove: () async {
                                          await Supabase.instance.client
                                              .from('medecins_famille')
                                              .delete()
                                              .eq('id', doctor.id);
                                          _loadDoctors();
                                        },
                                        onTap: () async {
                                          final added = await Navigator.of(context)
                                              .push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DoctorProfileScreen(
                                                doctorId: doctor.doctor.id,
                                                name:
                                                    'Dr. ${doctor.doctor.firstName} ${doctor.doctor.lastName}',
                                                specialty:
                                                    doctor.doctor.specialite,
                                                location:
                                                    '${doctor.doctor.ville}, ${doctor.doctor.pays}',
                                                imageUrl: imageUrl,
                                                photoUrl: doctor.doctor.photoUrl,
                                                bio: doctor.doctor.bio,
                                                cliniqueNom:
                                                    doctor.doctor.cliniqueNom,
                                                adresse: doctor.doctor.adresse,
                                                langues: doctor.doctor.langues,
                                                latitude: doctor.doctor.latitude,
                                                longitude:
                                                    doctor.doctor.longitude,
                                                tarifMin: doctor.doctor.tarifMin,
                                                tarifMax: doctor.doctor.tarifMax,
                                                secteur: doctor.doctor.secteur,
                                                note: doctor.doctor.note,
                                                disponibilite:
                                                    doctor.doctor.disponibilite,
                                                typesConsultation:
                                                    doctor.doctor.typesConsultation,
                                              ),
                                            ),
                                          );
                                          if (added == true) {
                                            _loadDoctors();
                                          }
                                        },
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DoctorListCard extends StatelessWidget {
  const _DoctorListCard({
    required this.name,
    required this.specialty,
    required this.location,
    required this.imageUrl,
    required this.disponibilite,
    required this.medecinFamilleId,
    required this.onRemove,
    required this.onTap,
  });

  final String name;
  final String specialty;
  final String location;
  final String imageUrl;
  final DateTime? disponibilite;
  final String medecinFamilleId;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final generatedSlots =
        disponibilite == null ? _generateSlots(DateTime.now()) : <DateTime>[];
    final availabilityText = disponibilite == null
        ? _formatSlotSummary(generatedSlots)
        : _formatDisponibilite(disponibilite!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1EEF7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
        child: Stack(
          children: [
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 20, color: Colors.black38),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialty,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.black38,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  availabilityText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Appeler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final slots = disponibilite == null
                              ? generatedSlots
                              : <DateTime>[disponibilite!];
                          final chosenMember =
                              await _pickFamilyMember(context);
                          if (chosenMember == null) {
                            return;
                          }
                          final takenSlots =
                              await _loadTakenSlots(medecinFamilleId, slots);
                          if (!context.mounted) return;
                          _showRdvSheet(
                            context,
                            slots,
                            medecinFamilleId: medecinFamilleId,
                            familyMemberId: chosenMember.id,
                            takenSlots: takenSlots,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.event_available, size: 18),
                      label: const Text('Prendre RDV'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }
}

class _DoctorFamily {
  const _DoctorFamily({
    required this.id,
    required this.medecinId,
    required this.doctor,
  });

  final String id;
  final String medecinId;
  final _Doctor doctor;

  factory _DoctorFamily.fromMap(Map<String, dynamic> map) {
    final raw = map['medecins'];
    Map<String, dynamic>? doctorMap;
    if (raw is Map<String, dynamic>) {
      doctorMap = raw;
    } else if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) {
        doctorMap = first;
      }
    }

    return _DoctorFamily(
      id: map['id']?.toString() ?? '',
      medecinId: map['medecin_id']?.toString() ?? '',
      doctor: _Doctor.fromMap(
        doctorMap ?? const {},
      ),
    );
  }
}

class _Doctor {
  const _Doctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.telephone,
    required this.specialite,
    required this.email,
    required this.ville,
    required this.pays,
    required this.photoUrl,
    required this.bio,
    required this.cliniqueNom,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    required this.langues,
    required this.tarifMin,
    required this.tarifMax,
    required this.secteur,
    required this.note,
    required this.disponibilite,
    required this.typesConsultation,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String telephone;
  final String specialite;
  final String? email;
  final String ville;
  final String pays;
  final String? photoUrl;
  final String? bio;
  final String? cliniqueNom;
  final String? adresse;
  final double? latitude;
  final double? longitude;
  final List<String> langues;
  final double? tarifMin;
  final double? tarifMax;
  final String? secteur;
  final double? note;
  final DateTime? disponibilite;
  final List<String> typesConsultation;

  factory _Doctor.fromMap(Map<String, dynamic> map) {
    final languesRaw = map['langues'];
    final typesRaw = map['types_consultation'];
    return _Doctor(
      id: map['id']?.toString() ?? '',
      firstName: map['first_name']?.toString() ?? '',
      lastName: map['last_name']?.toString() ?? '',
      telephone: map['telephone']?.toString() ?? '',
      specialite: map['specialite']?.toString() ?? '',
      email: map['email']?.toString(),
      ville: map['ville']?.toString() ?? '',
      pays: map['pays']?.toString() ?? '',
      photoUrl: map['photo_url']?.toString(),
      bio: map['bio']?.toString(),
      cliniqueNom: map['clinique_nom']?.toString(),
      adresse: map['adresse']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      langues: languesRaw is List
          ? languesRaw.map((e) => e.toString()).toList()
          : <String>[],
      tarifMin: (map['tarif_min'] as num?)?.toDouble(),
      tarifMax: (map['tarif_max'] as num?)?.toDouble(),
      secteur: map['secteur']?.toString(),
      note: (map['note'] as num?)?.toDouble(),
      disponibilite: map['disponibilite'] == null
          ? null
          : DateTime.tryParse(map['disponibilite'].toString()),
      typesConsultation: typesRaw is List
          ? typesRaw.map((e) => e.toString()).toList()
          : <String>[],
    );
  }
}

String _formatDisponibilite(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diffDays = dateOnly.difference(today).inDays;
  final time = _formatTime(dateTime);
  if (diffDays == 0) {
    return 'Aujourd\'hui, $time';
  }
  if (diffDays == 1) {
    return 'Demain, $time';
  }
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  return '$day/$month/${dateTime.year} $time';
}

List<DateTime> _generateSlots(DateTime now) {
  final slots = <DateTime>[];
  final today = DateTime(now.year, now.month, now.day);
  var cursor = today;
  var daysAdded = 0;

  while (daysAdded < 7 && slots.length < 140) {
    final weekday = cursor.weekday;
    if (weekday >= DateTime.monday && weekday <= DateTime.friday) {
      var hasAny = false;
      for (var hour = 9; hour <= 17; hour++) {
        for (var minute = 0; minute <= 30; minute += 30) {
          final slot = DateTime(cursor.year, cursor.month, cursor.day, hour, minute);
          if (slot.isBefore(now)) {
            continue;
          }
          slots.add(slot);
          hasAny = true;
        }
      }
      if (hasAny) {
        daysAdded += 1;
      }
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return slots;
}

String _formatSlotSummary(List<DateTime> slots) {
  if (slots.isEmpty) {
    return 'Sur rendez-vous';
  }
  final first = slots.first;
  final dayLabel = _dayLabel(first);
  return '$dayLabel, ${_formatTime(first)}';
}

void _showRdvSheet(
  BuildContext context,
  List<DateTime> slots, {
  required String medecinFamilleId,
  required String familyMemberId,
  required Set<String> takenSlots,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFFF7F6F8),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final theme = Theme.of(context);
      final grouped = _groupSlotsByDay(slots);
      DateTime? selectedSlot;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Choisir un rendez-vous',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (grouped.isEmpty)
                    Text(
                      'Aucune disponibilite pour le moment.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: grouped.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final entry = grouped[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateTitle(entry.key),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: entry.value.map((slot) {
                                  final isSelected = selectedSlot == slot;
                                  final isTaken =
                                      takenSlots.contains(_slotKey(slot));
                                  return _SlotChip(
                                    label: _formatTime(slot),
                                    selected: isSelected,
                                    disabled: isTaken,
                                    onTap: isTaken
                                        ? null
                                        : () {
                                            setState(() => selectedSlot = slot);
                                          },
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedSlot == null
                          ? null
                          : () async {
                              final nav = Navigator.of(context);
                              nav.pop();
                              await _createRendezVous(
                                context,
                                medecinFamilleId,
                                familyMemberId,
                                selectedSlot!,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Confirmer le rendez-vous',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

List<MapEntry<DateTime, List<DateTime>>> _groupSlotsByDay(
  List<DateTime> slots,
) {
  final map = <DateTime, List<DateTime>>{};
  for (final slot in slots) {
    final key = DateTime(slot.year, slot.month, slot.day);
    map.putIfAbsent(key, () => []).add(slot);
  }
  final entries = map.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries;
}

String _formatDateTitle(DateTime date) {
  final dayName = _dayName(date.weekday);
  final month = _monthName(date.month);
  return '$dayName ${date.day} $month';
}

String _dayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateOnly = DateTime(date.year, date.month, date.day);
  final diff = dateOnly.difference(today).inDays;
  if (diff == 0) {
    return 'Aujourd\'hui';
  }
  if (diff == 1) {
    return 'Demain';
  }
  return _dayName(date.weekday);
}

String _dayName(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Lundi';
    case DateTime.tuesday:
      return 'Mardi';
    case DateTime.wednesday:
      return 'Mercredi';
    case DateTime.thursday:
      return 'Jeudi';
    case DateTime.friday:
      return 'Vendredi';
    case DateTime.saturday:
      return 'Samedi';
    case DateTime.sunday:
      return 'Dimanche';
  }
  return '';
}

String _monthName(int month) {
  switch (month) {
    case 1:
      return 'janvier';
    case 2:
      return 'fevrier';
    case 3:
      return 'mars';
    case 4:
      return 'avril';
    case 5:
      return 'mai';
    case 6:
      return 'juin';
    case 7:
      return 'juillet';
    case 8:
      return 'aout';
    case 9:
      return 'septembre';
    case 10:
      return 'octobre';
    case 11:
      return 'novembre';
    case 12:
      return 'decembre';
  }
  return '';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _slotKey(DateTime slot) {
  final dateStr =
      '${slot.year.toString().padLeft(4, '0')}-${slot.month.toString().padLeft(2, '0')}-${slot.day.toString().padLeft(2, '0')}';
  return '$dateStr ${_formatTime(slot)}';
}

Future<Set<String>> _loadTakenSlots(
  String medecinFamilleId,
  List<DateTime> slots,
) async {
  if (slots.isEmpty) {
    return {};
  }
  final start = slots.first;
  final end = slots.last;
  final startDate =
      '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
  final endDate =
      '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
  final data = await Supabase.instance.client
      .from('rendez_vous')
      .select('date, heure, status')
      .eq('medecin_famille_id', medecinFamilleId)
      .gte('date', startDate)
      .lte('date', endDate)
      .neq('status', 'annule');
  final taken = <String>{};
  for (final row in (data as List<dynamic>)) {
    final map = row as Map<String, dynamic>;
    final date = map['date']?.toString();
    final time = map['heure']?.toString();
    if (date == null || time == null) {
      continue;
    }
    final hourMinute = time.length >= 5 ? time.substring(0, 5) : time;
    taken.add('$date $hourMinute');
  }
  return taken;
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        selected ? theme.colorScheme.primary : Colors.white;
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withOpacity(0.2);
    final textColor = selected ? Colors.white : theme.colorScheme.primary;
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(disabled ? 0.5 : 1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor.withOpacity(disabled ? 0.4 : 1),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor.withOpacity(disabled ? 0.5 : 1),
          ),
        ),
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
  final String role;

  factory _FamilyMember.fromMap(Map<String, dynamic> map) {
    return _FamilyMember(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString().trim().isNotEmpty == true
          ? map['full_name'].toString()
          : 'Membre',
      role: map['role']?.toString() ?? '',
    );
  }
}

Future<String?> _getFamilyId() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return null;
  }
  final row = await Supabase.instance.client
      .from('family_members')
      .select('family_id')
      .eq('auth_user_id', user.id)
      .limit(1)
      .maybeSingle();
  return row?['family_id']?.toString();
}

Future<List<_FamilyMember>> _loadFamilyMembers() async {
  final familyId = await _getFamilyId();
  if (familyId == null) {
    return [];
  }
  final data = await Supabase.instance.client
      .from('family_members')
      .select('id, full_name, role')
      .eq('family_id', familyId)
      .order('created_at');
  return (data as List<dynamic>)
      .map((row) => _FamilyMember.fromMap(row as Map<String, dynamic>))
      .where((member) => member.id.isNotEmpty)
      .toList();
}

Future<_FamilyMember?> _pickFamilyMember(BuildContext context) async {
  final members = await _loadFamilyMembers();
  if (!context.mounted) return null;
  if (members.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucun membre trouve.')),
    );
    return null;
  }
  return showModalBottomSheet<_FamilyMember>(
    context: context,
    backgroundColor: const Color(0xFFF7F6F8),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choisir un membre',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: Colors.white,
                      title: Text(
                        member.fullName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: member.role.isNotEmpty
                          ? Text(
                              member.role,
                              style: theme.textTheme.bodySmall,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(member),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _createRendezVous(
  BuildContext context,
  String medecinFamilleId,
  String familyMemberId,
  DateTime slot,
) async {
  final dateStr =
      '${slot.year.toString().padLeft(4, '0')}-${slot.month.toString().padLeft(2, '0')}-${slot.day.toString().padLeft(2, '0')}';
  final timeStr = '${_formatTime(slot)}:00';
  try {
    await Supabase.instance.client.from('rendez_vous').insert({
      'medecin_famille_id': medecinFamilleId,
      'family_member_id': familyMemberId,
      'date': dateStr,
      'heure': timeStr,
      'note': null,
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'RDV confirme: $dateStr a ${_formatTime(slot)}',
        ),
      ),
    );
  } on PostgrestException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur DB: ${e.message}')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  }
}
