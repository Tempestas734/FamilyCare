import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/workout_program_service.dart';
import 'profile_screen.dart';
import 'sessions_screen.dart';
import 'workout_home_screen.dart';

class ProgramCustomizationStep2Screen extends StatefulWidget {
  const ProgramCustomizationStep2Screen({
    super.key,
    required this.sessionName,
    required this.coverTitle,
    required this.coverImageUrl,
    this.initialCategories,
    this.initialCategory,
    this.initialDifficulty = 'Tous',
  });

  final String sessionName;
  final String coverTitle;
  final String coverImageUrl;
  final List<String>? initialCategories;
  final String? initialCategory;
  final String initialDifficulty;

  @override
  State<ProgramCustomizationStep2Screen> createState() =>
      _ProgramCustomizationStep2ScreenState();
}

class _ProgramCustomizationStep2ScreenState
    extends State<ProgramCustomizationStep2Screen> {
  final TextEditingController _searchController = TextEditingController();
  final WorkoutProgramService _service =
      WorkoutProgramService(Supabase.instance.client);

  final Set<String> _selectedExercises = <String>{};
  final Set<String> _selectedBodyTargets = <String>{};
  bool _loading = true;
  bool _saving = false;
  List<ExerciseLibraryItem> _items = const [];
  String _bodyView = 'upper';

  static const List<String> _upperTargets = <String>[
    'neck',
    'shoulders',
    'chest',
    'biceps',
    'triceps',
    'forearms',
    'abdominals',
    'traps',
    'lats',
    'middle back',
    'lower back',
  ];
  static const List<String> _lowerTargets = <String>[
    'abductors',
    'adductors',
    'glutes',
    'hamstrings',
    'quadriceps',
    'calves',
  ];

  static const List<_ExerciseLibraryItem> _fallbackItems = <_ExerciseLibraryItem>[
    _ExerciseLibraryItem(
      id: 'burpees',
      name: 'Burpees',
      category: 'Cardio',
      subtitle: 'Cardio  |  Haute intensite',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB4Pqqudq5CVlppU10SLqqm7n3MLw8Bv3QjBAS3yvIaR3eyETAul27vX82X-P_gFXDQpuZr38Qkhy-ft9raqm3xLLtSogaC0dD9hsNWkAbe_FSEwA8h79eV1yLeyvbfdGL0jKFcXhCCvj7QolUZfA7V4qJfL6gTlV54HUoqeqiTclzwFrHCdE2Nw3Pl3hrr6Tf3D4Lcfq52F-8O8Z_d3ksbXFfmM1OgGZ_XqWvs9OCQO-Bv2DG0ZK6frn6dyBoO87OXxkZ6zO3BuTgU',
    ),
    _ExerciseLibraryItem(
      id: 'fentes',
      name: 'Fentes alternees',
      category: 'Jambes',
      subtitle: 'Jambes  |  Mobilite',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDDFWZ5XqVR8FRNDUw0aLsoIYzVgUsllge-n6PNym6gdvrIG7G84itVrJ7DF6bSBhHHgwAGaHV7Q4yxoBdNqmHnaK-taMIHePMfojzW9iEDjaHq0p4cYtVU6_CNBqiJc1k8jPxVGtJdxK0e47SKYaCE3zl-9TLd8PpX_WKUOK1NYd0ps4D2Yn0u7WpOVO5FMo0zD-hbFGfmoefKJDXKxLWXd4UA1mImDJLRzH04lSegM8s4v0fSPa--lZ9fWwOcMx3b0ZV3cbQFy_o8',
    ),
    _ExerciseLibraryItem(
      id: 'mountain_climbers',
      name: 'Mountain Climbers',
      category: 'Abdos',
      subtitle: 'Abdos  |  Cardio',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuChHMswCQbFgNxQ2JcnnwiABVnlOr470-AaySk6gYAobS0wa_SBH4WLuW4wKiMInqayxCKecW2LHHXDF0AV_TYDOD3cc8Oc-zkP8RIgMlLK7CoMVz63NO4-mQXaYUIu4hEwc0NPKcnabIdsogFmfcGF2RNJBezLyLj9TsNseQlKM_VYhEpdWO5QZ2AKhKELIydkYvnH563hQGLVEHLu-E_ena9eVfRs465hDOK4oDHxLzYUer-jFm3-uen6TeOeFmoWjgnLeYrl_NEm',
    ),
    _ExerciseLibraryItem(
      id: 'dips_chaise',
      name: 'Dips sur chaise',
      category: 'Bras',
      subtitle: 'Bras  |  Triceps',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA8Cc_2rM9EOTh8V5o76e1Vt-x9fCuSK1zgJPbx6yrF0ZHLe2vPK1AOlujf4PUsH23C6jp2CYVc4J3iUUGHRERGGbJClgPt5QnB_wtbIr4qjnUdf36TOGsxBQYT9uOmvaSN4eOZ5MVuNNraOuH-8b-mOdPETbX5b_3PkJSm4yRjPWARSnkQR6UIgKQ82LyTuo_DzZGBYgtxA8AqQ5NeZwdcVvXRHMPQZeSFAleTZy1dmoxt4stG95Jn8Vt1qFWgvOZc2wN2wZ-lNkj-',
    ),
    _ExerciseLibraryItem(
      id: 'pompes',
      name: 'Pompes classiques',
      category: 'Bras',
      subtitle: 'Bras  |  Pectoraux',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDDFKq-3E-F4dYK-NaRI1WeZ6BalaNhG4nEalM74GJIHOFpw3utzOj-hv-MSqP4XpOTIAXTAJ_G1r0RFslnSTZIHsLdOrgkJAC6p_uONC1A4dmlFOLHY_nhARGaDvgkF5U0QK9rqta72ik8SO-M_OVVycVuSpAJY0fot9sMp62LWnhHQqd5qO7xJ118dWctqBZphmaUJi7FSrPzYxRA19BBZlUEjxNlMXParhZ-kKUm52fKht-mkvH6ZIz15LjHcowc_iVPIFmDzGKZ',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _items = _defaultItems();
    _loading = false;
    _loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      body: Stack(
        children: [
          Column(
            children: [
              _Step2Header(onBack: () => Navigator.of(context).pop()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 170),
                  children: [
                    const Text(
                      "Bibliotheque d'exercices",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Items affiches: ${filtered.length}  |  Source: ${_items.length}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un exercice...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                        suffixIcon: IconButton(
                          tooltip: 'Filtrer body part',
                          onPressed: _showBodyPartFilter,
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.filter_alt_outlined, color: Color(0xFFF48C25)),
                              if (_selectedBodyTargets.isNotEmpty)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF48C25),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_selectedBodyTargets.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._selectedBodyTargets.map((e) => _filterPill(e)),
                            GestureDetector(
                              onTap: () => setState(() => _selectedBodyTargets.clear()),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Text(
                                  'Effacer',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                          child: Text(
                            'Aucun exercice trouve. Change le filtre ou la recherche.',
                          ),
                        ),
                      )
                    else
                      ...filtered.map(
                        (item) {
                        final isAdded = _selectedExercises.contains(item.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => _showExerciseDetails(item),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isAdded
                                      ? const Color.fromRGBO(244, 140, 37, 0.45)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _ExerciseImage(imageUrl: item.imageUrl),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.subtitle,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (isAdded) {
                                          _selectedExercises.remove(item.id);
                                        } else {
                                          _selectedExercises.add(item.id);
                                        }
                                      });
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: isAdded
                                          ? const Color(0xFFF48C25)
                                          : const Color.fromRGBO(244, 140, 37, 0.12),
                                    ),
                                    icon: Icon(
                                      isAdded ? Icons.check : Icons.add,
                                      color: isAdded ? Colors.white : const Color(0xFFF48C25),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 98,
            child: ElevatedButton.icon(
              onPressed: _selectedExercises.isEmpty || _saving
                  ? null
                  : _saveProgram,
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Creation...' : 'Terminer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF48C25),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _Step2BottomNav(
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
          }
        },
      ),
    );
  }

  Future<void> _loadExercises() async {
    try {
      final rows = await _service
          .loadExerciseLibraryPreferApi()
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      final fallback = _defaultItems();
      setState(() {
        _items = rows.isNotEmpty ? rows : (_items.isNotEmpty ? _items : fallback);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_items.isEmpty) {
          _items = _defaultItems();
        }
        _loading = false;
      });
    }
  }

  Future<void> _saveProgram() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final sessionName =
          widget.sessionName.trim().isEmpty ? 'Ma seance' : widget.sessionName.trim();
      final selectedItems = _items
          .where((item) => _selectedExercises.contains(item.id))
          .toList();
      await _service.createProgramWithExerciseItems(
        title: sessionName,
        coverImageUrl: widget.coverImageUrl,
        focus: widget.coverTitle,
        items: selectedItems,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$sessionName cree avec ${_selectedExercises.length} exercices.',
          ),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const SessionsScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur creation programme: $e')),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _showExerciseDetails(ExerciseLibraryItem item) async {
    var detailsItem = item;
    var primaryMuscles = item.primaryMuscles ?? const <String>[];
    var secondaryMuscles = item.secondaryMuscles ?? const <String>[];
    if ((item.instructions ?? const <String>[]).isEmpty) {
      final fetched = await _service.loadExerciseInstructions(
        id: item.id,
        name: item.name,
      );
      if (primaryMuscles.isEmpty && secondaryMuscles.isEmpty) {
        final muscles = await _service.loadExerciseMuscles(
          id: item.id,
          name: item.name,
        );
        primaryMuscles = muscles['primary'] ?? const <String>[];
        secondaryMuscles = muscles['secondary'] ?? const <String>[];
      }
      detailsItem = ExerciseLibraryItem(
        id: item.id,
        name: item.name,
        category: item.category,
        difficulty: item.difficulty,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        instructions: fetched,
        muscleGroup: item.muscleGroup,
        primaryMuscles: primaryMuscles,
        secondaryMuscles: secondaryMuscles,
        equipment: item.equipment,
        met: item.met,
        externalId: item.externalId,
        externalSource: item.externalSource,
      );
    } else if (primaryMuscles.isEmpty && secondaryMuscles.isEmpty) {
      final muscles = await _service.loadExerciseMuscles(
        id: item.id,
        name: item.name,
      );
      detailsItem = ExerciseLibraryItem(
        id: item.id,
        name: item.name,
        category: item.category,
        difficulty: item.difficulty,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        instructions: item.instructions,
        muscleGroup: item.muscleGroup,
        primaryMuscles: muscles['primary'] ?? const <String>[],
        secondaryMuscles: muscles['secondary'] ?? const <String>[],
        equipment: item.equipment,
        met: item.met,
        externalId: item.externalId,
        externalSource: item.externalSource,
      );
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExerciseDetailsSheet(
        item: detailsItem,
        isAdded: _selectedExercises.contains(item.id),
        onToggleRoutine: () {
          setState(() {
            if (_selectedExercises.contains(item.id)) {
              _selectedExercises.remove(item.id);
            } else {
              _selectedExercises.add(item.id);
            }
          });
        },
      ),
    );
  }

  List<ExerciseLibraryItem> _filteredItems() {
    final source = _items.isNotEmpty ? _items : _defaultItems();
    final query = _searchController.text.trim().toLowerCase();
    final filtered = source.where((item) {
      final searchOk = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      final muscle = (item.muscleGroup ?? '').toLowerCase();
      final bodyTargetOk = _selectedBodyTargets.isEmpty ||
          _selectedBodyTargets.any((t) => muscle.contains(t.toLowerCase()));
      return searchOk && bodyTargetOk;
    }).toList();
    if (filtered.isEmpty && source.isNotEmpty) {
      return source;
    }
    return filtered;
  }

  Future<void> _showBodyPartFilter() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setLocal) {
              final targets = _bodyView == 'upper' ? _upperTargets : _lowerTargets;
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Filtre body part',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _bodyToggle(
                              label: 'Upper body',
                              selected: _bodyView == 'upper',
                              onTap: () => setLocal(() => _bodyView = 'upper'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _bodyToggle(
                              label: 'Lower body',
                              selected: _bodyView == 'lower',
                              onTap: () => setLocal(() => _bodyView = 'lower'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: targets.map((t) => _targetChip(t, setLocal)).toList(),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF48C25),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Appliquer'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() {});
  }

  Widget _targetChip(String target, void Function(void Function()) setLocal) {
    final selected = _selectedBodyTargets.contains(target);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedBodyTargets.remove(target);
          } else {
            _selectedBodyTargets.add(target);
          }
        });
        setLocal(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color.fromRGBO(244, 140, 37, 0.14)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFFF48C25)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          target,
          style: TextStyle(
            color: selected
                ? const Color(0xFFF48C25)
                : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _bodyToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF48C25) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFF48C25) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _filterPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(244, 140, 37, 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF48C25)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFF48C25),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<ExerciseLibraryItem> _defaultItems() {
    return _fallbackItems
        .map(
          (e) => ExerciseLibraryItem(
            id: e.id,
            name: e.name,
            category: e.category,
            difficulty: '',
            subtitle: e.subtitle,
            imageUrl: e.imageUrl,
          ),
        )
        .toList();
  }
}

