import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseLibraryItem {
  const ExerciseLibraryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.subtitle,
    required this.imageUrl,
    this.instructions,
    this.muscleGroup,
    this.primaryMuscles,
    this.secondaryMuscles,
    this.equipment,
    this.met,
    this.externalId,
    this.externalSource,
  });

  final String id;
  final String name;
  final String category;
  final String difficulty;
  final String subtitle;
  final String imageUrl;
  final List<String>? instructions;
  final String? muscleGroup;
  final List<String>? primaryMuscles;
  final List<String>? secondaryMuscles;
  final String? equipment;
  final double? met;
  final String? externalId;
  final String? externalSource;
}

class WorkoutProgramItem {
  const WorkoutProgramItem({
    required this.id,
    required this.title,
    required this.category,
    required this.tag2,
    required this.duration,
    required this.level,
    required this.imageUrl,
    required this.isFavorite,
  });

  final String id;
  final String title;
  final String category;
  final String tag2;
  final String duration;
  final String level;
  final String imageUrl;
  final bool isFavorite;
}

class WorkoutProgramService {
  WorkoutProgramService(this._client);

  final SupabaseClient _client;
  static const String _freeExerciseDbUrl = String.fromEnvironment(
    'FREE_EXERCISE_DB_URL',
    defaultValue:
        'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json',
  );
  static const String _freeExerciseDbLocalPath = String.fromEnvironment(
    'FREE_EXERCISE_DB_LOCAL_PATH',
    defaultValue:
        'D:/health_app/apps/workout_app/data/free-exercise-db-main/dist/exercises.json',
  );
  static const String _freeExerciseDbImageBase =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

  Future<List<ExerciseLibraryItem>> loadExerciseLibrary({
    String? search,
    String? category,
    String? difficulty,
  }) async {
    var query = _client
        .from('exercise_library')
        .select(
          'id, name, category, difficulty, equipment, primary_muscles, secondary_muscles, media_paths, instructions',
        )
        .eq('is_active', true);

    if (category != null && category.isNotEmpty && category.toLowerCase() != 'tous') {
      query = query.ilike('category', category);
    }
    if (difficulty != null && difficulty.isNotEmpty && difficulty.toLowerCase() != 'tous') {
      query = query.ilike('difficulty', difficulty);
    }
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('name', '%${search.trim()}%');
    }

    final rows = await query.order('name');
    return (rows as List<dynamic>)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .map((row) {
          final name = row['name']?.toString() ?? 'Exercice';
          final categoryText = row['category']?.toString() ?? 'General';
          final difficultyText = row['difficulty']?.toString() ?? '';
          final equipment = row['equipment']?.toString();
          final primaryMuscles = _asTextList(row['primary_muscles']);
          final secondaryMuscles = _asTextList(row['secondary_muscles']);
          final mediaPaths = _asTextList(row['media_paths']);
          final instructions = _asTextList(row['instructions']);
          final imageUrl = _resolveImageUrl(mediaPaths.isNotEmpty ? mediaPaths.first : null);
          final met = _estimateMet(
            category: categoryText,
            equipment: equipment ?? '',
            name: name,
          );
          return ExerciseLibraryItem(
            id: row['id']?.toString() ?? '',
            name: name,
            category: categoryText,
            difficulty: difficultyText,
            subtitle: difficultyText.isEmpty
                ? categoryText
                : '$categoryText  |  $difficultyText',
            imageUrl: imageUrl,
            instructions: instructions,
            muscleGroup: primaryMuscles.isEmpty ? null : primaryMuscles.first,
            primaryMuscles: primaryMuscles,
            secondaryMuscles: secondaryMuscles,
            equipment: equipment,
            met: met,
          );
        })
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<double> loadCurrentMemberWeightKg({double fallback = 70}) async {
    final user = _client.auth.currentUser;
    if (user == null) return fallback;

    final row = await _client
        .from('family_members')
        .select('weight_kg')
        .eq('auth_user_id', user.id)
        .limit(1)
        .maybeSingle();
    final weight = row?['weight_kg'];
    if (weight is num && weight > 0) return weight.toDouble();
    return fallback;
  }

