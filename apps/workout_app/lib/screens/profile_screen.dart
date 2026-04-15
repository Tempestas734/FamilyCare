import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'sessions_screen.dart';
import '../utils/avatar_urls.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de deconnexion: $e')),
      );
      setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8F7F6);
    final profileName = _connectedProfileName();
    final avatarUrl = _connectedProfileAvatar();
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
                color: const Color.fromRGBO(248, 247, 246, 0.92),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Image.network(
                            avatarUrl,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEE8C2B),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Profil',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D241D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profileName,
                      style: TextStyle(
                        color: Color(0xFF78716C),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Total entrainements',
                            value: '12',
                            suffix: 'seances',
                            valueColor: Color(0xFFEE8C2B),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Calories totales',
                            value: '5.2',
                            suffix: 'k kcal',
                            valueColor: Color(0xFFFBA77E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF5F5F4)),
                      ),
                      child: Column(
                        children: [
                          _ProfileAction(
                            icon: Icons.track_changes,
                            label: 'Objectifs personnels',
                            onTap: _comingSoon,
                          ),
                          _ProfileAction(
                            icon: Icons.history,
                            label: 'Historique des seances',
                            onTap: _comingSoon,
                          ),
                          _ProfileAction(
                            icon: Icons.military_tech,
                            label: 'Badges et recompenses',
                            onTap: _comingSoon,
                          ),
                          _ProfileAction(
                            icon: Icons.settings,
                            label: 'Parametres du compte',
                            onTap: _comingSoon,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _loggingOut ? null : _logout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEE8C2B),
                          side: const BorderSide(
                            color: Color.fromRGBO(238, 140, 43, 0.24),
                            width: 2,
                          ),
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _loggingOut ? 'Deconnexion...' : 'DECONNEXION',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNavProfile(
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
            return;
          }
          if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const SessionsScreen()),
            );
            return;
          }
          if (index != 3) {
            _comingSoon();
          }
        },
      ),
    );
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bientot disponible.')),
    );
  }

  String _connectedProfileName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Utilisateur';

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final fullName = metadata['full_name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;

    final name = metadata['name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final email = user.email?.trim() ?? '';
    if (email.isNotEmpty) return email.split('@').first;

    return 'Utilisateur';
  }

  String _connectedProfileAvatar() {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role']?.toString();
    return avatarForRole(role);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.suffix,
    required this.valueColor,
  });

  final String title;
  final String value;
  final String suffix;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5F5F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFFA8A29E),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  suffix,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF78716C),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF5F5F4)),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(238, 140, 43, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFEE8C2B), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF292524),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD6D3D1)),
          ],
        ),
      ),
    );
  }
}

class _BottomNavProfile extends StatelessWidget {
  const _BottomNavProfile({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.93),
        border: Border(top: BorderSide(color: Color(0xFFE7E5E4))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(icon: Icons.grid_view, label: 'Dashboard', active: false, onTap: () => onTap(0)),
          _NavItem(icon: Icons.fitness_center, label: 'Seances', active: false, onTap: () => onTap(1)),
          _NavItem(icon: Icons.leaderboard, label: 'Progres', active: false, onTap: () => onTap(2)),
          _NavItem(icon: Icons.person, label: 'Profil', active: true, onTap: () => onTap(3)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFEE8C2B) : const Color(0xFFA8A29E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
