import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'calendar/calendar_screen.dart';
import 'welcome_screen.dart';
import 'family/family_screen.dart';
import 'doctors/doctor_list_screen.dart';
import 'medication/medication_planning_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _family;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('family_members')
          .select('family_id, families (family_name)')
          .eq('auth_user_id', user.id)
          .limit(1)
          .maybeSingle();

      setState(() {
        _family = data == null ? null : data['families'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (_) {
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

          final familyName =
              _family?['family_name']?.toString().trim().isNotEmpty == true
                  ? _family!['family_name'].toString()
                  : 'Famille';

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
                      title: Text(
                        'Parametres',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF2D0A4E),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FamilyCard(
                              familyName:
                                  _loading ? 'Chargement...' : 'Famille $familyName',
                              onManageMembers: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const FamilyScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Compte Personnel',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2D0A4E),
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _SettingsGroup(
                              children: const [
                                _SettingsRow(
                                  icon: Icons.person,
                                  label: 'Modifier mes infos',
                                ),
                                _DividerLine(),
                                _SettingsRow(
                                  icon: Icons.lock,
                                  label: 'Securite',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _LogoutButton(
                              onTap: () async {
                                final shouldSignOut = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Se deconnecter ?'),
                                    content: const Text(
                                      'Voulez-vous vraiment vous deconnecter ?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(dialogContext)
                                                .pop(false),
                                        child: const Text('Annuler'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(dialogContext)
                                                .pop(true),
                                        child: const Text('Se deconnecter'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldSignOut == true) {
                                  await Supabase.instance.client.auth.signOut();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const WelcomeScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Version 2.4.1 (Build 108)',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.black38,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({required this.familyName, required this.onManageMembers});

  final String familyName;
  final VoidCallback onManageMembers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _AvatarStack(),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    familyName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D0A4E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compte Premium Famille',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsRow(
            icon: Icons.group,
            label: 'Gerer les membres',
            showChevron: true,
            onTap: onManageMembers,
          ),
          _SettingsRow(
            icon: Icons.medication,
            label: 'Medicaments & Planning',
            showChevron: true,
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const MedicationPlanningScreen(),
                ),
              );
            },
          ),
          _SettingsRow(
            icon: Icons.medical_services,
            label: 'Gerer les medecins',
            showChevron: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DoctorListScreen()),
              );
            },
          ),
          const _SettingsRow(
            icon: Icons.card_membership,
            label: 'Abonnement Famille',
            showChevron: true,
          ),
          const _SettingsRow(
            icon: Icons.notifications_active,
            label: 'Notifications de groupe',
            showChevron: true,
          ),
          const _SettingsRow(
            icon: Icons.share,
            label: 'Confidentialite et Partage',
            showChevron: true,
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    const urls = [
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDKBNFon7yMDR3Di7SJvZarsOS77qeVjD5BFRnJrCSfx-Ea3Iz8ySv9q4Bz3xXE5xDezZjMIlKMVOITdOCvavatVIt68gYRTbls14IHRMvb-uu41T5OjD-9rVJHxvHqStF0mEqE1b0FFQNfc6G_wbutjfWoTRqjl1u86U_60hIwFrHKYkfWQVJoszbZ6qcnIXo8g27erm0sP6ks5DhjKllUdhXmgMUOqFuq9WzUF5Khl0hMXhx5Ouqt6PAIINFiHYYwleRdtkAZZ1Yw',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAY6lvv8vRlHNQMoa2s0mMoaM3skXYxHnaHvoDVleBFHpbJglmAFO7VEfP0QHrovrTAq1u3kn6U5b0SRZFWCrg1I2fz7TYylpVKPkCfJgOvnA2xPHJTtADDjIwkDAWPcdd2iKK3iXBUB2VCbV05PR2N92HQNEVJ-ASLkdakIGkKBgsqOyWyMO7brLfckgm0T_0nJOUxUjpmtxpAtJkY-jxrwkMRC_qvfEclUPcqNh2SaA4Tgfc-tLtfVUvCdCC9JQRF0Sa8jPVhw5TB',
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB5qPqQ8vaSivmbodv9AIeXatHCgp4SWqfukhYBQBLEKTxN-P3B4okIXJrEVZ-0N3Hqp3GLvXuqRtteWJKbJpbmccmlsJnbS86TURKV6DBGM7LMkmRswPJouez4LLyeqblwCUvbzYHd1BVz3Nw8_LNWE2SsUEg6MOagTvMjW7pyYIIsxf0m_9kdnSl7G84uM30ttnO1PqFqffPtD96maI2daQjW_HCBwoTeQ1MC5ET7bJXNHlKPzEIYpuTiNMWxnBMlBbshew7613Cp',
    ];

    return SizedBox(
      width: 78,
      height: 40,
      child: Stack(
        children: [
          for (int i = 0; i < urls.length; i++)
            Positioned(
              left: i * 20.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(urls[i]),
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: _cardDecoration(theme),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.showChevron = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, color: Colors.black38, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5D0D0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text(
                'Deconnexion',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(ThemeData theme) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
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
