import 'package:flutter/material.dart';
import '../services/directions_service.dart';
import '../services/app_strings.dart';
import '../services/geocoding_service.dart';
import '../services/impact_calculator.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import 'place_search_screen.dart';

/// Écran de recherche d'itinéraire — champs de recherche réels (Mapbox
/// Geocoding v6), calcul d'itinéraire réel (Mapbox Directions v5), et
/// météo réelle (SMHI) en bandeau (fusion décidée dans la note de
/// synthèse).
///
/// CE QUI RESTE À FAIRE (voir README) :
/// - Les options renvoyées par Mapbox sont neutres ("Alternativ 1/2"),
///   PAS étiquetées "plus sûre" ou "moins de vent" — voir le commentaire
///   dans directions_service.dart.
/// - La température ressentie est calculée pour le point de départ
///   uniquement, pas le long de tout le trajet.
/// - Les champs de géocodage et l'appel météo n'ont pas été testés avec
///   un vrai token / réseau — voir les commentaires dans
///   geocoding_service.dart et weather_service.dart.
class RouteSearchScreen extends StatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

enum TravelMode { cycling, walking, transit }

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  TravelMode _mode = TravelMode.cycling;

  // Biaise les résultats de recherche vers le centre du Skåne.
  static const _skaneProximity = [13.19, 55.70];

  // Valeurs de départ, en attendant que l'utilisateur ne cherche autre
  // chose — Möllevångstorget (Malmö) -> Lund C.
  GeocodingResult? _origin = GeocodingResult(name: 'Möllevångstorget', longitude: 13.0067, latitude: 55.5895);
  GeocodingResult? _destination = GeocodingResult(name: 'Lund C', longitude: 13.1874, latitude: 55.7047);

  final _directionsService = DirectionsService(
    accessToken: const String.fromEnvironment('MAPBOX_TOKEN', defaultValue: 'YOUR_MAPBOX_TOKEN'),
  );
  final _weatherService = WeatherService();

  List<DirectionsRouteResult> _routes = [];
  bool _loading = false;
  String? _error;

  WeatherConditions? _weather;

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (_origin == null) return;
    try {
      final weather = await _weatherService.fetchCurrentConditions(
        lat: _origin!.latitude,
        lon: _origin!.longitude,
      );
      if (mounted) setState(() => _weather = weather);
    } catch (_) {
      // Bandeau simplement masqué si la météo échoue — pas d'erreur
      // bloquante pour une info secondaire.
      if (mounted) setState(() => _weather = null);
    }
  }

  Future<void> _pickPlace({required bool isOrigin}) async {
    final result = await Navigator.of(context).push<GeocodingResult>(
      MaterialPageRoute(
        builder: (_) => PlaceSearchScreen(
          title: isOrigin ? 'Varifrån?' : 'Vart?',
          proximity: _skaneProximity,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      if (isOrigin) {
        _origin = result;
      } else {
        _destination = result;
      }
    });
    _fetchRoutes();
    if (isOrigin) _fetchWeather();
  }

  Future<void> _fetchRoutes() async {
    if (_mode == TravelMode.transit) {
      setState(() {
        _routes = [];
        _error = null;
      });
      return;
    }
    if (_origin == null || _destination == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routes = await _directionsService.fetchRoutes(
        origin: [_origin!.longitude, _origin!.latitude],
        destination: [_destination!.longitude, _destination!.latitude],
        profile: _mode == TravelMode.cycling ? 'cycling' : 'walking',
      );
      if (mounted) setState(() => _routes = routes);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setMode(TravelMode mode) {
    setState(() => _mode = mode);
    _fetchRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: ValueListenableBuilder<String>(
          valueListenable: AppStrings.locale,
          builder: (context, _, __) => Text(AppStrings.t('search_trip_title')),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              children: [
                _LocationField(
                  icon: Icons.my_location,
                  iconColor: AppColors.cyclingGreen,
                  label: _origin?.name ?? 'Varifrån?',
                  onTap: () => _pickPlace(isOrigin: true),
                ),
                const SizedBox(height: 6),
                _LocationField(
                  icon: Icons.place,
                  iconColor: AppColors.alertAmber,
                  label: _destination?.name ?? 'Vart?',
                  onTap: () => _pickPlace(isOrigin: false),
                ),
              ],
            ),
          ),

          if (_mode == TravelMode.cycling && _weather != null) _WeatherBanner(weather: _weather!),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: ValueListenableBuilder<String>(
              valueListenable: AppStrings.locale,
              builder: (context, _, __) => Row(
                children: [
                  _ModeChip(label: AppStrings.t('mode_cycling'), selected: _mode == TravelMode.cycling, onTap: () => _setMode(TravelMode.cycling)),
                  const SizedBox(width: 6),
                  _ModeChip(label: AppStrings.t('mode_walking'), selected: _mode == TravelMode.walking, onTap: () => _setMode(TravelMode.walking)),
                  const SizedBox(width: 6),
                  _ModeChip(label: AppStrings.t('mode_transit'), selected: _mode == TravelMode.transit, onTap: () => _setMode(TravelMode.transit)),
                ],
              ),
            ),
          ),

          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_mode == TravelMode.transit) {
      return const Center(
        child: Text('Pas encore branché — Trafiklab (GTFS-RT)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.cyclingGreen));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.alertAmber, size: 28),
            const SizedBox(height: 10),
            Text(
              'Impossible de calculer l\'itinéraire.\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vérifie que MAPBOX_TOKEN est bien défini (--dart-define).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }
    if (_routes.isEmpty) {
      return const Center(
        child: Text('Aucun itinéraire trouvé', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      children: [
        for (int i = 0; i < _routes.length; i++)
          _RouteResultCard(route: _routes[i], isRecommended: i == 0, label: i == 0 ? 'Snabbaste vägen' : 'Alternativ ${i + 1}'),
      ],
    );
  }
}

class _LocationField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _LocationField({required this.icon, required this.iconColor, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5))),
            const Icon(Icons.search, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _WeatherBanner extends StatelessWidget {
  final WeatherConditions weather;
  const _WeatherBanner({required this.weather});

  @override
  Widget build(BuildContext context) {
    final feelsLike = weather.feelsLikeC.round();
    final windKmh = weather.windSpeedKmh.round();
    final isWindy = windKmh >= 25;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(Icons.air, size: 16, color: isWindy ? AppColors.alertAmber : AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Känns som $feelsLike°, vind $windKmh km/h',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyclingGreen : AppColors.chip,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, color: selected ? const Color(0xFF04342C) : AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _RouteResultCard extends StatelessWidget {
  final DirectionsRouteResult route;
  final bool isRecommended;
  final String label;
  const _RouteResultCard({required this.route, required this.isRecommended, required this.label});

  @override
  Widget build(BuildContext context) {
    final co2 = ImpactCalculator.co2SavedKg(route.distanceMeters);
    final money = ImpactCalculator.moneySavedSek(route.distanceMeters);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: isRecommended ? Border.all(color: AppColors.cyclingGreen) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(route.formattedDuration, style: TextStyle(color: isRecommended ? AppColors.cyclingGreen : AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(route.formattedDistance, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.eco_outlined, size: 13, color: AppColors.cyclingGreen),
              const SizedBox(width: 4),
              Text(
                '${co2.toStringAsFixed(1)} kg CO₂ · ${money.toStringAsFixed(0)} kr sparat vs bil',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