  Future<List<ExerciseLibraryItem>> loadExerciseLibraryPreferApi({
    String? search,
    String? category,
    String? difficulty,
  }) async {
    // DB-only mode: do not seed/insert from app runtime.
    return loadExerciseLibrary(
      search: search,
      category: category,
      difficulty: difficulty,
    );
  }

  Future<void> createProgramWithExercises({
    required String title,
    required String coverImageUrl,
    String? focus,
    required List<String> exerciseIds,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecte');

    final member = await _client
        .from('family_members')
        .select('id, family_id')
        .eq('auth_user_id', user.id)
        .limit(1)
        .maybeSingle();

    final memberId = member?['id']?.toString();
    final familyId = member?['family_id']?.toString();
    if (memberId == null || familyId == null) {
      throw Exception('Membre famille introuvable');
    }

    final programRow = await _client
        .from('workout_programs')
        .insert({
          'family_id': familyId,
          'created_by_member_id': memberId,
          'title': title.trim(),
          'cover_image_url': coverImageUrl,
          'focus': focus,
        })
        .select('id')
        .single();

    final programId = programRow['id']?.toString();
    if (programId == null || programId.isEmpty) {
      throw Exception('Echec creation programme');
    }

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < exerciseIds.length; i++) {
      rows.add({
        'program_id': programId,
        'exercise_id': exerciseIds[i],
        'position': i + 1,
      });
    }
    if (rows.isNotEmpty) {
      await _client.from('workout_program_exercises').insert(rows);
    }
  }

  Future<void> createProgramWithExerciseItems({
    required String title,
    required String coverImageUrl,
    String? focus,
    required List<ExerciseLibraryItem> items,
  }) async {
    final dbExerciseIds = <String>[];
    for (final item in items) {
      if (_isUuid(item.id) && (item.externalSource == null || item.externalSource!.isEmpty)) {
        dbExerciseIds.add(item.id);
      } else {
        final id = await _ensureExerciseExists(item);
        dbExerciseIds.add(id);
      }
    }
    await createProgramWithExercises(
      title: title,
      coverImageUrl: coverImageUrl,
      focus: focus,
      exerciseIds: dbExerciseIds,
    );
  }

