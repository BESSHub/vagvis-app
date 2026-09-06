import 'package:flutter/material.dart';
import '../services/app_strings.dart';
import '../services/micromobility_service.dart';
import '../theme/app_theme.dart';

/// Écran agrégateur vélos/trottinettes. Voir micromobility_service.dart
/// pour la correction importante : ça suppose des accords partenaires
/// avec Voi/Bolt (identifiants OAuth par zone) qui n'existent pas
/// encore. Tant que _service n'a pas de source configurée pour un
/// fournisseur, cet écran l'affiche comme "pas encore disponible" au
/// lieu de prétendre avoir une donnée qu'on n'a pas.
class MicromobilityScreen extends StatefulWidget {
  const MicromobilityScreen({super.key});

  @override
  State<MicromobilityScreen> createState() => _MicromobilityScreenState();
}

class _MicromobilityScreenState extends State<MicromobilityScreen> {
  // .mock() tant qu'aucun accord partenaire n'est signé — remplace par
  // de vraies sources (URL + token) une fois les accords en place.
  final _service = MicromobilityService.mock();

  static const _providers = [
    ('malmo_by_bike', 'Malmö by bike', Icons.pedal_bike, AppColors.cyclingGreenDark),
    ('voi', 'Voi', Icons.electric_scooter, Color(0xFF72243E)),
    ('bolt', 'Bolt', Icons.electric_scooter, Color(0xFF3C3489)),
  ];

  final Map<String, List<VehicleResult>> _results = {};
  final Map<String, bool> _loading = {};

  @override
  void initState() {
    super.initState();
    for (final (id, _, __, ___) in _providers) {
      _fetch(id);
    }
  }

  Future<void> _fetch(String provider) async {
    setState(() => _loading[provider] = true);
    try {
      final vehicles = await _service.fetchNearby(provider);
      if (mounted) setState(() => _results[provider] = vehicles);
    } catch (_) {
      if (mounted) setState(() => _results[provider] = []);
    } finally {
      if (mounted) setState(() => _loading[provider] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: ValueListenableBuilder<String>(
          valueListenable: AppStrings.locale,
          builder: (context, _, __) => Text(AppStrings.t('micromobility_title')),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final (id, label, icon, color) in _providers)
            _ProviderSection(
              label: label,
              icon: icon,
              color: color,
              loading: _loading[id] ?? true,
              vehicles: _results[id] ?? [],
            ),
        ],
      ),
    );
  }
}

class _ProviderSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final List<VehicleResult> vehicles;

  const _ProviderSection({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.vehicles,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<String>(
                    valueListenable: AppStrings.locale,
                    builder: (context, _, __) => Text(
                      loading ? AppStrings.t('micromobility_searching') : _statusText(),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText() {
    if (vehicles.isEmpty) {
      // Message honnête : soit personne à proximité, soit (le plus
      // probable pour l'instant) aucun accord partenaire configuré.
      return AppStrings.t('micromobility_unavailable');
    }
    return '${vehicles.length} ${AppStrings.t('micromobility_count_nearby')}';
  }
}
