import 'package:supabase_flutter/supabase_flutter.dart';

class WorkoutFeedItem {
  const WorkoutFeedItem({
    required this.memberName,
    required this.workoutType,
    required this.durationMinutes,
    required this.estimatedCalories,
    required this.endedAt,
  });

  final String memberName;
  final String workoutType;
  final int durationMinutes;
  final num estimatedCalories;
  final DateTime endedAt;
}

class WorkoutFeedService {
  WorkoutFeedService(this._client);

  final SupabaseClient _client;

  Future<List<WorkoutFeedItem>> fetchRecentFamilySessions({
    required String familyId,
    int limit = 20,
  }) async {
    final rows = await _client
        .from('workout_sessions')
        .select(
            'workout_type, duration_minutes, estimated_calories, ended_at, family_members!inner(full_name)')
        .eq('family_id', familyId)
        .order('ended_at', ascending: false)
        .limit(limit);

    return (rows as List<dynamic>)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .map((row) {
          final member = row['family_members'];
          Map<String, dynamic>? memberMap;
          if (member is Map<String, dynamic>) memberMap = member;
          if (member is Map) memberMap = Map<String, dynamic>.from(member);
          if (member is List && member.isNotEmpty && member.first is Map) {
            memberMap = Map<String, dynamic>.from(member.first as Map);
          }
          return WorkoutFeedItem(
            memberName: memberMap?['full_name']?.toString() ?? 'Membre',
            workoutType: row['workout_type']?.toString() ?? 'Workout',
            durationMinutes: (row['duration_minutes'] as num?)?.toInt() ?? 0,
            estimatedCalories: (row['estimated_calories'] as num?) ?? 0,
            endedAt: DateTime.tryParse(row['ended_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
          );
        })
        .toList();
  }
}
