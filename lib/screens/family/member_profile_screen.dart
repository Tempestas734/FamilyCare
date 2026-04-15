import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_nav.dart';
import '../medication/add_medication_screen.dart';
import 'edit_member_screen.dart';
import '../settings_screen.dart';

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({
    super.key,
    required this.memberId,
    required this.name,
    required this.role,
    required this.authUserId,
    this.avatarUrl,
    this.birthDate,
    this.bloodType,
    this.weightKg,
    this.inviteEmail,
  });

  final String memberId;
  final String name;
  final String role;
  final String? authUserId;
  final String? avatarUrl;
  final String? birthDate;
  final String? bloodType;
  final double? weightKg;
  final String? inviteEmail;

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  late String _name;
  late String _role;
  String? _avatarUrl;
  String? _birthDate;
  String? _bloodType;
  double? _weightKg;
  String? _inviteEmail;
  bool _isCreator = false;
  String? _creatorEmail;
  bool _loadingMedications = true;
  List<_MemberMedicationPlan> _medicationPlans = const [];

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _role = widget.role;
    _avatarUrl = widget.avatarUrl;
    _birthDate = widget.birthDate;
    _bloodType = widget.bloodType;
    _weightKg = widget.weightKg;
    _inviteEmail = widget.inviteEmail;
    final user = Supabase.instance.client.auth.currentUser;
    _creatorEmail = user?.email;
    _isCreator = user != null && widget.authUserId == user.id;
    _loadMemberMedications();
  }

  Future<void> _loadMemberMedications() async {
    try {
      if (mounted) {
        setState(() => _loadingMedications = true);
      }

      final rows = await Supabase.instance.client
          .from('family_medication_plans')
          .select(
              'id, status, times, intake_amount, intake_unit, family_medications(name, dosage_per_unit)')
          .eq('member_id', widget.memberId)
          .order('created_at', ascending: false);

      final plans = (rows as List<dynamic>).map((raw) {
        final row = raw as Map<String, dynamic>;
        final medRaw = row['family_medications'];
        Map<String, dynamic>? med;
        if (medRaw is Map<String, dynamic>) {
          med = medRaw;
        } else if (medRaw is List && medRaw.isNotEmpty) {
          final first = medRaw.first;
          if (first is Map<String, dynamic>) med = first;
          if (first is Map) med = Map<String, dynamic>.from(first);
        } else if (medRaw is Map) {
          med = Map<String, dynamic>.from(medRaw);
        }

        final name = med?['name']?.toString().trim();
        final dosage = med?['dosage_per_unit']?.toString().trim();
        final intakeAmount = row['intake_amount'];
        final intakeUnit = row['intake_unit']?.toString().trim();

        final timesRaw = row['times'];
        final times = <String>[];
        if (timesRaw is List) {
          for (final t in timesRaw) {
            final s = t?.toString() ?? '';
            if (s.length >= 5) {
              times.add(s.substring(0, 5));
            }
          }
        }

        final title = (name?.isNotEmpty == true) ? name! : 'Medicament';
        final subtitleParts = <String>[];
        if (dosage != null && dosage.isNotEmpty) {
          subtitleParts.add(dosage);
        }
        if (intakeAmount is num && intakeAmount > 0) {
          final amountText = intakeAmount % 1 == 0
              ? intakeAmount.toInt().toString()
              : intakeAmount.toString();
          subtitleParts.add(
            intakeUnit != null && intakeUnit.isNotEmpty
                ? '$amountText $intakeUnit'
                : amountText,
          );
        }
        if (times.isNotEmpty) {
          subtitleParts.add(times.take(2).join(', '));
        }

        return _MemberMedicationPlan(
          planId: row['id']?.toString() ?? '',
          title: title,
          subtitle: subtitleParts.isEmpty
              ? 'Aucune precision de planning'
              : subtitleParts.join(' - '),
          icon: Icons.medication,
          color: const Color(0xFFFFB866),
          isActive: row['status']?.toString() == 'active',
        );
      }).where((p) => p.planId.isNotEmpty).toList();

      if (!mounted) return;
      setState(() {
        _medicationPlans = plans;
        _loadingMedications = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMedications = false);
    }
  }

  Future<void> _toggleMedicationPlan(
    _MemberMedicationPlan plan,
    bool value,
  ) async {
    final previous = plan.isActive;
    setState(() {
      _medicationPlans = _medicationPlans.map((item) {
        if (item.planId != plan.planId) return item;
        return item.copyWith(isActive: value);
      }).toList();
    });

    try {
      await Supabase.instance.client.from('family_medication_plans').update({
        'status': value ? 'active' : 'inactive',
      }).eq('id', plan.planId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _medicationPlans = _medicationPlans.map((item) {
          if (item.planId != plan.planId) return item;
          return item.copyWith(isActive: previous);
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de modifier le statut')),
      );
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
          final displayRole = _roleLabel(_role);

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.08),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final result = await Navigator.of(context)
                                        .push<Map<String, dynamic>>(
                                      MaterialPageRoute(
                                        builder: (_) => EditMemberScreen(
                                          memberId: widget.memberId,
                                          name: _name,
                                          role: _role,
                                          isCreator: _isCreator,
                                          creatorEmail: _creatorEmail,
                                          birthDate: _birthDate,
                                          bloodType: _bloodType,
                                          weightKg: _weightKg,
                                          inviteEmail: _inviteEmail,
                                        ),
                                      ),
                                    );
                                    if (result == null) return;
                                    setState(() {
                                      _name = result['full_name']?.toString() ??
                                          _name;
                                      _role =
                                          result['role']?.toString() ?? _role;
                                      _birthDate =
                                          result['birth_date']?.toString();
                                      _bloodType =
                                          result['blood_type']?.toString();
                                      final weight = result['weight_kg'];
                                      _weightKg =
                                          weight is num ? weight.toDouble() : null;
                                      _inviteEmail =
                                          result['invite_email']?.toString();
                                      _avatarUrl = _roleAvatarUrl(_role);
                                    });
                                  },
                                  icon: Icon(
                                    Icons.settings,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                Container(
                                  width: 112,
                                  height: 112,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      width: 4,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: _avatarUrl == null
                                        ? null
                                        : NetworkImage(_avatarUrl!),
                                    backgroundColor:
                                        theme.colorScheme.primary.withOpacity(0.1),
                                    child: _avatarUrl == null
                                        ? Text(
                                            _name.isEmpty
                                                ? '?'
                                                : _name.characters.first
                                                    .toUpperCase(),
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 22,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Profil de $_name',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Position: $displayRole',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
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
                          children: [
                            _InfoSection(
                              title: 'Informations de base',
                              child: Row(
                                children: [
                                  _InfoTile(
                                    label: 'Sang',
                                    value: _bloodType?.isNotEmpty == true
                                        ? _bloodType!
                                        : '..',
                                  ),
                                  _InfoTile(
                                    label: 'Age',
                                    value: _ageLabel(_birthDate),
                                  ),
                                  _InfoTile(
                                    label: 'Poids',
                                    value: _weightKg != null
                                        ? '${_weightKg!.toStringAsFixed(0)} kg'
                                        : '..',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _InfoSection(
                              title: 'Medicaments a planifier',
                              action: 'Ajouter',
                              onActionTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddMedicationScreen(
                                      preselectedMemberId: widget.memberId,
                                    ),
                                  ),
                                );
                                _loadMemberMedications();
                              },
                              child: Column(
                                children: _loadingMedications
                                    ? const [
                                        Padding(
                                          padding: EdgeInsets.symmetric(vertical: 10),
                                          child: Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]
                                    : _medicationPlans.isEmpty
                                        ? [
                                            Text(
                                              'Aucun medicament pour ce membre.',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ]
                                        : _medicationPlans
                                            .map(
                                              (plan) => _MedicationRow(
                                                title: plan.title,
                                                subtitle: plan.subtitle,
                                                icon: plan.icon,
                                                color: plan.color,
                                                isActive: plan.isActive,
                                                onChanged: (value) =>
                                                    _toggleMedicationPlan(plan, value),
                                              ),
                                            )
                                            .toList(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _InfoSection(
                              title: 'Historique recent',
                              action: 'Voir tout',
                              child: Column(
                                children: const [
                                  _HistoryRow(
                                    title: 'Check-up Tension',
                                    subtitle:
                                        'Tension stable : 124/82 mmHg.',
                                    time: 'Hier, 18:30',
                                    icon: Icons.check_circle,
                                    color: Color(0xFF6FE39B),
                                  ),
                                  _HistoryRow(
                                    title: 'Activite physique',
                                    subtitle:
                                        'Marche rapide de 45 minutes.',
                                    time: 'Il y a 2 jours',
                                    icon: Icons.directions_run,
                                    color: Color(0xFF7F13EC),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                AppBottomNav(
                  activeTab: AppTab.home,
                  onSettings: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
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

class _MemberMedicationPlan {
  const _MemberMedicationPlan({
    required this.planId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isActive,
  });

  final String planId;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isActive;

  _MemberMedicationPlan copyWith({
    String? planId,
    String? title,
    String? subtitle,
    IconData? icon,
    Color? color,
    bool? isActive,
  }) {
    return _MemberMedicationPlan(
      planId: planId ?? this.planId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.child,
    this.action,
    this.onActionTap,
  });

  final String title;
  final Widget child;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (action != null)
              GestureDetector(
                onTap: onActionTap,
                child: Text(
                  action!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.black45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationRow extends StatelessWidget {
  const _MedicationRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
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
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
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

String _roleLabel(String role) {
  switch (role) {
    case 'pere':
      return 'Pere';
    case 'mere':
      return 'Mere';
    case 'enfant':
      return 'Enfant';
    case 'grand_parent':
      return 'Grand-parent';
    default:
      return 'Autre';
  }
}

String _ageLabel(String? birthDate) {
  if (birthDate == null || birthDate.isEmpty) {
    return '..';
  }
  final parsed = DateTime.tryParse(birthDate);
  if (parsed == null) {
    return '..';
  }
  final now = DateTime.now();
  var age = now.year - parsed.year;
  final hasHadBirthday =
      (now.month > parsed.month) ||
      (now.month == parsed.month && now.day >= parsed.day);
  if (!hasHadBirthday) {
    age -= 1;
  }
  return '$age ans';
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
