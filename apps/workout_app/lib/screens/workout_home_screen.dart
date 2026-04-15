import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_screen.dart';
import 'sessions_screen.dart';
import '../utils/avatar_urls.dart';

class WorkoutHomeScreen extends StatefulWidget {
  const WorkoutHomeScreen({super.key});

  @override
  State<WorkoutHomeScreen> createState() => _WorkoutHomeScreenState();
}

class _WorkoutHomeScreenState extends State<WorkoutHomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8F7F6);
    final profileName = _connectedProfileName();
    final avatarUrl = _connectedProfileAvatar();
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _HomeHeader(profileName: profileName, avatarUrl: avatarUrl),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, 110),
                      child: Column(
                        children: [
                          _ActivityCard(),
                          SizedBox(height: 22),
                          _ProgramsSection(),
                          SizedBox(height: 22),
                          _QuickStatsSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _tabIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SessionsScreen()),
            );
            return;
          }
          if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            );
            return;
          }
          setState(() => _tabIndex = index);
        },
      ),
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
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final role = metadata['role']?.toString();
    return avatarForRole(role);
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.profileName, required this.avatarUrl});

  final String profileName;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 18),
      color: const Color.fromRGBO(248, 247, 246, 0.92),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue',
                  style: TextStyle(
                    color: Color(0xFFEE8C2B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  profileName,
                  style: TextStyle(
                    color: Color(0xFF2D241D),
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Image.network(
                  avatarUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF8F7F6), width: 2),
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(238, 140, 43, 0.13)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(238, 140, 43, 0.08),
            blurRadius: 26,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Activite du jour',
                  style: TextStyle(
                    color: Color(0xFF2D241D),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(238, 140, 43, 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  "Aujourd'hui",
                  style: TextStyle(
                    color: Color(0xFFEE8C2B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: 185,
                  child: _ProgressRings(),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _LegendItem(
                      label: 'Calories',
                      value: '1,420',
                      suffix: 'kcal',
                      pct: '80%',
                      color: Color(0xFFEE8C2B),
                    ),
                    SizedBox(height: 14),
                    _LegendItem(
                      label: 'Pas',
                      value: '8,542',
                      suffix: 'pas',
                      pct: '72%',
                      color: Color(0xFFFBA77E),
                    ),
                    SizedBox(height: 14),
                    _LegendItem(
                      label: 'Minutes',
                      value: '45',
                      suffix: 'min',
                      pct: '65%',
                      color: Color(0xFFD96D1A),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRings extends StatelessWidget {
  const _ProgressRings();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: const [
        _Ring(size: 170, stroke: 12, progress: 0.8, color: Color(0xFFEE8C2B)),
        _Ring(size: 128, stroke: 12, progress: 0.72, color: Color(0xFFFBA77E)),
        _Ring(size: 86, stroke: 12, progress: 0.65, color: Color(0xFFD96D1A)),
        Icon(Icons.bolt, color: Color(0xFFEE8C2B), size: 34),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.size,
    required this.stroke,
    required this.progress,
    required this.color,
  });

  final double size;
  final double stroke;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          stroke: stroke,
          color: color,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.color,
  });

  final double progress;
  final double stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - stroke / 2;
    final start = -math.pi / 2;
    const full = math.pi * 2;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, base);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      full * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.stroke != stroke ||
        oldDelegate.color != color;
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.value,
    required this.suffix,
    required this.pct,
    required this.color,
  });

  final String label;
  final String value;
  final String suffix;
  final String pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF78716C),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Color(0xFF2D241D)),
                  children: [
                    TextSpan(
                      text: value,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    TextSpan(
                      text: ' $suffix',
                      style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text(
          pct,
          style: const TextStyle(
            color: Color(0xFFA8A29E),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProgramsSection extends StatelessWidget {
  const _ProgramsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Programmes recommandes',
                style: TextStyle(
                  color: Color(0xFF2D241D),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Tout voir',
                style: TextStyle(
                  color: Color(0xFFEE8C2B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const SizedBox(
          height: 300,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ProgramCard(
                  title: 'Yoga Zen',
                  subtitle: '25 min • Debutant',
                  tag: 'Souplesse',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuC9MzGbXWRplGt7_nVBxTEG85NuCSPtzKCevs-kjKQwRhJ2l26IPGU0UQjmymBgM37tIqEmU_SKQmCfDe2TJKXI-Qywil3IPtmaQrt6eU-Zgh0r8OD9e7CmU_QRwrCCrFRaUylBa9TuFkq35Gj96-hZdckBAsfVjfcTdzgkYcWVf8xezzxrmFlxCJE9nwHyHmul_Inj_743FD9UxPcI6iA5tGkopMZxyEQjo8_aIURxFo2gYZ2YHNiDta2UXYi7MX6uK0_VdFnqsNwC',
                ),
                SizedBox(width: 14),
                _ProgramCard(
                  title: 'HIIT Cardio',
                  subtitle: '40 min • Intense',
                  tag: 'Endurance',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAMjCJl4FoyqhfBS0YuVBQW_x28AUWOG_tKXwUpd9fgw5eINIwESWihYmKaVd5o5vRkY19DUKb2Y4pKokKe6tq5Jn-UlHY3CwdNDPnI9j9EeEltv8i6uMNkvA3RjsigFOKt-xw_iHjOd4yugNvbn3WPTND5audTvRPoVVu5sxxKaKD8aNKlW2qq2mYqNEF0uiLgE0xTKyDHs70QI_1OM1bu1cQxZXi0pXlnuYqXN--Ww9uZs7Lb0x1Kc_e_lFaYF4MecGDOzfO2S9P_',
                ),
                SizedBox(width: 14),
                _ProgramCard(
                  title: 'Full Body Strength',
                  subtitle: '50 min • Avance',
                  tag: 'Force',
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDSQF4tye1nUO6-gpHfIwjWtnfWWY5rNJCkye9I7EHnmX-J8wjcYqzpRoQy-sBg25Yx1-9V9XmrJshfpTnjKM00-JjuA2rb0i7v3HVTtkBCpLdWzBG7YY01G6MsbaPa6HZLRQmi5IsI0cRPENl4eAI3uub3ttu4gs9RWxZU8qKxuXgjyteU6GoMHYNuO-blpyb6TJieA56G7Hw43MINXt1sbGJJ_xOwsqOAlDlrT9SpC1Jm74OdevMowlY6g9jNjFbwg1oWccba55RS',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String tag;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        width: 250,
        height: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imageUrl, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0, 0, 0, 0.0),
                    Color.fromRGBO(0, 0, 0, 0.25),
                    Color.fromRGBO(0, 0, 0, 0.8),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(238, 140, 43, 0.24),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color.fromRGBO(255, 255, 255, 0.25),
                      ),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsSection extends StatelessWidget {
  const _QuickStatsSection();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            bgColor: Color.fromRGBO(238, 140, 43, 0.08),
            borderColor: Color.fromRGBO(238, 140, 43, 0.12),
            iconBg: Color(0xFFEE8C2B),
            icon: Icons.history,
            title: 'Historique',
            value: '12 Seances',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            bgColor: Color.fromRGBO(251, 167, 126, 0.1),
            borderColor: Color.fromRGBO(251, 167, 126, 0.2),
            iconBg: Color(0xFFFBA77E),
            icon: Icons.emoji_events,
            title: 'Badges',
            value: '8 Recus',
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.bgColor,
    required this.borderColor,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.value,
  });

  final Color bgColor;
  final Color borderColor;
  final Color iconBg;
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF78716C),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF2D241D),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
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
          _NavItem(
            icon: Icons.grid_view,
            label: 'Dashboard',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.fitness_center,
            label: 'Seances',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.leaderboard,
            label: 'Progres',
            selected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profil',
            selected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFEE8C2B) : const Color(0xFFA8A29E);
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
