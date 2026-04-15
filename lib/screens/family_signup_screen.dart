import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class FamilySignUpScreen extends StatefulWidget {
  const FamilySignUpScreen({super.key});

  @override
  State<FamilySignUpScreen> createState() => _FamilySignUpScreenState();
}

class _FamilySignUpScreenState extends State<FamilySignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _familyIdController = TextEditingController();
  final _random = Random();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  String? _familyId;

  @override
  void dispose() {
    _fullNameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _familyNameController.dispose();
    _familyIdController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _familyNameController.addListener(_syncFamilyId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_familyIdController.text.isEmpty &&
        _familyNameController.text.trim().isNotEmpty) {
      _syncFamilyId();
    }
  }

  void _syncFamilyId() {
    final name = _familyNameController.text.trim();
    if (name.isEmpty) {
      _familyIdController.text = '';
      return;
    }

    final base = _slugify(name);
    final suffix = _randomSuffix();
    _setFamilyIdText('${base}_$suffix');
  }

  String _slugify(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    if (cleaned.isEmpty) {
      return 'Famille';
    }

    return cleaned.substring(0, min(cleaned.length, 16));
  }

  String _randomSuffix() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(4, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  void _setFamilyIdText(String value) {
    _familyIdController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _createFamilyAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_acceptTerms) {
      _showMessage('Veuillez accepter les conditions.');
      return;
    }

    setState(() {
      _isLoading = true;
      _familyId = null;
    });

    try {
      debugPrint('Signup: start');
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();
      final role = _roleController.text.trim();
      final familyName = _familyNameController.text.trim();
      final familyId = _familyIdController.text.trim();

      debugPrint('Signup: email=$email familyId=$familyId');

      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user ?? supabase.auth.currentUser;
      debugPrint('Signup: user=${user?.id}');
      if (user == null) {
        _showMessage('Compte cree. Confirmez l email pour continuer.');
        return;
      }

      final family = await supabase
          .from('families')
          .insert({
            'family_id': familyId,
            'family_name': familyName,
            'auth_user_id': user.id,
          })
          .select()
          .single();

      debugPrint('Signup: family=${family['id']}');

      await supabase.from('family_members').insert({
        'family_id': family['id'],
        'auth_user_id': user.id,
        'full_name': fullName,
        'role': role,
        'is_admin': true,
      });

      debugPrint('Signup: family_members inserted');

      setState(() {
        _familyId = family['id']?.toString();
      });

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      debugPrint('Signup: auth error ${e.message}');
      _showMessage('Erreur auth: ${e.message}');
    } on PostgrestException catch (e) {
      debugPrint('Signup: db error ${e.message}');
      _showMessage('Erreur DB: ${e.message}');
    } catch (e) {
      debugPrint('Signup: unknown error $e');
      _showMessage('Erreur inconnue: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAuhMIlckRaBQ_PNfFQZeMEG2R72Lq9GrNqXhjgsED1QGefDJv5ulIn8kp9P7lwHj6y_skrGyuBecqwODtGog5pVWoS0RsQhBu0Lf_JgDgBL-4y0Wh6d-B-SyRU-R5-SPtnE1ZUt5x9Tz1Ih-a14KC6nw1LPVnqvfH5vdR-m2Pj7xRpZJTq--umr_GW7zd-PyzThRPgjYRfPfxkJaxG754uUHjhW39A_Lre07bhUIquC761ETCuOQ8R_mrqvIRJ7jMr6RQVuX5H_wj3',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99191022),
                    Color(0xE6191022),
                    Color(0xFF191022),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_ios_new,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.4),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.family_restroom,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text.rich(
                    TextSpan(
                      text: 'Creer un compte\n',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: 'famille',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Commencez votre parcours bien-etre ensemble.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _LabeledField(
                          label: 'Nom complet',
                          child: TextFormField(
                            controller: _fullNameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Jean Dupont',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nom requis';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'Position',
                          child: DropdownButtonFormField<String>(
                            initialValue: _roleController.text.isEmpty
                                ? null
                                : _roleController.text,
                            icon: const Icon(Icons.expand_more),
                            decoration: const InputDecoration(
                              hintText: 'Selectionnez votre role',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pere',
                                child: Text('Pere'),
                              ),
                              DropdownMenuItem(
                                value: 'mere',
                                child: Text('Mere'),
                              ),
                              DropdownMenuItem(
                                value: 'autre',
                                child: Text('Autre'),
                              ),
                            ],
                            onChanged: (value) {
                              _roleController.text = value ?? '';
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selection requise';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'Nom de la famille',
                          child: TextFormField(
                            controller: _familyNameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Famille Dupont',
                            ),
                            onChanged: (_) => _syncFamilyId(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nom requis';
                              }
                              if (value.trim().length < 2) {
                                return 'Nom trop court';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'Identifiant famille',
                          child: TextFormField(
                            controller: _familyIdController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Dupont_7F3K',
                              helperText: 'Genere automatiquement',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Identifiant requis';
                              }
                              if (value.trim().length < 4) {
                                return 'Identifiant trop court';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'Email',
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'email@exemple.com',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email requis';
                              }
                              if (!value.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'Mot de passe',
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Mot de passe requis';
                              }
                              if (value.length < 6) {
                                return 'Min 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'Confirmer le mot de passe',
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirm = !_obscureConfirm;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirmation requise';
                              }
                              if (value != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    height: 1.4,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text:
                                          'En creant un compte, vous acceptez nos ',
                                    ),
                                    TextSpan(
                                      text: 'Conditions d\'utilisation',
                                      style: TextStyle(
                                        color: Colors.white,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(text: ' et notre '),
                                    TextSpan(
                                      text: 'Politique de confidentialite',
                                      style: TextStyle(
                                        color: Colors.white,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _GlowSubmitButton(
                          label: 'Creer mon compte',
                          onPressed:
                              _isLoading ? null : _createFamilyAccount,
                          isLoading: _isLoading,
                        ),
                        if (_familyId != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Family ID: $_familyId',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        style: theme.textTheme.bodySmall,
                        children: [
                          const TextSpan(text: 'Deja un compte famille ? '),
                          TextSpan(
                            text: 'Se connecter',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Positioned(
            left: -80,
            bottom: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -70,
            top: MediaQuery.of(context).size.height * 0.25,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white10,
          border: Border.all(color: Colors.white10),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 1.2,
                color: AppTheme.muted,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: const Color(0xB3191022),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _GlowSubmitButton extends StatelessWidget {
  const _GlowSubmitButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shadowColor: theme.colorScheme.primary.withOpacity(0.4),
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
