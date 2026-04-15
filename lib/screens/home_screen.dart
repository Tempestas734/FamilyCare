import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'calendar/calendar_screen.dart';
import '../widgets/app_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _family;
  bool _loading = true;
  bool _loadingToday = true;
  bool _showFamily = true;
  List<_HomeAgendaItem> _familyTodayItems = const [];
  List<_HomeAgendaItem> _meTodayItems = const [];
  List<_HomeTimelineItem> _familyRecentTaken = const [];
  List<_HomeTimelineItem> _meRecentTaken = const [];
  List<String> _familyMemberAvatars = const [];
  int _activeFamilyMembers = 0;
  List<_FamilyMemberChoice> _familyMembers = const [];
  String? _selectedFamilyMemberId;

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
          .select('id, family_id, families (family_name)')
          .eq('auth_user_id', user.id)
          .limit(1)
          .maybeSingle();

      final familyId = data?['family_id']?.toString();
      final memberId = data?['id']?.toString();
      List<String> familyAvatars = const [];
      int activeMembers = 0;
      List<_FamilyMemberChoice> familyMembers = const [];
      if (familyId != null && familyId.isNotEmpty) {
        final memberRows = await Supabase.instance.client
            .from('family_members')
            .select('id, full_name, role, auth_user_id')
            .eq('family_id', familyId)
            .order('created_at');
        final rows = (memberRows as List<dynamic>)
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        familyMembers = rows
            .map(
              (row) => _FamilyMemberChoice(
                id: row['id']?.toString() ?? '',
                name: _asText(row['full_name']) ?? 'Membre',
                role: _asText(row['role']) ?? 'autre',
              ),
            )
            .where((m) => m.id.isNotEmpty)
            .toList();
        familyAvatars = rows
            .map((row) => _avatarForRole(row['role']?.toString()))
            .toList();
        activeMembers = rows
            .where((row) => _asText(row['auth_user_id']) != null)
            .length;
        await _loadTodayItems(
          familyId: familyId,
          userId: user.id,
          memberId: memberId,
        );
      } else {
        _loadingToday = false;
      }

      setState(() {
        _family = data == null ? null : data['families'] as Map<String, dynamic>?;
        _familyMemberAvatars = familyAvatars;
        _activeFamilyMembers = activeMembers;
        _familyMembers = familyMembers;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _loadingToday = false;
        _familyMemberAvatars = const [];
        _activeFamilyMembers = 0;
        _familyMembers = const [];
      });
    }
  }

  String _todayYmd() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _hhmm(dynamic raw) {
    final s = raw?.toString() ?? '';
    if (s.length >= 5) return s.substring(0, 5);
    return '--:--';
  }

  Map<String, dynamic>? _extractMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String? _asText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'undefined' || text == 'null') return null;
    return text;
  }

  Future<void> _loadTodayItems({
    required String familyId,
    required String userId,
    required String? memberId,
  }) async {
    try {
      if (mounted) {
        setState(() => _loadingToday = true);
      }

      final today = _todayYmd();

      final rdvFamilyQuery = Supabase.instance.client
          .from('rendez_vous')
          .select(
              'date, heure, status, family_members!inner(id, full_name, role, auth_user_id), medecins_famille!inner(family_id, medecins(first_name, last_name, specialite))')
          .eq('medecins_famille.family_id', familyId)
          .eq('date', today)
          .neq('status', 'annule');

      final rdvMeQuery = Supabase.instance.client
          .from('rendez_vous')
          .select(
              'date, heure, status, family_members!inner(id, full_name, role, auth_user_id), medecins_famille!inner(family_id, medecins(first_name, last_name, specialite))')
          .eq('medecins_famille.family_id', familyId)
          .eq('date', today)
          .eq('family_members.auth_user_id', userId)
          .neq('status', 'annule');

      final medFamilyQuery = Supabase.instance.client
          .from('family_medication_doses')
          .select(
              'id, scheduled_time, taken, family_members!inner(id, full_name, role, auth_user_id), family_medications!inner(name), family_medication_plans!inner(status)')
          .eq('family_id', familyId)
          .eq('scheduled_date', today)
          .eq('taken', false)
          .eq('family_medication_plans.status', 'active');

      final medMeQuery = Supabase.instance.client
          .from('family_medication_doses')
          .select(
              'id, scheduled_time, taken, family_members!inner(id, full_name, role, auth_user_id), family_medications!inner(name), family_medication_plans!inner(status)')
          .eq('family_id', familyId)
          .eq('scheduled_date', today)
          .eq('taken', false)
          .eq('family_medication_plans.status', 'active');

      final medMeFiltered = (memberId != null && memberId.isNotEmpty)
          ? medMeQuery.eq('member_id', memberId)
          : medMeQuery.eq('family_members.auth_user_id', userId);

      final rdvFamily = await rdvFamilyQuery.order('heure');
      final rdvMe = await rdvMeQuery.order('heure');
      final medFamily = await medFamilyQuery.order('scheduled_time');
      final medMe = await medMeFiltered.order('scheduled_time');
      final takenFamilyQuery = Supabase.instance.client
          .from('family_medication_doses')
          .select(
              'taken_at, scheduled_time, family_members!inner(id, full_name, role, auth_user_id), family_medications!inner(name)')
          .eq('family_id', familyId)
          .eq('taken', true)
          .not('taken_at', 'is', null)
          .order('taken_at', ascending: false)
          .limit(10);
      final takenMeQueryBase = Supabase.instance.client
          .from('family_medication_doses')
          .select(
              'taken_at, scheduled_time, family_members!inner(id, full_name, role, auth_user_id), family_medications!inner(name)')
          .eq('family_id', familyId)
          .eq('taken', true)
          .not('taken_at', 'is', null);
      final takenMeFiltered = (memberId != null && memberId.isNotEmpty)
          ? takenMeQueryBase.eq('member_id', memberId)
          : takenMeQueryBase.eq('family_members.auth_user_id', userId);
      final takenFamily = await takenFamilyQuery;
      final takenMe = await takenMeFiltered
          .order('taken_at', ascending: false)
          .limit(10);

      List<_HomeAgendaItem> mapRdv(List<dynamic> rows) {
        return rows.map((raw) {
          final row = raw as Map<String, dynamic>;
          final member = _extractMap(row['family_members']);
          final medFam = _extractMap(row['medecins_famille']);
          final medecin = _extractMap(medFam?['medecins']);
          final firstName = medecin?['first_name']?.toString() ?? '';
          final lastName = medecin?['last_name']?.toString() ?? '';
          final doctor = 'Dr. ${'$firstName $lastName'.trim()}'.trim();
          final specialty = medecin?['specialite']?.toString() ?? 'Medecin';
          final roleOrName =
              _asText(member?['role']) ?? _asText(member?['full_name']) ?? 'Membre';
          return _HomeAgendaItem(
            time: _hhmm(row['heure']),
            title: 'RDV $specialty',
            subtitle: 'Pour $roleOrName • $doctor',
            icon: Icons.medical_services,
            iconBg: const Color(0xFF133654),
            iconColor: const Color(0xFF68B6FF),
            memberId: member?['id']?.toString(),
          );
        }).toList();
      }

      List<_HomeAgendaItem> mapMeds(List<dynamic> rows) {
        return rows.map((raw) {
          final row = raw as Map<String, dynamic>;
          final member = _extractMap(row['family_members']);
          final med = _extractMap(row['family_medications']);
          final roleOrName =
              _asText(member?['role']) ?? _asText(member?['full_name']) ?? 'Membre';
          return _HomeAgendaItem(
            time: _hhmm(row['scheduled_time']),
            title: med?['name']?.toString() ?? 'Medicament',
            subtitle: 'Rappel pour $roleOrName',
            icon: Icons.medication,
            iconBg: const Color(0xFF5A360B),
            iconColor: const Color(0xFFFFB866),
            isMedication: true,
            doseId: row['id']?.toString(),
            memberId: member?['id']?.toString(),
          );
        }).toList();
      }

      final familyItems = [...mapRdv(rdvFamily), ...mapMeds(medFamily)]
        ..sort((a, b) => a.time.compareTo(b.time));
      final meItems = [...mapRdv(rdvMe), ...mapMeds(medMe)]
        ..sort((a, b) => a.time.compareTo(b.time));
      List<_HomeTimelineItem> mapTaken(List<dynamic> rows) {
        return rows.map((raw) {
          final row = raw as Map<String, dynamic>;
          final member = _extractMap(row['family_members']);
          final med = _extractMap(row['family_medications']);
          final takenAt = DateTime.tryParse(row['taken_at']?.toString() ?? '');
          final roleOrName =
              _asText(member?['role']) ?? _asText(member?['full_name']) ?? 'Membre';
          final medName = med?['name']?.toString() ?? 'medicament';
          final plannedTime = _hhmm(row['scheduled_time']);
          return _HomeTimelineItem(
            name: roleOrName,
            time: _relativeFromNow(takenAt),
            content: 'a pris $medName (prevu a $plannedTime).',
            imageUrl: _avatarForRole(member?['role']?.toString()),
            memberId: member?['id']?.toString(),
          );
        }).take(3).toList();
      }

      if (!mounted) return;
      setState(() {
        _familyTodayItems = familyItems;
        _meTodayItems = meItems;
        _familyRecentTaken = mapTaken(takenFamily);
        _meRecentTaken = mapTaken(takenMe);
        _loadingToday = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingToday = false);
    }
  }

  Future<void> _onAgendaTap(_HomeAgendaItem item) async {
    if (!item.isMedication || item.doseId == null || item.doseId!.isEmpty) {
      return;
    }

    final taken = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prise du medicament'),
        content: Text('Est-ce que "${item.title}" est prise ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (!mounted || taken == null) return;
    if (!taken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicament non pris.')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('family_medication_doses').update({
        'taken': true,
        'taken_at': DateTime.now().toIso8601String(),
      }).eq('id', item.doseId!);

      if (!mounted) return;
      setState(() {
        _familyTodayItems = _familyTodayItems
            .where((e) => e.doseId != item.doseId)
            .toList();
        _meTodayItems =
            _meTodayItems.where((e) => e.doseId != item.doseId).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicament marque comme pris.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise a jour.')),
      );
    }
  }

  String _selectedFamilyMemberLabel() {
    if (_selectedFamilyMemberId == null) return 'Tous';
    for (final member in _familyMembers) {
      if (member.id == _selectedFamilyMemberId) return member.name;
    }
    return 'Tous';
  }

  Future<void> _pickFamilyMember() async {
    if (_familyMembers.isEmpty) return;
    final selected = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Choisir un membre')),
              ListTile(
                leading: const Icon(Icons.groups),
                title: const Text('Tous les membres'),
                trailing: _selectedFamilyMemberId == null
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(null),
              ),
              ..._familyMembers.map((member) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(_avatarForRole(member.role)),
                  ),
                  title: Text(member.name),
                  subtitle: Text(member.role),
                  trailing: _selectedFamilyMemberId == member.id
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(context).pop(member.id),
                );
              }),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() => _selectedFamilyMemberId = selected);
  }

  String _relativeFromNow(DateTime? dateTime) {
    if (dateTime == null) return 'Recent';
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'A l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays} jours';
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

          final familyName = _asText(_family?['family_name']) ?? 'Famille';
          final visibleFamilyTodayItems = _selectedFamilyMemberId == null
              ? _familyTodayItems
              : _familyTodayItems
                  .where((item) => item.memberId == _selectedFamilyMemberId)
                  .toList();
          final visibleFamilyRecentTaken = _selectedFamilyMemberId == null
              ? _familyRecentTaken
              : _familyRecentTaken
                  .where((item) => item.memberId == _selectedFamilyMemberId)
                  .toList();

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
                      'Famille',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.notifications,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      _AvatarCircle(
                        imageUrl:
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuBdN7bnNU6TR1CS8DghMWvZEYmyFEcFM-Y2Y3Zbi6yGkt5BxqPWIqcvcsa_BEz3D7DAJFLONJiA2pOTpy01FupzCRhra6wPSCv5O74--2_2KmbgIs0-pr0dQOGNx2xiMpA2k4aMAtV84lVEWmrpgr5BE9ibi--RP_STU7IIjIHiecrDHZ7hfvPAtRTXZxw1VPqauniTeLK-eZF2GxtMoLSK1T7nIN8OAwxlap7KpqxWS_tww4z4uaqiaB6eghzdZWzzi9IEJXZHM2PT',
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _showFamily = true),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _showFamily
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: _showFamily
                                        ? [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Famille',
                                    textAlign: TextAlign.center,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: _showFamily
                                          ? Colors.white
                                          : Colors.black54,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _showFamily = false),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !_showFamily
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: !_showFamily
                                        ? [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Moi',
                                    textAlign: TextAlign.center,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: !_showFamily
                                          ? Colors.white
                                          : Colors.black54,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_showFamily)
                            _FamilyStack(
                              members: _familyMemberAvatars.isEmpty
                                  ? [_avatarForRole(null)]
                                  : _familyMemberAvatars,
                            )
                          else
                            const _AvatarCircle(
                              imageUrl:
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBdN7bnNU6TR1CS8DghMWvZEYmyFEcFM-Y2Y3Zbi6yGkt5BxqPWIqcvcsa_BEz3D7DAJFLONJiA2pOTpy01FupzCRhra6wPSCv5O74--2_2KmbgIs0-pr0dQOGNx2xiMpA2k4aMAtV84lVEWmrpgr5BE9ibi--RP_STU7IIjIHiecrDHZ7hfvPAtRTXZxw1VPqauniTeLK-eZF2GxtMoLSK1T7nIN8OAwxlap7KpqxWS_tww4z4uaqiaB6eghzdZWzzi9IEJXZHM2PT',
                              size: 32,
                              borderColor: Colors.white,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _showFamily
                                      ? (_loading
                                          ? 'Chargement...'
                                          : 'Famille $familyName')
                                      : 'Moi',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _showFamily
                                      ? (_activeFamilyMembers <= 1
                                          ? '$_activeFamilyMembers membre actif'
                                          : '$_activeFamilyMembers membres actifs')
                                      : 'Suivi personnel actif',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  theme.colorScheme.primary.withOpacity(0.15),
                              foregroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            onPressed: _showFamily ? _pickFamilyMember : () {},
                            icon: Icon(
                              _showFamily ? Icons.unfold_more : Icons.person,
                              size: 16,
                            ),
                            label: Text(
                              _showFamily ? _selectedFamilyMemberLabel() : 'Profil',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      child: Column(
                        children: _showFamily
                            ? [
                                _TodayCard(
                                  loading: _loadingToday,
                                  items: visibleFamilyTodayItems,
                                  onItemTap: _onAgendaTap,
                                ),
                                const SizedBox(height: 20),
                                _HealthSummaryCard(),
                                const SizedBox(height: 20),
                                _LatestInfoCard(
                                  loading: _loadingToday,
                                  items: visibleFamilyRecentTaken,
                                ),
                              ]
                            : [
                                _PersonalTodayCard(
                                  loading: _loadingToday,
                                  items: _meTodayItems,
                                  onItemTap: _onAgendaTap,
                                ),
                                const SizedBox(height: 18),
                                const _PersonalSummaryGrid(),
                                const SizedBox(height: 18),
                                _LatestInfoCard(
                                  loading: _loadingToday,
                                  items: _meRecentTaken,
                                ),
                              ],
                      ),
                    ),
                  ),
                  ],
                ),
                Positioned(
                  right: 20,
                  bottom: 90,
                  child: FloatingActionButton(
                    backgroundColor: theme.colorScheme.primary,
                    onPressed: () {},
                    child: const Icon(Icons.add, size: 30),
                  ),
                ),
                AppBottomNav(
                  activeTab: AppTab.home,
                  onSettings: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  onCalendar: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
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

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.loading,
    required this.items,
    required this.onItemTap,
  });

  final bool loading;
  final List<_HomeAgendaItem> items;
  final ValueChanged<_HomeAgendaItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleItems = items.take(3).toList();
    final eventCount = items.length;
    final countLabel = loading
        ? 'Chargement...'
        : eventCount == 0
            ? 'Aucun evenement prevu'
            : '$eventCount evenement${eventCount > 1 ? 's' : ''} prevu${eventCount > 1 ? 's' : ''}';

    return Container(
      decoration: _cardDecoration(theme),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3D2C).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Tout va bien',
                              style: TextStyle(
                                color: Color(0xFF6FE39B),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Aujourd\'hui',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            countLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CalendarScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                else if (items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F0F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Aucun rendez-vous ni prise de medicament non prise pour aujourd\'hui.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  )
                else
                  ...List.generate(visibleItems.length, (index) {
                    final item = visibleItems[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == visibleItems.length - 1 ? 0 : 10,
                      ),
                      child: _EventRow(
                        icon: item.icon,
                        iconBg: item.iconBg,
                        iconColor: item.iconColor,
                        title: item.title,
                        subtitle: item.subtitle,
                        time: item.time,
                        onTap: () => onItemTap(item),
                      ),
                    );
                  }),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                    ),
                  ),
                  color: theme.colorScheme.primary.withOpacity(0.08),
                ),
                child: Text(
                  'Voir les details',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F0F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
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

class _HealthSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resume sante',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.directions_walk,
                label: 'Activite',
                value: '6 200 pas',
                badge: '+12%',
                badgeColor: const Color(0xFF6FE39B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                icon: Icons.monitor_weight,
                label: 'Poids',
                value: 'Stable',
                badge: 'STABLE',
                badgeColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String badge;
  final Color badgeColor;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              Text(
                badge,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestInfoCard extends StatelessWidget {
  const _LatestInfoCard({
    required this.loading,
    this.items,
  });

  final bool loading;
  final List<_HomeTimelineItem>? items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timelineItems = items ?? const <_HomeTimelineItem>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dernieres infos',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (timelineItems.isEmpty)
            Text(
              'Aucune prise recente.',
              style: theme.textTheme.bodySmall,
            )
          else
            Column(
              children: List.generate(timelineItems.length, (index) {
                final item = timelineItems[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == timelineItems.length - 1 ? 0 : 18,
                  ),
                  child: _TimelineItem(
                    name: item.name,
                    time: item.time,
                    content: item.content,
                    imageUrl: item.imageUrl,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _PersonalTodayCard extends StatelessWidget {
  const _PersonalTodayCard({
    required this.loading,
    required this.items,
    required this.onItemTap,
  });

  final bool loading;
  final List<_HomeAgendaItem> items;
  final ValueChanged<_HomeAgendaItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleItems = items.take(3).toList();
    final taskCount = items.length;
    final countLabel = loading
        ? 'Chargement...'
        : taskCount == 0
            ? 'Aucune tache personnelle'
            : '$taskCount tache${taskCount > 1 ? 's' : ''} personnelle${taskCount > 1 ? 's' : ''}';

    return Container(
      decoration: _cardDecoration(theme),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'En pleine forme',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Aujourd\'hui',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            countLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CalendarScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  )
                else if (items.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Aucune prise de medicament non prise ni rendez-vous pour aujourd\'hui.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  )
                else
                  ...List.generate(visibleItems.length, (index) {
                    final item = visibleItems[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == visibleItems.length - 1 ? 0 : 10,
                      ),
                      child: _EventRow(
                        icon: item.icon,
                        iconBg: item.iconBg,
                        iconColor: item.iconColor,
                        title: item.title,
                        subtitle: item.subtitle,
                        time: item.time,
                        onTap: () => onItemTap(item),
                      ),
                    );
                  }),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                    ),
                  ),
                  color: theme.colorScheme.primary.withOpacity(0.06),
                ),
                child: Text(
                  'Voir les details',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalSummaryGrid extends StatelessWidget {
  const _PersonalSummaryGrid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resume sante',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.directions_walk,
                label: 'Activite',
                value: '8 450 pas',
                badge: '+15%',
                badgeColor: const Color(0xFF6FE39B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                icon: Icons.monitor_weight,
                label: 'Poids',
                value: '78.5 kg',
                badge: 'STABLE',
                badgeColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.name,
    required this.time,
    required this.content,
    required this.imageUrl,
  });

  final String name;
  final String time;
  final String content;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _AvatarCircle(
              imageUrl: imageUrl,
              size: 40,
              borderColor: theme.colorScheme.surface,
            ),
            const SizedBox(height: 6),
            Container(
              width: 2,
              height: 40,
              color: theme.colorScheme.primary.withOpacity(0.1),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
                Text(
                  content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeAgendaItem {
  const _HomeAgendaItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.isMedication = false,
    this.doseId,
    this.memberId,
  });

  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool isMedication;
  final String? doseId;
  final String? memberId;
}

class _HomeTimelineItem {
  const _HomeTimelineItem({
    required this.name,
    required this.time,
    required this.content,
    required this.imageUrl,
    this.memberId,
  });

  final String name;
  final String time;
  final String content;
  final String imageUrl;
  final String? memberId;
}

class _FamilyMemberChoice {
  const _FamilyMemberChoice({
    required this.id,
    required this.name,
    required this.role,
  });

  final String id;
  final String name;
  final String role;
}

class _FamilyStack extends StatelessWidget {
  const _FamilyStack({required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 32,
      child: Stack(
        children: [
          for (int i = 0; i < members.length; i++)
            Positioned(
              left: i * 18.0,
              child: _AvatarCircle(
                imageUrl: members[i],
                size: 32,
                borderColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.imageUrl,
    required this.size,
    this.borderColor,
  });

  final String imageUrl;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? AppTheme.bg,
          width: 2,
        ),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}


BoxDecoration _cardDecoration(ThemeData theme) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
    boxShadow: [
      BoxShadow(
        color: theme.colorScheme.primary.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

String _avatarForRole(String? role) {
  switch (role) {
    case 'pere':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuCqrdt8Y2LDzW4L2OBgbaWMLUFtzv5wsTxRXsTenIk5--Sn09sN8kf5DT5ICS1y9U8cj3QfNVyf24wGEV2thzTAdGSIPCUr4594VL3QdZvIj95Fa4ANu0m2HwJER9skr5lYbnns-DBHiuWuOfG7buIYYRaMg7gtc8TfCwuhQ2q6I6yotGv-HoAGGuL_EJl2sY0IQyyKi-lNh3Dd8aY75M6Vj0IiG6Tvl19N2CKNb9NxPNbp44T75SA-jgZON8hK9EU9-kY63ujD5hX6';
    case 'mere':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuA_Oh9U81EW2PATmAxX3My-4rgugn1enxEPsQk7q_EOMvOPn8vNu_BZ-JEbrcyTOxTJq3GqhV1ZieQjzxikW8Cg1Fuew4wc1VwYihEj6vcBRFwu_vpe-a374U1IN08WYMlyR4uljQFkd9F316fyaOVTvaHcfVSE0nQQuQPR5bPQ4gCDyZQPhLYVJmR3yLEjrO17ARccCMp9hBavxp8UlLPZFEP4qG0JE-RtndAFGKkpetOuQkpFZIYCaJnoRlEbOfK6wPyikIhjYg1s';
    case 'enfant':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuAY6lvv8vRlHNQMoa2s0mMoaM3skXYxHnaHvoDVleBFHpbJglmAFO7VEfP0QHrovrTAq1u3kn6U5b0SRZFWCrg1I2fz7TYylpVKPkCfJgOvnA2xPHJTtADDjIwkDAWPcdd2iKK3iXBUB2VCbV05PR2N92HQNEVJ-ASLkdakIGkKBgsqOyWyMO7brLfckgm0T_0nJOUxUjpmtxpAtJkY-jxrwkMRC_qvfEclUPcqNh2SaA4Tgfc-tLtfVUvCdCC9JQRF0Sa8jPVhw5TB';
    default:
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBdN7bnNU6TR1CS8DghMWvZEYmyFEcFM-Y2Y3Zbi6yGkt5BxqPWIqcvcsa_BEz3D7DAJFLONJiA2pOTpy01FupzCRhra6wPSCv5O74--2_2KmbgIs0-pr0dQOGNx2xiMpA2k4aMAtV84lVEWmrpgr5BE9ibi--RP_STU7IIjIHiecrDHZ7hfvPAtRTXZxw1VPqauniTeLK-eZF2GxtMoLSK1T7nIN8OAwxlap7KpqxWS_tww4z4uaqiaB6eghzdZWzzi9IEJXZHM2PT';
  }
}
