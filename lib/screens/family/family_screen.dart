import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import 'add_member_screen.dart';
import '../home_screen.dart';
import '../../widgets/app_bottom_nav.dart';
import '../settings_screen.dart';
import 'member_profile_screen.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  Map<String, dynamic>? _family;
  String? _familyId;
  List<Map<String, dynamic>> _members = [];
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
      debugPrint('Family: loading for user=${user.id}');
      final data = await Supabase.instance.client
          .from('family_members')
          .select('family_id')
          .eq('auth_user_id', user.id)
          .limit(1)
          .maybeSingle();

      debugPrint('Family: member row=$data');
      final familyId = data?['family_id']?.toString();
      final members = familyId == null
          ? <Map<String, dynamic>>[]
          : (await Supabase.instance.client
                  .from('family_members')
                  .select('id, full_name, role, auth_user_id, birth_date, blood_type, weight_kg, invite_email')
                  .eq('family_id', familyId)
                  .order('created_at'))
              .cast<Map<String, dynamic>>();

      Map<String, dynamic>? family;
      if (familyId != null) {
        try {
          family = await Supabase.instance.client
              .from('families')
              .select('family_name')
              .eq('id', familyId)
              .maybeSingle();
        } catch (e) {
          debugPrint('Family: families select error $e');
        }
      }

      debugPrint('Family: members count=${members.length}');
      setState(() {
        _family = family;
        _familyId = familyId;
        _members = members;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Family: load error $e');
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
              fontSize: 22,
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
                  : 'Ma famille';

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
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: _CircleButton(
                          icon: Icons.chevron_left,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      centerTitle: true,
                      title: Text(
                        'Ma Famille',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Icon(
                            Icons.settings,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    image: const DecorationImage(
                                      image: NetworkImage(
                                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBkeilY1RAYHikF3nYJ_dy1NP2VR6IDLunbLh0AtTptdkFiuwf2hod1N2OrOoHUiY_fBCNRfiB2YoYSeexr-m9N-unsYUYX1Jm9YmgHBH4sjY5m4wYLGLuHsEw_cDdOoizZgYsgv74_n01rFmc9rjQDFtiD7sV3f-tmIuxI50AadObHpykTyNn_LPlqVLPBI7IKfkpRxC1gQ8CkGXoKRaBza7R9YqcRQYqC9Vx-fxtwNmJIKOFGeow9pHnlaQHQgin1jCuAct3ZNeqm',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.3),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.photo_camera,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _loading
                                  ? 'Chargement...'
                                  : 'Famille $familyName',
                              style: theme.textTheme.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Gerez le bien-etre de votre foyer',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Membres',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _loading ? '...' : '${_members.length} actifs',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        child: Column(
                          children: [
                            if (_members.isEmpty && !_loading)
                              const _EmptyMembers()
                            else
                              for (final member in _members) ...[
                                _MemberCard(
                                  name: member['full_name']?.toString() ?? '-',
                                  role: member['role']?.toString() ?? '-',
                                  avatarUrl: _roleAvatarUrl(
                                    member['role']?.toString(),
                                  ),
                                  statusColor: const Color(0xFF3DDC84),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => MemberProfileScreen(
                                            memberId: member['id']?.toString() ?? '',
                                            name: member['full_name']
                                                    ?.toString() ??
                                                '-',
                                            role:
                                                member['role']?.toString() ??
                                                    'autre',
                                            authUserId: member['auth_user_id']?.toString(),
                                            avatarUrl: _roleAvatarUrl(
                                              member['role']?.toString(),
                                            ),
                                            birthDate:
                                              member['birth_date']?.toString(),
                                          bloodType:
                                              member['blood_type']?.toString(),
                                          weightKg:
                                              (member['weight_kg'] as num?)
                                                  ?.toDouble(),
                                          inviteEmail:
                                              member['invite_email']?.toString(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                            const SizedBox(height: 6),
                            _AddMemberButton(
                              onPressed: _familyId == null
                                  ? null
                                  : () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => AddMemberScreen(
                                            familyId: _familyId!,
                                          ),
                                        ),
                                      );
                                      _loadFamily();
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                AppBottomNav(
                  activeTab: AppTab.home,
                  onHome: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  onSettings: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.name,
    required this.role,
    required this.avatarUrl,
    required this.statusColor,
    this.onTap,
  });

  final String name;
  final String role;
  final String? avatarUrl;
  final Color statusColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  backgroundImage:
                      avatarUrl == null ? null : NetworkImage(avatarUrl!),
                  child: avatarUrl == null
                      ? Text(
                          name.isEmpty
                              ? '?'
                              : name.characters.first.toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMemberButton extends StatelessWidget {
  const _AddMemberButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter un membre'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}


class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
        ),
      ),
      child: Text(
        'Aucun membre pour le moment.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

String? _roleAvatarUrl(String? role) {
  switch (role) {
    case 'pere':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuCqrdt8Y2LDzW4L2OBgbaWMLUFtzv5wsTxRXsTenIk5--Sn09sN8kf5DT5ICS1y9U8cj3QfNVyf24wGEV2thzTAdGSIPCUr4594VL3QdZvIj95Fa4ANu0m2HwJER9skr5lYbnns-DBHiuWuOfG7buIYYRaMg7gtc8TfCwuhQ2q6I6yotGv-HoAGGuL_EJl2sY0IQyyKi-lNh3Dd8aY75M6Vj0IiG6Tvl19N2CKNb9NxPNbp44T75SA-jgZON8hK9EU9-kY63ujD5hX6';
    case 'mere':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuAEJmPdK_O2RYr-G2GtRL90CoFroxOWj90Ge9G2rwr_FQ9lU2JFsL57M_nJTp7a5GE_bjD9lHj1L3gZTc3bhNXSqpqflLTcWgWLtOtvWHAqWQcuEDUMyadt_yCVrbpuxAppKv2ZfqY6o_OUtsKSeTYu8ncoqUMM8gjNp7mnRESP2CwVekDgWxdgRFGY6ijCkcOun_hMaw3CP4NKe2OMO_Qu76hOP55Eocnsj4lcdB3PWWaii_p-_nTxsx3gYeptfHb82k9sMFkEbTKq';
    case 'enfant':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuD2RoG3vW3Mb2qRrNBDxGKYZ_zw87xeiaLXmH_JvzNjNEGc8A5vPS_ssr62oeWcwMZHtEHWs9KcPrdXD00nIPRslhypxoVPRUG0VyMB4UE8BuZzAeCbnEc7suZH-Hm_4dZNPhZK6Pv0ik29t-J9E2iTWRDjE-XJfg8XI_lDxzUTxM_fDtg9v-u-Al1hQJbPuMD7YjxP-7ZgDSztt-ZAMxn7TKvhYUEK9bqGCfbme9htd969i7oxThjmIQIbmy3cprbXSOmSXUVWAjSd';
    case 'grand_parent':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBkeilY1RAYHikF3nYJ_dy1NP2VR6IDLunbLh0AtTptdkFiuwf2hod1N2OrOoHUiY_fBCNRfiB2YoYSeexr-m9N-unsYUYX1Jm9YmgHBH4sjY5m4wYLGLuHsEw_cDdOoizZgYsgv74_n01rFmc9rjQDFtiD7sV3f-tmIuxI50AadObHpykTyNn_LPlqVLPBI7IKfkpRxC1gQ8CkGXoKRaBza7R9YqcRQYqC9Vx-fxtwNmJIKOFGeow9pHnlaQHQgin1jCuAct3ZNeqm';
    case 'autre':
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBKXLWc3i-WuGXBWzkEUO5vgFt1M8O1MboaF_qcLXMIbv417W4jliKYxti5j0VT3ppS_7wC6dS8_fM734VYJzLxKUrwStQ3RYcf0rKN26ivqev9369_7dF4JZK5emn0dsSWZz1TbTECvCP9JkThKo5Y_QqwEC-bdiUlCX-9v0WH5imj_K5-nUi5WIhPUhcrV7du30U3_zrKYnra1icR6_VUUP71L623vpOhbgavbbCRF-R2kNy9431od2zCK62pk-BpetY-72JxS3km';
    default:
      return null;
  }
}
