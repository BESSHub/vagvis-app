import 'dart:convert';
import 'package:http/http.dart' as http;

/// Récupère les pistes cyclables et zones piétonnes depuis OpenStreetMap
/// via Overpass, pour une zone rectangulaire donnée, et les convertit en
/// GeoJSON directement utilisable par un GeoJsonSource de Mapbox.
///
/// ATTENTION — vu en revue avec le reste du projet Vägvis : Overpass est
/// un service public à usage raisonnable, pas fait pour être interrogé à
/// chaque ouverture d'écran par chaque utilisateur en prod. Ce service
/// est correct pour prototyper, mais avant la mise en production il faut
/// mettre en cache le résultat côté serveur (import périodique dans ta
/// propre base, ex. PostGIS) plutôt que d'appeler Overpass en direct
/// depuis l'app.
class OsmLayerService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// bbox : [sud, ouest, nord, est] (latitude/longitude), ex. Malmö centre.
  Future<String> fetchCyclingLanesGeoJson(List<double> bbox) {
    return _fetchWaysAsGeoJson(bbox, 'highway=cycleway');
  }

  Future<String> fetchPedestrianWaysGeoJson(List<double> bbox) {
    return _fetchWaysAsGeoJson(bbox, 'highway~"^(pedestrian|footway)\$"');
  }

  Future<String> _fetchWaysAsGeoJson(List<double> bbox, String filter) async {
    final bboxStr = bbox.join(',');
    final query = '''
      [out:json][timeout:25];
      (
        way[$filter]($bboxStr);
      );
      out geom;
    ''';

    final response = await http.post(
      Uri.parse(_endpoint),
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      throw Exception('Overpass a répondu ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List<dynamic>? ?? []);

    final features = elements.where((el) => el['geometry'] != null).map((el) {
      final geometry = el['geometry'] as List<dynamic>;
      final coordinates = geometry
          .map((pt) => [pt['lon'], pt['lat']])
          .toList();
      return {
        'type': 'Feature',
        'geometry': {'type': 'LineString', 'coordinates': coordinates},
        'properties': {'id': el['id']},
      };
    }).toList();

    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }
}
