import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'family_signup_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66191022),
                    Color(0xCC191022),
                    Color(0xFF191022),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Votre voyage\ncommence ici',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 34,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Equilibrez votre esprit et votre corps avec notre approche personnalisee.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _GlowButton(
                    label: 'Creer un compte',
                    filled: true,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FamilySignUpScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _GlowButton(
                    label: 'Se connecter',
                    filled: false,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodySmall,
                      children: [
                        const TextSpan(text: 'Deja membre ? '),
                        TextSpan(
                          text: 'Acces membre',
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
                  const SizedBox(height: 12),
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
            top: 360,
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

class _GlowButton extends StatelessWidget {
  const _GlowButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = filled ? theme.colorScheme.primary : Colors.white10;
    final borderColor = filled ? Colors.transparent : Colors.white24;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          shadowColor: filled
              ? theme.colorScheme.primary.withOpacity(0.4)
              : Colors.transparent,
          elevation: filled ? 8 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: borderColor),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
