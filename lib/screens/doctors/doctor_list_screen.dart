import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/healthsync_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/doctor_images.dart';
import '../../widgets/app_bottom_nav.dart';
import '../home_screen.dart';
import 'doctor_profile_screen.dart';
import 'doctor_search_screen.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final _healthsync = HealthsyncService(Supabase.instance.client);
  bool _loading = true;
  List<HealthsyncDoctorLink> _doctors = const [];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final familyId = (await _healthsync.getCurrentFamilyContext())?.familyId;
      if (familyId == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
      final doctors = await _healthsync.getFamilyDoctors(familyId);
      if (!mounted) return;
      setState(() {
        _doctors = doctors;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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
    return Theme(
      data: theme,
      child: Scaffold(
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
                        Expanded(
                          child: Text(
                            'Ma liste de medecins',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
                            ? const Center(child: Text('Aucun medecin ajoute.'))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                                itemCount: _doctors.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final doctor = _doctors[index];
                                  final imageUrl = doctor.doctor.photoUrl?.isNotEmpty == true
                                      ? doctor.doctor.photoUrl!
                                      : imageUrlForSpecialty(doctor.doctor.specialty);
                                  return ListTile(
                                    tileColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(imageUrl),
                                    ),
                                    title: Text('Dr. ${doctor.doctor.fullName}'),
                                    subtitle: Text(
                                      '${doctor.doctor.specialty}\n${doctor.doctor.primaryEstablishment?.displayLabel ?? ''}',
                                    ),
                                    isThreeLine: true,
                                    trailing: IconButton(
                                      onPressed: () async {
                                        await Supabase.instance.client
                                            .from('family_medecins')
                                            .delete()
                                            .eq('id', doctor.id);
                                        _loadDoctors();
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => DoctorProfileScreen(
                                            doctorId: doctor.doctor.id,
                                            name: doctor.doctor.fullName,
                                            specialty: doctor.doctor.specialty,
                                            location: doctor.doctor.primaryEstablishment?.displayLabel ??
                                                '',
                                            imageUrl: imageUrl,
                                            etablissementId:
                                                doctor.doctor.primaryEstablishment?.etablissementId,
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
      ),
    );
  }
}
