import 'package:flutter/material.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import 'map_screen.dart';

enum AppLanguage { sv, en, fr }

/// Écran de langue de la maquette. Le suédois reste sélectionné par
/// défaut ; noms de rues et infos trafic officielles restent en
/// suédois quel que soit le choix ici (voir note du projet, section 3).
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  AppLanguage _selected = AppLanguage.sv;

  static const _options = [
    (AppLanguage.sv, 'SV', 'Svenska', 'Standard'),
    (AppLanguage.en, 'EN', 'English', null),
    (AppLanguage.fr, 'FR', 'Français', null),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Språk / Language / Langue'),
      ),
      body: ListView(
        children: [
          for (final option in _options)
            ListTile(
              leading: Container(
                width: 28,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selected == option.$1 ? AppColors.cyclingGreenDark : AppColors.chip,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(option.$2, style: const TextStyle(fontSize: 10, color: AppColors.textPrimary)),
              ),
              title: Text(option.$3),
              subtitle: option.$4 != null ? Text(option.$4!) : null,
              trailing: _selected == option.$1
                  ? const Icon(Icons.check, color: AppColors.cyclingGreen, size: 18)
                  : null,
              onTap: () => setState(() {
                _selected = option.$1;
                AppStrings.setLocale(option.$1.name);
              }),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.chip,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: AppStrings.locale,
                builder: (context, _, __) => Text(
                  AppStrings.t('street_names_note'),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                ),
                child: const Text('Fortsätt'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