  Future<List<WorkoutProgramItem>> loadProgramsForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];

    final member = await _client
        .from('family_members')
        .select('id, family_id')
        .eq('auth_user_id', user.id)
        .limit(1)
        .maybeSingle();
    final memberId = member?['id']?.toString();
    final familyId = member?['family_id']?.toString();
    if (memberId == null || familyId == null) return const [];

    final programsRaw = await _client
        .from('workout_programs')
        .select('id, title, cover_image_url, focus')
        .eq('family_id', familyId)
        .order('created_at', ascending: false);
    final programsRows = List<dynamic>.from(programsRaw);

    final programIds = programsRows
        .whereType<Map>()
        .map((row) => row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (programIds.isEmpty) return const [];

    final exerciseRaw = await _client
        .from('workout_program_exercises')
        .select('program_id, exercise_id')
        .inFilter('program_id', programIds);
    final exerciseRows = List<dynamic>.from(exerciseRaw);

    final favoriteRaw = await _client
        .from('workout_program_favorites')
        .select('program_id')
        .eq('member_id', memberId);
    final favoriteRows = List<dynamic>.from(favoriteRaw);

    final exerciseCountByProgram = <String, int>{};
    for (final row in exerciseRows.whereType<Map>()) {
      final p = row['program_id']?.toString();
      if (p == null || p.isEmpty) continue;
      exerciseCountByProgram[p] = (exerciseCountByProgram[p] ?? 0) + 1;
    }

    final favoriteProgramIds = favoriteRows
        .whereType<Map>()
        .map((row) => row['program_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    return programsRows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .map((row) {
          final id = row['id']?.toString() ?? '';
          final focus = row['focus']?.toString().trim();
          final category = (focus == null || focus.isEmpty) ? 'Workout' : focus;
          final exerciseCount = exerciseCountByProgram[id] ?? 0;
          final durationMinutes = (exerciseCount == 0) ? 20 : (exerciseCount * 4);
          return WorkoutProgramItem(
            id: id,
            title: row['title']?.toString() ?? 'Programme',
            category: category,
            tag2: 'Personnalise',
            duration: '$durationMinutes min',
            level: 'Tous niveaux',
            imageUrl: row['cover_image_url']?.toString() ?? '',
            isFavorite: favoriteProgramIds.contains(id),
          );
        })
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<void> setFavorite({
    required String programId,
    required bool favorite,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecte');

    final member = await _client
        .from('family_members')
        .select('id')
        .eq('auth_user_id', user.id)
        .limit(1)
        .maybeSingle();
    final memberId = member?['id']?.toString();
    if (memberId == null || memberId.isEmpty) {
      throw Exception('Membre famille introuvable');
    }

    if (favorite) {
      await _client.from('workout_program_favorites').insert({
        'member_id': memberId,
        'program_id': programId,
      });
    } else {
      await _client
          .from('workout_program_favorites')
          .delete()
          .eq('member_id', memberId)
          .eq('program_id', programId);
    }
  }

  Future<List<String>> loadExerciseInstructions({
    required String id,
    required String name,
  }) async {
    try {
      if (id.isNotEmpty) {
        final byId = await _client
            .from('exercise_library')
            .select('instructions')
            .eq('id', id)
            .limit(1)
            .maybeSingle();
        final steps = _asTextList(byId?['instructions']);
        if (steps.isNotEmpty) return steps;
      }
    } catch (_) {
      // Fallback to name lookup below.
    }

    try {
      final byName = await _client
          .from('exercise_library')
          .select('instructions')
          .ilike('name', name.trim())
          .limit(1)
          .maybeSingle();
      return _asTextList(byName?['instructions']);
    } catch (_) {
      return const <String>[];
    }
  }

  Future<Map<String, List<String>>> loadExerciseMuscles({
    required String id,
    required String name,
  }) async {
    try {
      if (id.isNotEmpty) {
        final byId = await _client
            .from('exercise_library')
            .select('primary_muscles, secondary_muscles')
            .eq('id', id)
            .limit(1)
            .maybeSingle();
        final primary = _asTextList(byId?['primary_muscles']);
        final secondary = _asTextList(byId?['secondary_muscles']);
        if (primary.isNotEmpty || secondary.isNotEmpty) {
          return <String, List<String>>{
            'primary': primary,
            'secondary': secondary,
          };
        }
      }
    } catch (_) {
      // Fallback to name lookup below.
    }

    try {
      final byName = await _client
          .from('exercise_library')
          .select('primary_muscles, secondary_muscles')
          .ilike('name', name.trim())
          .limit(1)
          .maybeSingle();
      return <String, List<String>>{
        'primary': _asTextList(byName?['primary_muscles']),
        'secondary': _asTextList(byName?['secondary_muscles']),
      };
    } catch (_) {
      return const <String, List<String>>{
        'primary': <String>[],
        'secondary': <String>[],
      };
    }
  }

  Future<List<ExerciseLibraryItem>> _loadExerciseDbExercises() async {
    final jsonContent = await _readFreeExerciseDbJson();
    final decoded = jsonDecode(jsonContent);
    final rows = decoded is List ? decoded : const [];

    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .map((row) {
          final name = row['name']?.toString().trim();
          if (name == null || name.isEmpty) return null;
          final sourceCategory = row['category']?.toString().trim() ?? '';
          final level = row['level']?.toString().trim() ?? '';
          final equipment = row['equipment']?.toString().trim() ?? '';
          final externalId = row['id']?.toString().trim() ?? '';
          final primary = (row['primaryMuscles'] is List)
              ? (row['primaryMuscles'] as List)
                  .map((m) => m?.toString().trim() ?? '')
                  .where((m) => m.isNotEmpty)
                  .toList()
              : const <String>[];
          final secondary = (row['secondaryMuscles'] is List)
              ? (row['secondaryMuscles'] as List)
                  .map((m) => m?.toString().trim() ?? '')
                  .where((m) => m.isNotEmpty)
                  .toList()
              : const <String>[];
          final imagePath = (row['images'] is List && (row['images'] as List).isNotEmpty)
              ? (row['images'] as List).first.toString()
              : '';
          final imageUrl = imagePath.isEmpty ? '' : '$_freeExerciseDbImageBase$imagePath';

          final uiCategory = _mapExerciseCategory(
            sourceCategory: sourceCategory,
            primaryMuscles: primary,
            exerciseName: name,
          );
          final met = _estimateMet(
            category: uiCategory,
            equipment: equipment,
            name: name,
          );
          final subtitleBits = <String>[
            if (sourceCategory.isNotEmpty) sourceCategory,
            if (level.isNotEmpty) level,
            if (equipment.isNotEmpty) equipment,
          ];

          return ExerciseLibraryItem(
            id: externalId.isEmpty ? name : 'exdb_$externalId',
            externalId: externalId.isEmpty ? null : externalId,
            externalSource: 'free_exercise_db',
            name: _capitalizeWords(name),
            category: uiCategory,
            difficulty: level,
            subtitle: subtitleBits.isEmpty ? uiCategory : subtitleBits.join('  |  '),
            imageUrl: imageUrl,
            muscleGroup: primary.isEmpty ? null : primary.first,
            primaryMuscles: primary,
            secondaryMuscles: secondary,
            equipment: equipment,
            met: met,
          );
        })
        .whereType<ExerciseLibraryItem>()
        .toList();
  }

  Future<String> _readFreeExerciseDbJson() async {
    if (!kIsWeb) {
      try {
        final file = File(_freeExerciseDbLocalPath);
        if (await file.exists()) {
          debugPrint('free-exercise-db local file used: $_freeExerciseDbLocalPath');
          return await file.readAsString();
        }
      } catch (e) {
        debugPrint('free-exercise-db local read failed: $e');
      }
    }

    final uri = _buildExerciseDbListUri();
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('free-exercise-db HTTP ${response.statusCode}');
    }
    debugPrint('free-exercise-db remote file used: $uri');
    return response.body;
  }

  Uri _buildExerciseDbListUri() {
    final base = _freeExerciseDbUrl.trim();
    final parsed = Uri.tryParse(base);
    if (parsed == null || parsed.scheme.isEmpty || parsed.host.isEmpty) {
      return Uri.parse(
        'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json',
      );
    }
    return parsed;
  }

  Future<String> _ensureExerciseExists(ExerciseLibraryItem item) async {
    if (item.externalSource != null && item.externalId != null) {
      final existing = await _client
          .from('exercise_library')
          .select('id')
          .eq('external_source', item.externalSource!)
          .eq('external_id', item.externalId!)
          .limit(1)
          .maybeSingle();
      final existingId = existing?['id']?.toString();
      if (existingId != null && existingId.isNotEmpty) return existingId;
    }

    final inserted = await _client
        .from('exercise_library')
        .insert({
          'name': item.name,
          'category': item.category,
          'difficulty': 'API',
          'force': null,
          'mechanic': null,
          'equipment': item.equipment,
          'primary_muscles': item.muscleGroup == null ? null : [item.muscleGroup],
          'secondary_muscles': null,
          'instructions': null,
          'media_paths': item.imageUrl.trim().isEmpty ? <String>[] : [item.imageUrl],
          'external_source': item.externalSource,
          'external_id': item.externalId,
          'is_active': true,
        })
        .select('id')
        .single();
    final id = inserted['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Echec insertion exercice');
    }
    return id;
  }

  Future<void> _upsertExercisesFromApi(List<ExerciseLibraryItem> items) async {
    final rows = items
        .where((e) => (e.externalSource ?? '').isNotEmpty && (e.externalId ?? '').isNotEmpty)
        .map(
          (e) => {
            'name': e.name,
            'category': e.category,
            'difficulty': 'API',
            'force': null,
            'mechanic': null,
            'equipment': e.equipment,
            'primary_muscles': e.muscleGroup == null ? null : [e.muscleGroup],
            'secondary_muscles': null,
            'instructions': null,
            'media_paths': e.imageUrl.trim().isEmpty ? <String>[] : [e.imageUrl],
            'external_source': e.externalSource,
            'external_id': e.externalId,
            'is_active': true,
          },
        )
        .toList();
    if (rows.isEmpty) return;

    try {
      await _client
          .from('exercise_library')
          .upsert(rows, onConflict: 'external_source,external_id');
    } catch (_) {
      await _client.from('exercise_library').insert(rows);
    }
  }

  Future<void> _seedBuiltInExercises() async {
    final rows = <Map<String, dynamic>>[
      {
        'name': 'Burpees',
        'category': 'Cardio',
        'difficulty': 'Intermediaire',
        'equipment': 'body only',
        'primary_muscles': <String>['quadriceps'],
        'secondary_muscles': null,
        'instructions': null,
        'media_paths': <String>[
          'https://lh3.googleusercontent.com/aida-public/AB6AXuB4Pqqudq5CVlppU10SLqqm7n3MLw8Bv3QjBAS3yvIaR3eyETAul27vX82X-P_gFXDQpuZr38Qkhy-ft9raqm3xLLtSogaC0dD9hsNWkAbe_FSEwA8h79eV1yLeyvbfdGL0jKFcXhCCvj7QolUZfA7V4qJfL6gTlV54HUoqeqiTclzwFrHCdE2Nw3Pl3hrr6Tf3D4Lcfq52F-8O8Z_d3ksbXFfmM1OgGZ_XqWvs9OCQO-Bv2DG0ZK6frn6dyBoO87OXxkZ6zO3BuTgU',
        ],
        'is_active': true,
      },
      {
        'name': 'Fentes alternees',
        'category': 'Jambes',
        'difficulty': 'Debutant',
        'equipment': 'body only',
        'primary_muscles': <String>['quadriceps'],
        'secondary_muscles': null,
        'instructions': null,
        'media_paths': <String>[
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDDFWZ5XqVR8FRNDUw0aLsoIYzVgUsllge-n6PNym6gdvrIG7G84itVrJ7DF6bSBhHHgwAGaHV7Q4yxoBdNqmHnaK-taMIHePMfojzW9iEDjaHq0p4cYtVU6_CNBqiJc1k8jPxVGtJdxK0e47SKYaCE3zl-9TLd8PpX_WKUOK1NYd0ps4D2Yn0u7WpOVO5FMo0zD-hbFGfmoefKJDXKxLWXd4UA1mImDJLRzH04lSegM8s4v0fSPa--lZ9fWwOcMx3b0ZV3cbQFy_o8',
        ],
        'is_active': true,
      },
      {
        'name': 'Mountain Climbers',
        'category': 'Abdos',
        'difficulty': 'Intermediaire',
        'equipment': 'body only',
        'primary_muscles': <String>['abdominals'],
        'secondary_muscles': null,
        'instructions': null,
        'media_paths': <String>[
          'https://lh3.googleusercontent.com/aida-public/AB6AXuChHMswCQbFgNxQ2JcnnwiABVnlOr470-AaySk6gYAobS0wa_SBH4WLuW4wKiMInqayxCKecW2LHHXDF0AV_TYDOD3cc8Oc-zkP8RIgMlLK7CoMVz63NO4-mQXaYUIu4hEwc0NPKcnabIdsogFmfcGF2RNJBezLyLj9TsNseQlKM_VYhEpdWO5QZ2AKhKELIydkYvnH563hQGLVEHLu-E_ena9eVfRs465hDOK4oDHxLzYUer-jFm3-uen6TeOeFmoWjgnLeYrl_NEm',
        ],
        'is_active': true,
      },
      {
        'name': 'Dips sur chaise',
        'category': 'Bras',
        'difficulty': 'Debutant',
        'equipment': 'chair',
        'primary_muscles': <String>['triceps'],
        'secondary_muscles': null,
        'instructions': null,
        'media_paths': <String>[
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA8Cc_2rM9EOTh8V5o76e1Vt-x9fCuSK1zgJPbx6yrF0ZHLe2vPK1AOlujf4PUsH23C6jp2CYVc4J3iUUGHRERGGbJClgPt5QnB_wtbIr4qjnUdf36TOGsxBQYT9uOmvaSN4eOZ5MVuNNraOuH-8b-mOdPETbX5b_3PkJSm4yRjPWARSnkQR6UIgKQ82LyTuo_DzZGBYgtxA8AqQ5NeZwdcVvXRHMPQZeSFAleTZy1dmoxt4stG95Jn8Vt1qFWgvOZc2wN2wZ-lNkj-',
        ],
        'is_active': true,
      },
      {
        'name': 'Pompes classiques',
        'category': 'Bras',
        'difficulty': 'Intermediaire',
        'equipment': 'body only',
        'primary_muscles': <String>['chest'],
        'secondary_muscles': null,
        'instructions': null,
        'media_paths': <String>[
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDDFKq-3E-F4dYK-NaRI1WeZ6BalaNhG4nEalM74GJIHOFpw3utzOj-hv-MSqP4XpOTIAXTAJ_G1r0RFslnSTZIHsLdOrgkJAC6p_uONC1A4dmlFOLHY_nhARGaDvgkF5U0QK9rqta72ik8SO-M_OVVycVuSpAJY0fot9sMp62LWnhHQqd5qO7xJ118dWctqBZphmaUJi7FSrPzYxRA19BBZlUEjxNlMXParhZ-kKUm52fKht-mkvH6ZIz15LjHcowc_iVPIFmDzGKZ',
        ],
        'is_active': true,
      },
    ];

    try {
      await _client.from('exercise_library').insert(rows);
    } catch (_) {
      // Ignore duplicate conflicts; this is best-effort fallback seeding.
    }
  }

  bool _isUuid(String input) {
    final regex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return regex.hasMatch(input);
  }

  String _mapExerciseCategory({
    required String sourceCategory,
    required List<String> primaryMuscles,
    required String exerciseName,
  }) {
    final source = sourceCategory.toLowerCase();
    final primary = primaryMuscles.map((m) => m.toLowerCase()).join(' ');
    final name = exerciseName.toLowerCase();
    if (primary.contains('abdom') || primary.contains('oblique')) {
      return 'Abdos';
    }
    if (primary.contains('quadriceps') ||
        primary.contains('hamstring') ||
        primary.contains('glute') ||
        primary.contains('calves')) {
      return 'Jambes';
    }
    if (primary.contains('biceps') ||
        primary.contains('triceps') ||
        primary.contains('chest') ||
        primary.contains('shoulder') ||
        primary.contains('lats') ||
        primary.contains('forearms')) {
      return 'Bras';
    }
    if (source.contains('cardio') ||
        source.contains('plyometrics') ||
        name.contains('burpee') ||
        name.contains('jump') ||
        name.contains('mountain climber')) {
      return 'Cardio';
    }
    return 'Cardio';
  }

  double _estimateMet({
    required String category,
    required String equipment,
    required String name,
  }) {
    final cat = category.toLowerCase();
    final eq = equipment.toLowerCase();
    final n = name.toLowerCase();
    if (n.contains('burpee') || n.contains('hiit')) return 10.0;
    if (cat == 'cardio') return 8.0;
    if (cat == 'jambes') return 6.0;
    if (cat == 'bras') return 5.5;
    if (cat == 'abdos') return 5.0;
    if (eq.contains('kettlebell') || eq.contains('barbell')) return 6.0;
    return 5.0;
  }

  String _capitalizeWords(String input) {
    return input
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  List<String> _asTextList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  String _resolveImageUrl(String? mediaPath) {
    final value = mediaPath?.trim() ?? '';
    if (value.isEmpty) return '';
    if (_looksLikeLocalPath(value)) {
      return value;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '$_freeExerciseDbImageBase$value';
  }

  bool _looksLikeLocalPath(String value) {
    final normalized = value.replaceAll('\\', '/');
    final isWindowsAbsolute = RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
    final isUnixAbsolute = normalized.startsWith('/');
    final isFileUri = normalized.startsWith('file://');
    return isWindowsAbsolute || isUnixAbsolute || isFileUri;
  }

}

double estimateCaloriesKcal({
  required double met,
  required double weightKg,
  required double durationMinutes,
}) {
  final kcalPerMinute = (met * 3.5 * weightKg) / 200.0;
  return kcalPerMinute * durationMinutes;
}
