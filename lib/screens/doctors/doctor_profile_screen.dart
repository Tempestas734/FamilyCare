import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/healthsync_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/doctor_images.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({
    super.key,
    required this.doctorId,
    required this.name,
    required this.specialty,
    required this.location,
    required this.imageUrl,
    this.etablissementId,
    this.photoUrl,
    this.bio,
    this.cliniqueNom,
    this.adresse,
    this.latitude,
    this.longitude,
    this.langues = const [],
    this.tarifMin,
    this.tarifMax,
    this.secteur,
    this.note,
    this.disponibilite,
    this.typesConsultation = const [],
  });

  final String doctorId;
  final String name;
  final String specialty;
  final String location;
  final String imageUrl;
  final String? etablissementId;
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

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _healthsync = HealthsyncService(Supabase.instance.client);
  bool _loading = true;
  HealthsyncDoctor? _doctor;
  DoctorEstablishment? _selectedEstablishment;
  List<DoctorAvailabilityDay> _availability = const [];
  List<DoctorUnavailability> _unavailabilities = const [];
  List<DateTime> _takenSlots = const [];
  List<DateTime> _availableSlots = const [];

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    try {
      final doctor = await _healthsync.getDoctorById(widget.doctorId);
      if (doctor == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      final establishment = doctor.establishments.firstWhere(
        (item) => item.etablissementId == widget.etablissementId,
        orElse: () => doctor.establishments.first,
      );
      if (!mounted) return;
      setState(() {
        _doctor = doctor;
        _selectedEstablishment = establishment;
      });
      await _loadAvailabilityFor(establishment);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAvailabilityFor(DoctorEstablishment establishment) async {
    final doctor = _doctor;
    if (doctor == null) return;
    setState(() => _loading = true);
    try {
      final from = DateTime.now();
      final to = from.add(const Duration(days: 14));
      final availability = await _healthsync.getDoctorAvailability(
        medecinId: doctor.id,
        etablissementId: establishment.etablissementId,
      );
      final unavailabilities = await _healthsync.getDoctorUnavailabilities(
        medecinId: doctor.id,
        etablissementId: establishment.etablissementId,
        from: from,
        to: to,
      );
      final takenSlots = await _healthsync.getTakenAppointmentSlots(
        medecinId: doctor.id,
        etablissementId: establishment.etablissementId,
        from: DateTime(from.year, from.month, from.day),
        to: DateTime(to.year, to.month, to.day + 1),
      );
      final availableSlots = _healthsync.buildAvailableSlots(
        availability: availability,
        unavailabilities: unavailabilities,
        takenSlots: takenSlots,
        from: from,
      );
      if (!mounted) return;
      setState(() {
        _selectedEstablishment = establishment;
        _availability = availability;
        _unavailabilities = unavailabilities;
        _takenSlots = takenSlots;
        _availableSlots = availableSlots;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _bookAppointment() async {
    final doctor = _doctor;
    final establishment = _selectedEstablishment;
    if (doctor == null || establishment == null || _availableSlots.isEmpty) {
      return;
    }
    final member = await _pickFamilyMember(context);
    if (!mounted || member == null) return;

    final slot = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final grouped = _groupSlotsByDay(_availableSlots);
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Text(
                'Choisir un creneau',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...grouped.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.value
                            .map(
                              (item) => ChoiceChip(
                                label: Text(_formatTime(item)),
                                selected: false,
                                onSelected: (_) => Navigator.of(context).pop(item),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
    if (!mounted || slot == null) return;

    try {
      final familyId = (await _healthsync.getCurrentFamilyContext())?.familyId;
      if (familyId == null) {
        throw StateError('Famille introuvable');
      }
      await _healthsync.createFamilyAppointment(
        familyId: familyId,
        familyMemberId: member.id,
        medecinId: doctor.id,
        etablissementId: establishment.etablissementId,
        scheduledAt: slot,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'RDV cree pour ${_formatDate(slot)} a ${_formatTime(slot)}',
          ),
        ),
      );
      await _loadAvailabilityFor(establishment);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.seed,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F6F8),
    );
    final doctor = _doctor;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: const Text('Fiche du praticien'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : doctor == null
                ? const Center(child: Text('Medecin introuvable.'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      _DoctorHeader(doctor: doctor),
                      const SizedBox(height: 16),
                      if (doctor.establishments.length > 1)
                        DropdownButtonFormField<String>(
                          initialValue: _selectedEstablishment?.etablissementId,
                          decoration: const InputDecoration(
                            labelText: 'Etablissement',
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: doctor.establishments
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.etablissementId,
                                  child: Text(item.displayLabel),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final establishment = doctor.establishments.firstWhere(
                              (item) => item.etablissementId == value,
                            );
                            _loadAvailabilityFor(establishment);
                          },
                        ),
                      if (_selectedEstablishment != null) ...[
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Etablissement',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedEstablishment!.nom,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(_selectedEstablishment!.adresse),
                              const SizedBox(height: 4),
                              Text(_selectedEstablishment!.ville),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Horaires',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _availability.isEmpty
                              ? const [Text('Aucun horaire actif.')]
                              : _availability
                                  .map(
                                    (day) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        '${_weekdayLabel(day.weekday)}: ${day.intervals.map((item) => '${_trimTime(item.startTime)}-${_trimTime(item.endTime)}').join(', ')}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Indisponibilites',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _unavailabilities.isEmpty
                              ? const [Text('Aucune indisponibilite sur 14 jours.')]
                              : _unavailabilities
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        '${_formatDate(item.startDate)} - ${_formatDate(item.endDate)} ${item.reason ?? item.type}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Disponibilites',
                        child: _availableSlots.isEmpty
                            ? const Text('Aucun creneau disponible.')
                            : Text(
                                '${_availableSlots.length} creneaux disponibles sur 14 jours',
                              ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _availableSlots.isEmpty ? null : _bookAppointment,
                          icon: const Icon(Icons.event_available),
                          label: const Text('Prendre rendez-vous'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _DoctorHeader extends StatelessWidget {
  const _DoctorHeader({required this.doctor});

  final HealthsyncDoctor doctor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = doctor.photoUrl?.isNotEmpty == true
        ? doctor.photoUrl!
        : imageUrlForSpecialty(doctor.specialty);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 36, backgroundImage: NetworkImage(imageUrl)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${doctor.fullName}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(doctor.specialty),
                if (doctor.email != null) ...[
                  const SizedBox(height: 4),
                  Text(doctor.email!),
                ],
                if (doctor.phone != null) Text(doctor.phone!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FamilyMemberChoice {
  const _FamilyMemberChoice({
    required this.id,
    required this.name,
    required this.role,
  });

  final String id;
  final String name;
  final String role;
}

Future<_FamilyMemberChoice?> _pickFamilyMember(BuildContext context) async {
  final service = HealthsyncService(Supabase.instance.client);
  final familyId = (await service.getCurrentFamilyContext())?.familyId;
  if (familyId == null) return null;
  final members = await service.getFamilyMembers(familyId);
  if (!context.mounted || members.isEmpty) return null;
  return showModalBottomSheet<_FamilyMemberChoice>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: members
              .map(
                (member) => ListTile(
                  title: Text(member.fullName),
                  subtitle: Text(member.relationshipRole),
                  onTap: () => Navigator.of(context).pop(
                    _FamilyMemberChoice(
                      id: member.id,
                      name: member.fullName,
                      role: member.relationshipRole,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    },
  );
}

Map<DateTime, List<DateTime>> _groupSlotsByDay(List<DateTime> slots) {
  final grouped = <DateTime, List<DateTime>>{};
  for (final slot in slots) {
    final key = DateTime(slot.year, slot.month, slot.day);
    grouped.putIfAbsent(key, () => []).add(slot);
  }
  return Map.fromEntries(
    grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

String _weekdayLabel(int weekday) {
  const labels = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
  return labels[weekday.clamp(0, 6)];
}

String _trimTime(String raw) {
  return raw.length >= 5 ? raw.substring(0, 5) : raw;
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
