import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectionsRouteResult {
  final double distanceMeters;
  final double durationSeconds;
  final List<List<double>> geometry; // [ [lon, lat], ... ]

  DirectionsRouteResult({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
  });

  String get formattedDistance => '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  String get formattedDuration => '${(durationSeconds / 60).round()} min';
}

/// Appelle l'API REST Mapbox Directions (v5) — pas le SDK de navigation
/// turn-by-turn, juste le calcul d'itinéraire brut (distance, durée, tracé).
///
/// LIMITE IMPORTANTE À GARDER EN TÊTE : cette API calcule le meilleur
/// itinéraire selon le réseau routier standard. Elle ne sait pas
/// distinguer une piste cyclable séparée d'une bande peinte, et elle
/// n'a aucune notion du vent. Les options "la plus sûre" et "la moins
/// de vent" de la maquette ne peuvent donc PAS venir directement de
/// cette API telle quelle — il faudrait soit un profil de routage
/// personnalisé (OSRM avec une pondération sur les tags OSM de
/// séparation cycliste), soit un post-traitement qui croise le tracé
/// renvoyé ici avec les données OSM et météo. Pour l'instant, ce
/// service renvoie simplement les alternatives que Mapbox propose,
/// affichées de façon neutre plutôt que ré-étiquetées à tort.
class DirectionsService {
  static const _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';

  final String accessToken;
  DirectionsService({required this.accessToken});

  /// profile : 'cycling', 'walking', ou 'driving'.
  Future<List<DirectionsRouteResult>> fetchRoutes({
    required List<double> origin, // [lon, lat]
    required List<double> destination, // [lon, lat]
    required String profile,
  }) async {
    final coords = '${origin[0]},${origin[1]};${destination[0]},${destination[1]}';
    final uri = Uri.parse(
      '$_baseUrl/$profile/$coords'
      '?geometries=geojson&overview=full&alternatives=true&access_token=$accessToken',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Mapbox Directions a répondu ${response.statusCode} : ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code'] != 'Ok') {
      throw Exception('Mapbox Directions : ${data['code']} — ${data['message'] ?? ''}');
    }

    final routes = (data['routes'] as List<dynamic>);
    return routes.map((r) {
      final geometry = (r['geometry']['coordinates'] as List<dynamic>)
          .map<List<double>>((pt) => [pt[0] as double, pt[1] as double])
          .toList();
      return DirectionsRouteResult(
        distanceMeters: (r['distance'] as num).toDouble(),
        durationSeconds: (r['duration'] as num).toDouble(),
        geometry: geometry,
      );
    }).toList();
  }
}
