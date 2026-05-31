import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/healthsync_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/doctor_images.dart';
import 'doctor_profile_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final _healthsync = HealthsyncService(Supabase.instance.client);
  final _searchController = TextEditingController();
  bool _loading = true;
  List<HealthsyncDoctor> _doctors = const [];
  List<String> _specialties = const [];
  List<String> _cities = const [];
  String _selectedSpecialty = 'Tous';
  String _selectedCity = 'Toutes';
  String? _familyId;
  final Set<String> _linkedDoctorIds = {};

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    try {
      final familyContext = await _healthsync.getCurrentFamilyContext();
      final doctors = await _healthsync.getDoctors();
      final specialties = <String>{
        for (final doctor in doctors)
          if (doctor.specialty.trim().isNotEmpty) doctor.specialty.trim(),
      }.toList()
        ..sort();
      final cities = <String>{
        for (final doctor in doctors)
          for (final establishment in doctor.establishments)
            if (establishment.ville.trim().isNotEmpty) establishment.ville.trim(),
      }.toList()
        ..sort();

      final familyId = familyContext?.familyId;
      if (familyId != null) {
        final linked = await Supabase.instance.client
            .from('family_medecins')
            .select('medecin_id')
            .eq('family_id', familyId);
        _linkedDoctorIds
          ..clear()
          ..addAll((linked as List<dynamic>)
              .map((row) => row['medecin_id']?.toString())
              .whereType<String>());
      }

      if (!mounted) return;
      setState(() {
        _familyId = familyId;
        _doctors = doctors;
        _specialties = specialties;
        _cities = cities;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<HealthsyncDoctor> get _filteredDoctors {
    final query = _searchController.text.trim().toLowerCase();
    return _doctors.where((doctor) {
      final matchesSpecialty = _selectedSpecialty == 'Tous' ||
          doctor.specialty == _selectedSpecialty;
      final matchesCity = _selectedCity == 'Toutes' ||
          doctor.establishments.any((item) => item.ville == _selectedCity);
      final haystack = [
        doctor.fullName,
        doctor.specialty,
        doctor.email,
        doctor.phone,
        ...doctor.establishments.map((item) => item.nom),
        ...doctor.establishments.map((item) => item.ville),
      ].whereType<String>().join(' ').toLowerCase();
      final matchesQuery = query.isEmpty || haystack.contains(query);
      return matchesSpecialty && matchesCity && matchesQuery;
    }).toList();
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

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Rechercher un medecin',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Medecin, specialite, etablissement, ville',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSpecialty,
                        decoration: const InputDecoration(
                          labelText: 'Specialite',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ['Tous', ..._specialties]
                            .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedSpecialty = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'Ville',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: ['Toutes', ..._cities]
                            .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedCity = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredDoctors.isEmpty
                        ? const Center(child: Text('Aucun medecin trouve.'))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            itemCount: _filteredDoctors.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doctor = _filteredDoctors[index];
                              final alreadyLinked = _linkedDoctorIds.contains(doctor.id);
                              final imageUrl = doctor.photoUrl?.isNotEmpty == true
                                  ? doctor.photoUrl!
                                  : imageUrlForSpecialty(doctor.specialty);
                              return _DoctorCard(
                                doctor: doctor,
                                imageUrl: imageUrl,
                                alreadyLinked: alreadyLinked,
                                canAdd: _familyId != null && !alreadyLinked,
                                onAdd: () async {
                                  if (_familyId == null) return;
                                  await _healthsync.ensureFamilyDoctorLink(
                                    familyId: _familyId!,
                                    medecinId: doctor.id,
                                  );
                                  if (!mounted) return;
                                  setState(() => _linkedDoctorIds.add(doctor.id));
                                },
                                onOpen: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DoctorProfileScreen(
                                        doctorId: doctor.id,
                                        name: doctor.fullName,
                                        specialty: doctor.specialty,
                                        location: _doctorSummaryLocation(doctor),
                                        imageUrl: imageUrl,
                                      ),
                                    ),
                                  );
                                },
                                onBook: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => DoctorProfileScreen(
                                        doctorId: doctor.id,
                                        name: doctor.fullName,
                                        specialty: doctor.specialty,
                                        location: _doctorSummaryLocation(doctor),
                                        imageUrl: imageUrl,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.doctor,
    required this.imageUrl,
    required this.alreadyLinked,
    required this.canAdd,
    required this.onAdd,
    required this.onOpen,
    required this.onBook,
  });

  final HealthsyncDoctor doctor;
  final String imageUrl;
  final bool alreadyLinked;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onOpen;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = doctor.primaryEstablishment;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${doctor.fullName}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.specialty,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (doctor.note != null) ...[
                        const SizedBox(height: 6),
                        Text('Note: ${doctor.note!.toStringAsFixed(1)}'),
                      ],
                      if (doctor.langues.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Langues: ${doctor.langues.join(', ')}'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (primary != null) ...[
              Text(
                primary.nom,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(_establishmentAddress(primary)),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: doctor.establishments
                  .take(3)
                  .map((item) => Chip(label: Text(item.displayLabel)))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onOpen,
                    child: const Text('Voir disponibilites'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBook,
                    child: const Text('Prendre RDV'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canAdd ? onAdd : null,
                    child: Text(alreadyLinked ? 'Deja ajoute' : 'Ajouter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _establishmentAddress(DoctorEstablishment establishment) {
  final parts = <String>[
    if (establishment.ville.trim().isNotEmpty) establishment.ville.trim(),
    if (establishment.adresse.trim().isNotEmpty) establishment.adresse.trim(),
  ];
  if (parts.isNotEmpty) return parts.join(', ');
  return establishment.typeEtablissement;
}

String _doctorSummaryLocation(HealthsyncDoctor doctor) {
  final primary = doctor.primaryEstablishment;
  if (primary == null) return doctor.email ?? 'Medecin';
  return _establishmentAddress(primary);
}
