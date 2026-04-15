import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'sessions_screen.dart';
import 'workout_home_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({
    super.key,
    required this.title,
    required this.category,
    required this.secondaryTag,
    required this.imageUrl,
    required this.duration,
    required this.level,
  });

  final String title;
  final String category;
  final String secondaryTag;
  final String imageUrl;
  final String duration;
  final String level;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  bool _favorite = false;

  @override
  Widget build(BuildContext context) {
    final detail = _detailData();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeroSection(
                  imageUrl: widget.imageUrl,
                  favorite: _favorite,
                  onBack: () => Navigator.of(context).pop(),
                  onFavorite: () => setState(() => _favorite = !_favorite),
                  onPlay: _startSession,
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F7F6),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      color: Color(0xFF2D241D),
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Par ${detail.coach}  |  Coach expert',
                                    style: const TextStyle(
                                      color: Color(0xFF78716C),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(238, 140, 43, 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                widget.category.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFEE8C2B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                icon: Icons.schedule,
                                iconColor: const Color(0xFFEE8C2B),
                                label: 'Duree',
                                value: widget.duration,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatBox(
                                icon: Icons.signal_cellular_alt,
                                iconColor: const Color(0xFFFBA77E),
                                label: 'Niveau',
                                value: widget.level,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatBox(
                                icon: Icons.local_fire_department,
                                iconColor: const Color(0xFFD96D1A),
                                label: 'Calories',
                                value: '${detail.calories} kcal',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Equipement requis',
                          style: TextStyle(
                            color: Color(0xFF2D241D),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: detail.equipments
                              .map(
                                (e) => _EquipmentPill(
                                  icon: e.icon,
                                  label: e.label,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Contenu de la seance',
                                style: TextStyle(
                                  color: Color(0xFF2D241D),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${detail.exercises.length} exercices',
                              style: const TextStyle(
                                color: Color(0xFFA8A29E),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: detail.exercises
                              .map(
                                (exercise) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ExerciseTile(exercise: exercise),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 100,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startSession,
                icon: const Icon(Icons.play_circle_filled),
                label: const Text('Commencer la seance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEE8C2B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavDetail(
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const WorkoutHomeScreen()),
              (route) => false,
            );
            return;
          }
          if (index == 1) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const SessionsScreen()),
              (route) => false,
            );
            return;
          }
          if (index == 3) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              (route) => false,
            );
            return;
          }
        },
      ),
    );
  }

  void _startSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Seance lancee: ${widget.title}')),
    );
  }

  _SessionDetailData _detailData() {
    if (widget.title.toLowerCase().contains('yoga')) {
      return _SessionDetailData(
        coach: 'Sarah Martin',
        calories: 180,
        equipments: const [
          _EquipmentItem(icon: Icons.self_improvement, label: 'Tapis de yoga'),
        ],
        exercises: [
          _ExerciseItem(
            name: 'Salutation au soleil',
            info: '05:00  |  Focus Respiration',
            imageUrl: widget.imageUrl,
          ),
          const _ExerciseItem(
            name: 'Position du Guerrier II',
            info: '03:00  |  Force & Equilibre',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuCEAMcSrLRTCnjI0auwRLq8B8k-eUU21GhVSja8YNHUpON2CaT0Of0YdO41w7kv9ZlRgQmqjPeMgXv5jIB2aA4-nA0JfbXyEKGqQoRNA25e_oV9ya2bYdkEoaiRSXxdbUlIBDbuBekH0OgHHKjAlhckCRjP6fQzYDxrwk5-S98aQLYBbBCUWXBpQxQvHblX5kRq6IIKZlR5hO2ufRflH5zqfFWO23OWVx54Hx3R16FHo47xSKRrhXU5BSCx3A9DRb9All0Yxqlo5nyk',
          ),
          const _ExerciseItem(
            name: 'Etirement Cobra',
            info: '04:30  |  Dos & Abdos',
            imageUrl:
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAMjCJl4FoyqhfBS0YuVBQW_x28AUWOG_tKXwUpd9fgw5eINIwESWihYmKaVd5o5vRkY19DUKb2Y4pKokKe6tq5Jn-UlHY3CwdNDPnI9j9EeEltv8i6uMNkvA3RjsigFOKt-xw_iHjOd4yugNvbn3WPTND5audTvRPoVVu5sxxKaKD8aNKlW2qq2mYqNEF0uiLgE0xTKyDHs70QI_1OM1bu1cQxZXi0pXlnuYqXN--Ww9uZs7Lb0x1Kc_e_lFaYF4MecGDOzfO2S9P_',
          ),
        ],
      );
    }

    return _SessionDetailData(
      coach: 'Coach principal',
      calories: 240,
      equipments: const [
        _EquipmentItem(icon: Icons.sports_gymnastics, label: 'Tenue de sport'),
      ],
      exercises: [
        _ExerciseItem(
          name: 'Echauffement',
          info: '04:00  |  Preparation',
          imageUrl: widget.imageUrl,
        ),
        _ExerciseItem(
          name: 'Bloc principal',
          info: '12:00  |  Intensite',
          imageUrl: widget.imageUrl,
        ),
        _ExerciseItem(
          name: 'Retour au calme',
          info: '05:00  |  Respiration',
          imageUrl: widget.imageUrl,
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.imageUrl,
    required this.favorite,
    required this.onBack,
    required this.onFavorite,
    required this.onPlay,
  });

  final String imageUrl;
  final bool favorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
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
                  Color.fromRGBO(0, 0, 0, 0.3),
                  Color.fromRGBO(0, 0, 0, 0.0),
                  Color.fromRGBO(0, 0, 0, 0.6),
                ],
              ),
            ),
          ),
          Positioned(
            top: 58,
            left: 20,
            right: 20,
            child: Row(
              children: [
                _RoundIconButton(icon: Icons.arrow_back_ios_new, onPressed: onBack),
                const Spacer(),
                _RoundIconButton(
                  icon: favorite ? Icons.favorite : Icons.favorite_border,
                  onPressed: onFavorite,
                ),
              ],
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: onPlay,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(238, 140, 43, 0.9),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(238, 140, 43, 0.42),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5F5F4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF78716C),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF2D241D),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentPill extends StatelessWidget {
  const _EquipmentPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5F5F4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(238, 140, 43, 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFEE8C2B), size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2D241D),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise});

  final _ExerciseItem exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5F5F4)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 62,
              height: 62,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(exercise.imageUrl, fit: BoxFit.cover),
                  Container(
                    color: const Color.fromRGBO(0, 0, 0, 0.12),
                    child: const Icon(
                      Icons.play_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: Color(0xFF2D241D),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  exercise.info,
                  style: const TextStyle(
                    color: Color(0xFF78716C),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Color(0xFFA8A29E), size: 20),
          ),
        ],
      ),
    );
  }
}

class _BottomNavDetail extends StatelessWidget {
  const _BottomNavDetail({required this.onTap});

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
          _NavItem(icon: Icons.grid_view, label: 'Dashboard', selected: false, onTap: () => onTap(0)),
          _NavItem(icon: Icons.fitness_center, label: 'Seances', selected: true, onTap: () => onTap(1)),
          _NavItem(icon: Icons.leaderboard, label: 'Progres', selected: false, onTap: () => onTap(2)),
          _NavItem(icon: Icons.person_outline, label: 'Profil', selected: false, onTap: () => onTap(3)),
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

class _SessionDetailData {
  const _SessionDetailData({
    required this.coach,
    required this.calories,
    required this.equipments,
    required this.exercises,
  });

  final String coach;
  final int calories;
  final List<_EquipmentItem> equipments;
  final List<_ExerciseItem> exercises;
}

class _EquipmentItem {
  const _EquipmentItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _ExerciseItem {
  const _ExerciseItem({
    required this.name,
    required this.info,
    required this.imageUrl,
  });

  final String name;
  final String info;
  final String imageUrl;
}