class _Step2Header extends StatelessWidget {
  const _Step2Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 46, 10, 10),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(248, 247, 245, 0.92),
        border: Border(bottom: BorderSide(color: Color.fromRGBO(244, 140, 37, 0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left, color: Color(0xFFF48C25)),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'ETAPE 2 SUR 2',
                  style: TextStyle(
                    color: Color(0xFFF48C25),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ajouter des exercices',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _Step2BottomNav extends StatelessWidget {
  const _Step2BottomNav({required this.onTap});

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.92),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(icon: Icons.dashboard, label: 'Dashboard', active: false, onTap: () => onTap(0)),
          _NavItem(icon: Icons.fitness_center, label: 'Seances', active: true, onTap: () => onTap(1)),
          _NavItem(icon: Icons.insights, label: 'Progres', active: false, onTap: () => onTap(2)),
          _NavItem(icon: Icons.person, label: 'Profil', active: false, onTap: () => onTap(3)),
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
    final color = active ? const Color(0xFFF48C25) : const Color(0xFF94A3B8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseLibraryItem {
  const _ExerciseLibraryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.subtitle,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String category;
  final String subtitle;
  final String imageUrl;
}

class _ExerciseImage extends StatelessWidget {
  const _ExerciseImage({
    required this.imageUrl,
    this.frameIndex = 0,
    this.width = 64,
    this.height = 64,
  });

  final String imageUrl;
  final int frameIndex;
  final double width;
  final double height;
  static const String _githubImageBase =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

  @override
  Widget build(BuildContext context) {
    final value = _forceFrameJpg(imageUrl.trim(), frameIndex);
    if (value.isEmpty) {
      return _placeholder();
    }
    final remoteFromPath = _remoteFrameJpgFromAnyPath(value, frameIndex);
    if (kIsWeb && remoteFromPath != null) {
      return Image.network(
        remoteFromPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    final canonicalAsset = _canonicalExerciseAsset(value, frameIndex);
    if (canonicalAsset != null) {
      return Image.asset(
        canonicalAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    final assetPath = _toAssetPath(value);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          final alt = _fallbackAssetFromAnyPath(value, frameIndex);
          if (alt != null && alt != assetPath) {
            return Image.asset(
              alt,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            );
          }
          return _placeholder();
        },
      );
    }
    if (!kIsWeb && _looksLikeLocalPath(value)) {
      final filePath = _toFilePath(value);
      return Image.file(
        File(filePath),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          final alt = _fallbackAssetFromAnyPath(value, frameIndex);
          if (alt != null) {
            return Image.asset(
              alt,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            );
          }
          return _placeholder();
        },
      );
    }
    return Image.network(
      value,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        final alt = _fallbackAssetFromAnyPath(value, frameIndex);
        if (alt != null) {
          return Image.asset(
            alt,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          );
        }
        return _placeholder();
      },
    );
  }

  bool _looksLikeLocalPath(String value) {
    final normalized = value.replaceAll('\\', '/');
    final isWindowsAbsolute = RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
    final isUnixAbsolute = normalized.startsWith('/');
    final isFileUri = normalized.startsWith('file://');
    return isWindowsAbsolute || isUnixAbsolute || isFileUri;
  }

  String _toFilePath(String value) {
    if (value.startsWith('file://')) {
      return Uri.parse(value).toFilePath();
    }
    return value;
  }

  String? _toAssetPath(String value) {
    final normalized = value.replaceAll('\\', '/');
    const marker = '/assets/';
    final idx = normalized.toLowerCase().indexOf(marker);
    if (idx >= 0) {
      return normalized.substring(idx + 1);
    }
    if (normalized.startsWith('assets/')) {
      return normalized;
    }
    return null;
  }

  String _forceFrameJpg(String value, int frame) {
    final target = frame == 0 ? '0.jpg' : '1.jpg';
    final lower = value.toLowerCase();
    if (lower.endsWith('/0.jpg') || lower.endsWith('/1.jpg')) {
      return '${value.substring(0, value.length - 5)}$target';
    }
    if (lower.endsWith('\\0.jpg') || lower.endsWith('\\1.jpg')) {
      return '${value.substring(0, value.length - 5)}$target';
    }
    return value;
  }

  String? _fallbackAssetFromAnyPath(String value, int frame) {
    final normalized = value.replaceAll('\\', '/');
    final marker = '/exercises/';
    final idx = normalized.toLowerCase().lastIndexOf(marker);
    if (idx < 0) return null;
    final tail = normalized.substring(idx + marker.length);
    final slash = tail.indexOf('/');
    if (slash <= 0) return null;
    final exerciseDir = tail.substring(0, slash);
    return 'assets/free-exercise-db-main/exercises/$exerciseDir/${frame == 0 ? '0' : '1'}.jpg';
  }

  String? _canonicalExerciseAsset(String value, int frame) {
    final normalized = value.replaceAll('\\', '/');
    const marker = '/exercises/';
    final idx = normalized.toLowerCase().lastIndexOf(marker);
    if (idx < 0) return null;
    final tail = normalized.substring(idx + marker.length);
    final slash = tail.indexOf('/');
    if (slash <= 0) return null;
    final exerciseDir = tail.substring(0, slash);
    return 'assets/free-exercise-db-main/exercises/$exerciseDir/${frame == 0 ? '0' : '1'}.jpg';
  }

  String? _remoteFrameJpgFromAnyPath(String value, int frame) {
    final normalized = value.replaceAll('\\', '/');
    final marker = '/exercises/';
    final idx = normalized.toLowerCase().lastIndexOf(marker);
    if (idx < 0) return null;
    final tail = normalized.substring(idx + marker.length);
    final slash = tail.indexOf('/');
    if (slash <= 0) return null;
    final exerciseDir = tail.substring(0, slash);
    return '$_githubImageBase$exerciseDir/${frame == 0 ? '0' : '1'}.jpg';
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fitness_center,
        size: 26,
        color: Color(0xFF94A3B8),
      ),
    );
  }
}

