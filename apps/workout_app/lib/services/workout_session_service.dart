import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyMemberLite {
  const FamilyMemberLite({
    required this.id,
    required this.familyId,
    required this.name,
  });

  final String id;
  final String familyId;
  final String name;
}

class WorkoutSessionService {
  WorkoutSessionService(this._client);

  final SupabaseClient _client;

  Future<List<FamilyMemberLite>> loadFamilyMembersForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];

    final owner = await _client
        .from('family_members')
        .select('family_id')
        .eq('auth_user_id', user.id)
        .limit(1)
        .maybeSingle();
    final familyId = owner?['family_id']?.toString();
    if (familyId == null || familyId.isEmpty) return const [];

    final rows = await _client
        .from('family_members')
        .select('id, full_name')
        .eq('family_id', familyId)
        .order('created_at');

    return (rows as List<dynamic>)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .map(
          (row) => FamilyMemberLite(
            id: row['id']?.toString() ?? '',
            familyId: familyId,
            name: (row['full_name']?.toString().trim().isNotEmpty == true)
                ? row['full_name'].toString()
                : 'Membre',
          ),
        )
        .where((m) => m.id.isNotEmpty)
        .toList();
  }

  Future<void> createWorkoutSession({
    required String familyId,
    required String memberId,
    required String workoutType,
    required int durationMinutes,
    required num estimatedCalories,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    await _client.from('workout_sessions').insert({
      'family_id': familyId,
      'member_id': memberId,
      'source_app': 'workout_app',
      'workout_type': workoutType,
      'duration_minutes': durationMinutes,
      'estimated_calories': estimatedCalories,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
    });
  }
}
