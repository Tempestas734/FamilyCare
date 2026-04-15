import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../utils/doctor_images.dart';
import 'doctor_profile_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final _searchController = TextEditingController();
  bool _loading = true;
  List<_Doctor> _doctors = [];
  List<String> _specialties = [];
  String _activeFilter = 'Tous';
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

      final data = await Supabase.instance.client
          .from('medecins')
          .select('id, first_name, last_name, telephone, specialite, email, ville, pays, photo_url, bio, clinique_nom, adresse, latitude, longitude, langues, tarif_min, tarif_max, secteur, note, disponibilite, types_consultation')
          .order('last_name');
      final items = (data as List<dynamic>)
          .map((row) => _Doctor.fromMap(row as Map<String, dynamic>))
          .toList();
      final specialtySet = <String>{};
      for (final doctor in items) {
        final value = doctor.specialite.trim();
        if (value.isNotEmpty) {
          specialtySet.add(value);
        }
      }
      final specialties = specialtySet.toList()..sort();
      if (familyId != null) {
        final linked = await Supabase.instance.client
            .from('medecins_famille')
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
        _doctors = items;
        _specialties = specialties;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<_Doctor> get _filteredDoctors {
    final query = _searchController.text.trim().toLowerCase();
    return _doctors.where((doctor) {
      final matchesFilter = _activeFilter == 'Tous' ||
          doctor.specialite.toLowerCase().contains(_activeFilter.toLowerCase());
      final matchesQuery = query.isEmpty ||
          doctor.firstName.toLowerCase().contains(query) ||
          doctor.lastName.toLowerCase().contains(query) ||
          doctor.specialite.toLowerCase().contains(query) ||
          doctor.ville.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
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
          return Scaffold(
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
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Rechercher un medecin',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                    child: _SearchField(controller: _searchController),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _Chip(
                          label: 'Tous',
                          active: _activeFilter == 'Tous',
                          onTap: () => setState(() => _activeFilter = 'Tous'),
                        ),
                        ..._specialties.map(
                          (specialty) => _Chip(
                            label: specialty,
                            active: _activeFilter == specialty,
                            onTap: () =>
                                setState(() => _activeFilter = specialty),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredDoctors.isEmpty
                            ? Center(
                                child: Text(
                                  'Aucun medecin trouve.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              )
                            : ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Medecins a proximite',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Voir tout',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ..._filteredDoctors.map((doctor) {
                                    final alreadyLinked = _linkedDoctorIds.contains(doctor.id);
                                    final imageUrl = doctor.photoUrl?.isNotEmpty == true
                                      ? doctor.photoUrl!
                                      : imageUrlForSpecialty(doctor.specialite);
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _DoctorCard(
                                        name: 'Dr. ${doctor.firstName} ${doctor.lastName}',
                                        specialty: doctor.specialite,
                                        distance: '${doctor.ville} - ${doctor.pays}',
                                        rating: doctor.note?.toStringAsFixed(1) ?? '—',
                                        imageUrl: imageUrl,
                                        onAdd: (_familyId == null || alreadyLinked) ? null : () async {
                                          final user = Supabase.instance.client.auth.currentUser;
                                          debugPrint('DoctorSearch: user=${user?.id} familyId=$_familyId doctorId=${doctor.id}');
                                          if (user != null) {
                                            final adminRow = await Supabase.instance.client
                                                .from('family_members')
                                                .select('is_admin, family_id')
                                                .eq('auth_user_id', user.id)
                                                .maybeSingle();
                                            debugPrint('DoctorSearch: adminRow=$adminRow');
                                          }
                                          await Supabase.instance.client.from('medecins_famille').insert({
                                            'family_id': _familyId,
                                            'medecin_id': doctor.id,
                                          });
                                          _linkedDoctorIds.add(doctor.id);
                                          if (mounted) {
                                            setState(() {});
                                          }
                                        },
                                        onTap: () async {
                                          final added = await Navigator.of(context).push<bool>(
                                            MaterialPageRoute(
                                              builder: (_) => DoctorProfileScreen(
                                                doctorId: doctor.id,
                                                name: 'Dr. ${doctor.firstName} ${doctor.lastName}',
                                                specialty: doctor.specialite,
                                                location: '${doctor.ville}, ${doctor.pays}',
                                                imageUrl: imageUrl,
                                                photoUrl: doctor.photoUrl,
                                                bio: doctor.bio,
                                                cliniqueNom: doctor.cliniqueNom,
                                                adresse: doctor.adresse,
                                                langues: doctor.langues,
                                                latitude: doctor.latitude,
                                                longitude: doctor.longitude,
                                                tarifMin: doctor.tarifMin,
                                                tarifMax: doctor.tarifMax,
                                                secteur: doctor.secteur,
                                                note: doctor.note,
                                                disponibilite: doctor.disponibilite,
                                                typesConsultation: doctor.typesConsultation,
                                              ),
                                            ),
                                          );
                                          if (added == true) {
                                            _linkedDoctorIds.add(doctor.id);
                                            if (mounted) setState(() {});
                                          }
                                        },
                                      ),
                                    );
                                  }),
                              ],
                            ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF0F3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Nom, specialite ou ville',
          hintStyle: theme.textTheme.bodySmall?.copyWith(
            color: Colors.black45,
          ),
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.active = false,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: active ? Colors.white : theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.name,
    required this.specialty,
    required this.distance,
    required this.rating,
    required this.imageUrl,
    this.onAdd,
    required this.onTap,
  });

  final String name;
  final String specialty;
  final String distance;
  final String rating;
  final String imageUrl;
  final VoidCallback? onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1EEF7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
        child: Column(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFF59E0B),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFFB45309),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            distance,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black45,
                            ),
                            overflow: TextOverflow.ellipsis,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter a ma liste'),
            ),
          ),
          ],
        ),
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
