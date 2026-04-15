import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'welcome_screen.dart';
import 'workout_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _healthFamily = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WorkoutHomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connexion echouee: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF27F0D);
    const lightBg = Color(0xFFF8F7F5);

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 250,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(242, 127, 13, 0.1),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 8,
                    top: 8,
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: const Color(0xFF27272A),
                    ),
                  ),
                  Positioned(
                    top: -32,
                    right: -34,
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(242, 127, 13, 0.28),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -26,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(242, 127, 13, 0.24),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(242, 127, 13, 0.35),
                              blurRadius: 18,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bienvenue',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF27272A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Pret pour l'entrainement ?",
                        style: TextStyle(
                          color: Color(0xFF71717A),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Email'),
                      const SizedBox(height: 6),
                      _InputShell(
                        icon: Icons.person_outline,
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            hintText: 'votre.email@exemple.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) {
                              return 'Email requis';
                            }
                            if (!input.contains('@')) {
                              return 'Entrez l email utilise dans l application mere';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Mot de passe'),
                      const SizedBox(height: 6),
                      _InputShell(
                        icon: Icons.lock_open,
                        trailing: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFFA1A1AA),
                          ),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(hintText: '********'),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Champ requis';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _healthFamily = !_healthFamily),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _healthFamily ? primary : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color:
                                          _healthFamily ? primary : const Color(0x66F27F0D),
                                      width: 2,
                                    ),
                                  ),
                                  child: _healthFamily
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Sante Famille',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF71717A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reset mot de passe a brancher.'),
                                ),
                              );
                            },
                            child: const Text(
                              'Mot de passe oublie ?',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            shadowColor: const Color.fromRGBO(242, 127, 13, 0.34),
                          ),
                          child: Text(
                            _loading ? 'Connexion...' : 'Commencer',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
  
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF52525B),
        ),
      ),
    );
  }
}

class _InputShell extends StatelessWidget {
  const _InputShell({
    required this.child,
    required this.icon,
    this.trailing,
  });

  final Widget child;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromRGBO(242, 127, 13, 0.16), width: 2),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: const Color.fromRGBO(242, 127, 13, 0.62), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                  hintStyle: TextStyle(color: Color(0xFFA1A1AA)),
                ),
              ),
              child: child,
            ),
          ),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 4),
          ] else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}