class _ExerciseDetailsSheet extends StatefulWidget {
  const _ExerciseDetailsSheet({
    required this.item,
    required this.isAdded,
    required this.onToggleRoutine,
  });

  final ExerciseLibraryItem item;
  final bool isAdded;
  final VoidCallback onToggleRoutine;

  @override
  State<_ExerciseDetailsSheet> createState() => _ExerciseDetailsSheetState();
}

class _ExerciseDetailsSheetState extends State<_ExerciseDetailsSheet> {
  Timer? _timer;
  int _frameIndex = 0;
  late bool _isAdded;
  static const double _detailImageHeight = 260;

  @override
  void initState() {
    super.initState();
    _isAdded = widget.isAdded;
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() => _frameIndex = _frameIndex == 0 ? 1 : 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final steps = item.instructions ?? const <String>[];
    final screenHeight = MediaQuery.of(context).size.height;
    final maxImageHeight = screenHeight * 0.30;
    final imageHeight =
        _detailImageHeight > maxImageHeight ? maxImageHeight : _detailImageHeight;
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.80,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 24, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFF48C25),
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(244, 140, 37, 0.35),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _ExerciseImage(
                      imageUrl: item.imageUrl,
                      frameIndex: _frameIndex,
                      width: double.infinity,
                      height: imageHeight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _frameIndex == 0 ? 'Photo 1/2' : 'Photo 2/2',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 150,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${item.category} | ${item.difficulty.trim().isEmpty ? 'Tous niveaux' : item.difficulty}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.subtitle,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              _musclesInfo(
                primary: item.primaryMuscles ?? const <String>[],
                secondary: item.secondaryMuscles ?? const <String>[],
              ),
              const SizedBox(height: 12),
              const Text(
                'Instructions',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: steps.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune instruction disponible',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: steps.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 14,
                          thickness: 1,
                          color: Color(0xFFE2E8F0),
                        ),
                        itemBuilder: (context, index) {
                          final text = steps[index];
                          return Text(
                            '${index + 1}. $text',
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onToggleRoutine();
                    setState(() => _isAdded = !_isAdded);
                  },
                  icon: Icon(_isAdded ? Icons.check : Icons.add),
                  label: Text(
                    _isAdded ? 'Ajoute a la routine' : ' Ajouter a la routine',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF48C25),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _musclesInfo({
    required List<String> primary,
    required List<String> secondary,
  }) {
    final allMuscles = <String>{
      ...primary.map((e) => e.trim()).where((e) => e.isNotEmpty),
      ...secondary.map((e) => e.trim()).where((e) => e.isNotEmpty),
    }.toList();
    allMuscles.sort();

    final musclesText = allMuscles.isEmpty ? '-' : allMuscles.join(', ');

    return Text(
      'Muscles: $musclesText',
      style: const TextStyle(
        color: Color(0xFF475569),
        fontSize: 13,
        height: 1.35,
      ),
    );
  }
}
