import 'package:flutter/material.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import 'language_screen.dart';

/// Reprend l'écran de bienvenue de la maquette : logo, message d'accueil,
/// bouton principal, et accès direct au changement de langue en dessous
/// pour qu'un utilisateur non-suédophone ne reste pas bloqué.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              _VagvisMark(),
              const SizedBox(height: 20),
              Text('Vägvis', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              ValueListenableBuilder<String>(
                valueListenable: AppStrings.locale,
                builder: (context, _, __) => Text(
                  AppStrings.t('welcome_subtitle'),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LanguageScreen()),
                  ),
                  child: ValueListenableBuilder<String>(
                    valueListenable: AppStrings.locale,
                    builder: (context, _, __) => Text(AppStrings.t('get_started')),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LanguageScreen()),
                ),
                child: ValueListenableBuilder<String>(
                  valueListenable: AppStrings.locale,
                  builder: (context, _, __) => Text(
                    AppStrings.t('change_language'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le logo : un chemin courbe reliant un point de départ (bleu) à une
/// destination (ambre) — cf. l'écran logo validé dans les maquettes.
class _VagvisMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: CustomPaint(painter: _VagvisMarkPainter()),
    );
  }
}

class _VagvisMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.surfaceAlt;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, bg);

    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.15, size.width * 0.78, size.height * 0.42);

    final pathPaint = Paint()
      ..color = AppColors.cyclingGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, pathPaint);

    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.42), 7, Paint()..color = AppColors.alertAmber);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.62), 5, Paint()..color = AppColors.pedestrianBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
