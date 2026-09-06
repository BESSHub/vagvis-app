import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';
import '../services/app_strings.dart';
import '../services/osm_layer_service.dart';
import '../theme/app_theme.dart';
import 'micromobility_screen.dart';
import 'newcomer_services_screen.dart';
import 'route_search_screen.dart';
import 'station_entrance_screen.dart';

/// Écran carte principal. Centré par défaut sur Malmö.
///
/// NB : n'a pas été compilé ni testé dans cet environnement (pas de
/// Flutter/réseau ici). Vérifie avec `flutter analyze` et un vrai
/// token Mapbox avant de t'y fier. L'API mapbox_maps_flutter évolue
/// vite d'une version à l'autre — si `flutter pub get` récupère une
/// version différente de celle du pubspec.yaml, certains noms
/// (styleUri, CameraOptions, Position) peuvent avoir changé de forme.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;
  final AlertService _alertService = AlertService();
  final OsmLayerService _osmLayerService = OsmLayerService();

  static const _malmoCenter = Position(13.0038, 55.6050);
  // Zone approximative couvrant le centre de Malmö — à remplacer par les
  // bornes réelles de la caméra une fois l'écran zoomable/déplaçable géré.
  static const _malmoBbox = [55.55, 12.93, 55.65, 13.08]; // [sud, ouest, nord, est]

  List<SkaneAlertModel> _nearbyAlerts = [];
  bool _loadingAlerts = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyAlerts();
  }

  Future<void> _loadNearbyAlerts() async {
    setState(() => _loadingAlerts = true);
    try {
      final position = await _currentPositionOrDefault();
      final alerts = await _alertService.fetchNearbyAlerts(
        position.latitude,
        position.longitude,
      );
      if (mounted) setState(() => _nearbyAlerts = alerts);
    } catch (_) {
      // En prod : afficher un message discret plutôt que de rester muet.
      // Laissé volontairement simple ici.
    } finally {
      if (mounted) setState(() => _loadingAlerts = false);
    }
  }

  Future<Position> _currentPositionOrDefault() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return _malmoCenter;
        }
      }
      final pos = await Geolocator.getCurrentPosition();
      return Position(pos.longitude, pos.latitude);
    } catch (_) {
      return _malmoCenter;
    }
  }

  void _onMapCreated(MapboxMap controller) {
    _mapboxMap = controller;
    // Puck de localisation — équivalent du point bleu sur la maquette.
    _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  bool _osmLayersAdded = false;

  /// Appelé une fois le style entièrement chargé — ajouter des sources/
  /// layers dans onMapCreated est signalé comme peu fiable par endroits
  /// (voir commentaire dans osm_layer_service.dart et le README), donc on
  /// attend onStyleLoadedListener plutôt que de le faire dans onMapCreated.
  /// Protégé par _osmLayersAdded : ce callback peut se redéclencher (hot
  /// reload, changement de style), et Mapbox lève une exception si on
  /// tente d'ajouter une source dont l'ID existe déjà.
  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final map = _mapboxMap;
    if (map == null || _osmLayersAdded) return;
    _osmLayersAdded = true;

    try {
      final cyclingGeoJson = await _osmLayerService.fetchCyclingLanesGeoJson(_malmoBbox);
      await map.style.addSource(GeoJsonSource(id: 'cycling-lanes', data: cyclingGeoJson));
      await map.style.addLayer(LineLayer(
        id: 'cycling-lanes-layer',
        sourceId: 'cycling-lanes',
        lineJoin: LineJoin.ROUND,
        lineCap: LineCap.ROUND,
        lineColor: AppColors.cyclingGreen.value,
        lineWidth: 3.0,
      ));

      final pedestrianGeoJson = await _osmLayerService.fetchPedestrianWaysGeoJson(_malmoBbox);
      await map.style.addSource(GeoJsonSource(id: 'pedestrian-ways', data: pedestrianGeoJson));
      await map.style.addLayer(LineLayer(
        id: 'pedestrian-ways-layer',
        sourceId: 'pedestrian-ways',
        lineJoin: LineJoin.ROUND,
        lineCap: LineCap.ROUND,
        lineColor: AppColors.pedestrianBlue.value,
        lineWidth: 2.0,
        lineDasharray: [1.0, 2.0],
      ));
    } catch (e) {
      // À remplacer par un vrai log / message discret en prod.
      debugPrint('Échec du chargement des calques OSM : $e');
    }
  }

  Future<void> _recenter() async {
    final position = await _currentPositionOrDefault();
    _mapboxMap?.setCamera(
      CameraOptions(center: Point(coordinates: position), zoom: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('vagvis_map'),
            styleUri: MapboxStyles.DARK,
            cameraOptions: CameraOptions(
              center: Point(coordinates: _malmoCenter),
              zoom: 13,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
          ),

          // Barre de recherche, superposée en haut — reprend la maquette.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RouteSearchScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.chip,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<String>(
                              valueListenable: AppStrings.locale,
                              builder: (context, _, __) => Text(
                                AppStrings.t('search_hint'),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoundIconButton(
                    icon: Icons.menu,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NewcomerServicesScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Accès rapide à la fiche d'entrée de Malmö C — le vrai
          // comportement (taper directement un repère de gare sur la
          // carte) demande un PointAnnotationManager avec gestion du
          // tap, plus complexe à câbler ; ce chip sert de raccourci en
          // attendant.
          Positioned(
            top: 70,
            left: 14,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StationEntranceScreen(stationId: 'malmo_c')),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.train, size: 13, color: AppColors.pedestrianBlue),
                      SizedBox(width: 5),
                      Text('Malmö C', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            right: 12,
            bottom: 220,
            child: Column(
              children: [
                _RoundIconButton(
                  icon: Icons.electric_scooter,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MicromobilityScreen()),
                  ),
                ),
                const SizedBox(height: 8),
                _RoundIconButton(icon: Icons.my_location, onTap: _recenter),
              ],
            ),
          ),

          // Fiche du bas — alertes communautaires à proximité.
          DraggableScrollableSheet(
            initialChildSize: 0.28,
            minChildSize: 0.14,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  children: [
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (_loadingAlerts)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(color: AppColors.cyclingGreen)),
                      )
                    else if (_nearbyAlerts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Inga rapporter i närheten just nu', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      )
                    else
                      for (final alert in _nearbyAlerts) _AlertTile(alert: alert),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.chip,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final SkaneAlertModel alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.alertAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.message ?? alert.alertType, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${alert.upvotes} bekräftelser', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
