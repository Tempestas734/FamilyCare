import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class EditMemberScreen extends StatefulWidget {
  const EditMemberScreen({
    super.key,
    required this.memberId,
    required this.name,
    required this.role,
    required this.isCreator,
    this.creatorEmail,
    this.birthDate,
    this.bloodType,
    this.weightKg,
    this.inviteEmail,
  });

  final String memberId;
  final String name;
  final String role;
  final bool isCreator;
  final String? creatorEmail;
  final String? birthDate;
  final String? bloodType;
  final double? weightKg;
  final String? inviteEmail;

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _bloodTypeController;
  late final TextEditingController _weightController;

  late String _role;
  late String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    final initialEmail =
        widget.isCreator ? (widget.creatorEmail ?? '') : (widget.inviteEmail ?? '');
    _emailController = TextEditingController(text: initialEmail);
    _birthDateController =
        TextEditingController(text: widget.birthDate ?? '');
    _bloodTypeController =
        TextEditingController(text: widget.bloodType ?? '');
    _weightController = TextEditingController(
      text: widget.weightKg == null
          ? ''
          : widget.weightKg!.toStringAsFixed(0),
    );
    _role = widget.role;
    _avatarUrl = _roleAvatarUrl(_role);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _bloodTypeController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      debugPrint('EditMember: user=${user?.id} memberId=${widget.memberId}');
      final payload = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'role': _role,
      };

      if (widget.isCreator && (widget.creatorEmail?.isNotEmpty ?? false)) {
        payload['invite_email'] = widget.creatorEmail;
      } else {
        final email = _emailController.text.trim();
        payload['invite_email'] = email.isEmpty ? null : email;
      }

      final birthDate = _birthDateController.text.trim();
      if (birthDate.isNotEmpty) {
        payload['birth_date'] = birthDate;
      } else {
        payload['birth_date'] = null;
      }

      final bloodType = _bloodTypeController.text.trim();
      payload['blood_type'] = bloodType.isEmpty ? null : bloodType;

      final weightText = _weightController.text.trim();
      if (weightText.isNotEmpty) {
        payload['weight_kg'] = double.tryParse(weightText);
      } else {
        payload['weight_kg'] = null;
      }

      debugPrint('EditMember: payload=$payload');
      await Supabase.instance.client
          .from('family_members')
          .update(payload)
          .eq('id', widget.memberId);

      if (!mounted) return;
      Navigator.of(context).pop({
        'full_name': payload['full_name'],
        'role': _role,
        'birth_date': payload['birth_date'],
        'blood_type': payload['blood_type'],
        'weight_kg': payload['weight_kg'],
        'invite_email': payload['invite_email'],
      });
    } on PostgrestException catch (e) {
      _showMessage('Erreur DB: ${e.message}');
    } catch (e) {
      _showMessage('Erreur inconnue: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new,
                              color: theme.colorScheme.primary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        Text(
                          'Modifier le Profil',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _AvatarHeader(
                      avatarUrl: _avatarUrl,
                    ),
                    const SizedBox(height: 24),
                    _InputField(
                      label: 'Nom complet',
                      child: TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'ex: Jean Dupont',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nom requis';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InputField(
                      label: 'Email',
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: widget.isCreator,
                        decoration: InputDecoration(
                          hintText: 'email@exemple.com',
                          helperText: widget.isCreator
                              ? null
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _SelectField(
                            label: 'Groupe Sanguin',
                            value: _bloodTypeController.text.isEmpty
                                ? null
                                : _bloodTypeController.text,
                            items: const [
                              'A+',
                              'A-',
                              'B+',
                              'B-',
                              'AB+',
                              'AB-',
                              'O+',
                              'O-',
                            ],
                            onChanged: (value) {
                              _bloodTypeController.text = value ?? '';
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InputField(
                            label: 'Age',
                            child: TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: _ageFromBirth(
                                          _birthDateController.text,
                                        )
                                            ?.toString() ??
                                        '..',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            label: 'Poids (kg)',
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '70',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SelectField(
                            label: 'Position',
                            value: _role,
                            items: const [
                              'pere',
                              'mere',
                              'enfant',
                              'grand_parent',
                              'autre',
                            ],
                            display: const {
                              'pere': 'Pere',
                              'mere': 'Mere',
                              'enfant': 'Enfant',
                              'grand_parent': 'Grand-parent',
                              'autre': 'Autre',
                            },
                            onChanged: (value) {
                              setState(() {
                                _role = value ?? 'autre';
                                _avatarUrl = _roleAvatarUrl(_role);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InputField(
                      label: 'Date de naissance',
                      child: TextFormField(
                        controller: _birthDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icon(Icons.cake),
                        ),
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(now.year - 25, 1, 1),
                            firstDate: DateTime(now.year - 120, 1, 1),
                            lastDate: now,
                          );
                          if (picked != null) {
                            _birthDateController.text =
                                picked.toIso8601String().split('T').first;
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Enregistrer'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              await Supabase.instance.client
                                  .from('family_members')
                                  .delete()
                                  .eq('id', widget.memberId);
                              if (!mounted) return;
                              Navigator.of(context).pop();
                            },
                      child: const Text(
                        'Supprimer ce profil',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E5B7A),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFE1DCE8)),
          ),
          child: Theme(
            data: theme.copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.display,
  });

  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? value;
  final Map<String, String>? display;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E5B7A),
          ),
        ),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            items: items
                .map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text(display?[item] ?? item),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  const _AvatarHeader({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                color: theme.colorScheme.primary.withOpacity(0.05),
                image: avatarUrl == null
                    ? null
                    : DecorationImage(
                        image: NetworkImage(avatarUrl!),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 4),
                ),
                child: const Icon(
                  Icons.photo_camera,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

int? _ageFromBirth(String? birthDate) {
  if (birthDate == null || birthDate.isEmpty) return null;
  final parsed = DateTime.tryParse(birthDate);
  if (parsed == null) return null;
  final now = DateTime.now();
  var age = now.year - parsed.year;
  final hadBirthday =
      (now.month > parsed.month) ||
      (now.month == parsed.month && now.day >= parsed.day);
  if (!hadBirthday) age -= 1;
  return age;
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
