import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'program_customization_step1_screen.dart';
import 'session_detail_screen.dart';
import '../services/workout_program_service.dart';
import 'profile_screen.dart';
import 'workout_home_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final WorkoutProgramService _service =
      WorkoutProgramService(Supabase.instance.client);

  String _selectedCategory = 'Tous';
  bool _loading = true;
  bool _togglingFavorite = false;
  List<WorkoutProgramItem> _programs = const [];

  static const List<String> _categories = <String>[
    'Tous',
    'Yoga',
    'Cardio',
    'Force',
    'HIIT',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _Header(
              searchController: _searchController,
              selectedCategory: _selectedCategory,
              categories: _categories,
              onCategorySelected: (category) => setState(() => _selectedCategory = category),
              onSearchChanged: (_) => setState(() {}),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(
                          child: Text('Aucun programme en base. Cree ton premier programme.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _SessionCard(
                              item: item,
                              isFavorite: item.isFavorite,
                              onOpen: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SessionDetailScreen(
                                      title: item.title,
                                      category: item.category,
                                      secondaryTag: item.tag2,
                                      imageUrl: item.imageUrl,
                                      duration: item.duration,
                                      level: item.level,
                                    ),
                                  ),
                                );
                              },
                              onFavoriteToggle: () => _toggleFavorite(item),
                              onPlay: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SessionDetailScreen(
                                      title: item.title,
                                      category: item.category,
                                      secondaryTag: item.tag2,
                                      imageUrl: item.imageUrl,
                                      duration: item.duration,
                                      level: item.level,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemCount: filtered.length,
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavSessions(
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const WorkoutHomeScreen()),
            );
            return;
          }
          if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            );
            return;
          }
        },
      ),
    );
  }

  Future<void> _loadPrograms() async {
    try {
      final rows = await _service.loadProgramsForCurrentUser();
      if (!mounted) return;
      setState(() {
        _programs = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement programmes: $e')),
      );
    }
  }

  Future<void> _toggleFavorite(WorkoutProgramItem item) async {
    if (_togglingFavorite) return;
    setState(() => _togglingFavorite = true);

    final newValue = !item.isFavorite;
    setState(() {
      _programs = _programs
          .map(
            (p) => p.id == item.id
                ? WorkoutProgramItem(
                    id: p.id,
                    title: p.title,
                    category: p.category,
                    tag2: p.tag2,
                    duration: p.duration,
                    level: p.level,
                    imageUrl: p.imageUrl,
                    isFavorite: newValue,
                  )
                : p,
          )
          .toList();
    });

    try {
      await _service.setFavorite(programId: item.id, favorite: newValue);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _programs = _programs
            .map(
              (p) => p.id == item.id
                  ? WorkoutProgramItem(
                      id: p.id,
                      title: p.title,
                      category: p.category,
                      tag2: p.tag2,
                      duration: p.duration,
                      level: p.level,
                      imageUrl: p.imageUrl,
                      isFavorite: item.isFavorite,
                    )
                  : p,
            )
            .toList();
      });
    } finally {
      if (mounted) setState(() => _togglingFavorite = false);
    }
  }

  List<WorkoutProgramItem> _filteredItems() {
    final search = _searchController.text.trim().toLowerCase();
    return _programs.where((item) {
      final itemCategory = item.category.trim().isEmpty ? 'Workout' : item.category;
      final categoryOk = _selectedCategory == 'Tous' || itemCategory == _selectedCategory;
      final searchOk = search.isEmpty ||
          item.title.toLowerCase().contains(search) ||
          itemCategory.toLowerCase().contains(search);
      return categoryOk && searchOk;
    }).toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.searchController,
    required this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
      color: const Color.fromRGBO(248, 247, 246, 0.92),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tous les programmes',
                  style: TextStyle(
                    color: Color(0xFF2D241D),
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.06),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.tune, color: Color(0xFFEE8C2B)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEE8C2B),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(238, 140, 43, 0.34),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProgramCustomizationStep1Screen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.06),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                hintText: 'Rechercher un programme...',
                prefixIcon: Icon(Icons.search, color: Color(0xFFEE8C2B)),
                hintStyle: TextStyle(color: Color(0xFFA8A29E), fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final selected = selectedCategory == cat;
                return GestureDetector(
                  onTap: () => onCategorySelected(cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFEE8C2B) : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? const Color(0xFFEE8C2B) : const Color(0xFFF1F5F9),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? Colors.white : const Color(0xFF57534E),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: categories.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.item,
    required this.isFavorite,
    required this.onOpen,
    required this.onFavoriteToggle,
    required this.onPlay,
  });

  final WorkoutProgramItem item;
  final bool isFavorite;
  final VoidCallback onOpen;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 224,
      child: GestureDetector(
        onTap: onOpen,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(item.imageUrl, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0.12),
                      Color.fromRGBO(0, 0, 0, 0.35),
                      Color.fromRGBO(0, 0, 0, 0.9),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: onFavoriteToggle,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: Colors.white,
                    ),
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
                    Row(
                      children: [
                        _Pill(text: item.category, primary: true),
                        const SizedBox(width: 6),
                        _Pill(text: item.tag2, primary: false),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Color(0xFFEE8C2B),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.duration,
                                    style: const TextStyle(
                                      color: Color.fromRGBO(255, 255, 255, 0.82),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.bar_chart,
                                    color: Color(0xFFEE8C2B),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.level,
                                    style: const TextStyle(
                                      color: Color.fromRGBO(255, 255, 255, 0.82),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onPlay,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEE8C2B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.primary});

  final String text;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primary ? const Color(0xFFEE8C2B) : const Color.fromRGBO(255, 255, 255, 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BottomNavSessions extends StatelessWidget {
  const _BottomNavSessions({required this.onTap});

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
