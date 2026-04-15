import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key, required this.familyId});

  final String familyId;

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weightController = TextEditingController();
  String? _bloodType;

  String _role = 'pere';
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('AddMember: start familyId=${widget.familyId}');
      final Map<String, dynamic> payload = {
        'family_id': widget.familyId,
        'full_name': _fullNameController.text.trim(),
        'role': _role,
        'is_admin': false,
      };

      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        payload['invite_email'] = email;
      }

      final birthDate = _birthDateController.text.trim();
      if (birthDate.isNotEmpty) {
        payload['birth_date'] = birthDate;
      }

      final bloodType = _bloodType?.trim() ?? '';
      if (bloodType.isNotEmpty) {
        payload['blood_type'] = bloodType;
      }

      final weight = _weightController.text.trim();
      if (weight.isNotEmpty) {
        final parsedWeight = double.tryParse(weight);
        if (parsedWeight != null) {
          payload['weight_kg'] = parsedWeight;
        }
      }

      await Supabase.instance.client.from('family_members').insert(payload);

      debugPrint('AddMember: inserted');
      if (!mounted) return;
      Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      debugPrint('AddMember: db error ${e.message}');
      _showMessage('Erreur DB: ${e.message}');
    } catch (e) {
      debugPrint('AddMember: unknown error $e');
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
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.9),
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: theme.colorScheme.primary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              centerTitle: true,
              title: Text(
                'Ajouter un membre',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _PhotoPicker(),
                    const SizedBox(height: 24),
                    _InputField(
                      label: 'Nom complet',
                      child: TextFormField(
                        controller: _fullNameController,
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
                    _RoleSelector(
                      value: _role,
                      onChanged: (value) => setState(() => _role = value),
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
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InputField(
                      label: 'Groupe sanguin (optionnel)',
                      child: DropdownButtonFormField<String>(
                        initialValue: _bloodType,
                        items: const [
                          'A+',
                          'A-',
                          'B+',
                          'B-',
                          'AB+',
                          'AB-',
                          'O+',
                          'O-',
                        ]
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _bloodType = value),
                        decoration: const InputDecoration(
                          hintText: 'Selectionner',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InputField(
                      label: 'Poids (optionnel)',
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'ex: 82',
                          suffixText: 'kg',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InputField(
                      label: 'Email (facultatif)',
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: "pour l'invitation",
                          prefixIcon: Icon(Icons.mail),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _addMember,
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
                        icon: const Icon(Icons.person_add),
                        label: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Ajouter a la famille'),
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

class _PhotoPicker extends StatelessWidget {
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
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBKXLWc3i-WuGXBWzkEUO5vgFt1M8O1MboaF_qcLXMIbv417W4jliKYxti5j0VT3ppS_7wC6dS8_fM734VYJzLxKUrwStQ3RYcf0rKN26ivqev9369_7dF4JZK5emn0dsSWZz1TbTECvCP9JkThKo5Y_QqwEC-bdiUlCX-9v0WH5imj_K5-nUi5WIhPUhcrV7du30U3_zrKYnra1icR6_VUUP71L623vpOhbgavbbCRF-R2kNy9431od2zCK62pk-BpetY-72JxS3km',
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.add_a_photo,
                  color: theme.colorScheme.primary,
                  size: 36,
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Ajouter une photo',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const roles = [
      _RoleItem('pere', 'Pere', Icons.man),
      _RoleItem('mere', 'Mere', Icons.woman),
      _RoleItem('enfant', 'Enfant', Icons.child_care),
      _RoleItem('grand_parent', 'Grand-parent', Icons.elderly),
      _RoleItem('autre', 'Autre', Icons.group),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Position',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E5B7A),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: roles.map((role) {
            final isActive = value == role.value;
            final color =
                isActive ? theme.colorScheme.primary : Colors.grey.shade500;

            return GestureDetector(
              onTap: () => onChanged(role.value),
              child: Container(
                width: role.value == 'autre'
                    ? MediaQuery.of(context).size.width - 72
                    : (MediaQuery.of(context).size.width - 72) / 3,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? theme.colorScheme.primary
                        : const Color(0xFFE1DCE8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(role.icon, color: color, size: 30),
                    const SizedBox(height: 6),
                    Text(
                      role.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RoleItem {
  const _RoleItem(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;
}
