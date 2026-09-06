import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final String name;
  final String? fullAddress;
  final double longitude;
  final double latitude;

  GeocodingResult({
    required this.name,
    this.fullAddress,
    required this.longitude,
    required this.latitude,
  });
}

/// Recherche de lieux via l'API Mapbox Geocoding v6 (forward geocoding).
///
/// À VÉRIFIER avant de t'y fier : la structure exacte des champs
/// `properties` (name, full_address, place_formatted...) est reprise de
/// la documentation et d'exemples publics de la v6, mais je n'ai pas pu
/// récupérer une vraie réponse JSON pour la confirmer telle quelle dans
/// cet environnement (pas d'accès réseau depuis le bash ici, et la page
/// de doc Mapbox est rendue en JavaScript). Fais un test manuel avec ton
/// token avant de t'appuyer dessus en prod — voir la commande curl en
/// commentaire plus bas.
///
/// Limite connue : la Geocoding API v6 ne renvoie plus les points
/// d'intérêt (POI) — restaurants, commerces, etc. Pour ça, Mapbox
/// recommande sa Search Box API séparée. Les places/adresses/quartiers
/// (comme "Möllevångstorget") restent couvertes par v6.
class GeocodingService {
  static const _endpoint = 'https://api.mapbox.com/search/geocode/v6/forward';

  final String accessToken;
  GeocodingService({required this.accessToken});

  // Exemple pour tester manuellement :
  // curl "https://api.mapbox.com/search/geocode/v6/forward?q=M%C3%B6llev%C3%A5ngstorget&proximity=13.0,55.6&access_token=TON_TOKEN"
  Future<List<GeocodingResult>> search(
    String query, {
    List<double>? proximity, // [lon, lat] pour biaiser vers une zone (ex. Skåne)
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) return [];

    final params = {
      'q': query,
      'access_token': accessToken,
      'autocomplete': 'true',
      'limit': '$limit',
      'language': 'sv',
      if (proximity != null) 'proximity': '${proximity[0]},${proximity[1]}',
    };

    final uri = Uri.parse(_endpoint).replace(queryParameters: params);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Mapbox Geocoding a répondu ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final features = (data['features'] as List<dynamic>? ?? []);

    return features.map((f) {
      final props = f['properties'] as Map<String, dynamic>;
      final coords = (f['geometry']['coordinates'] as List<dynamic>);
      return GeocodingResult(
        name: props['name'] ?? query,
        fullAddress: props['full_address'] ?? props['place_formatted'],
        longitude: (coords[0] as num).toDouble(),
        latitude: (coords[1] as num).toDouble(),
      );
    }).toList();
  }
}
