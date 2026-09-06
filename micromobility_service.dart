/// Agrégateur de vélos/trottinettes en libre-service — Malmö by bike,
/// Voi, Bolt.
///
/// CORRECTION IMPORTANTE par rapport à ce qui avait été dit plus tôt
/// dans le projet : GBFS n'est PAS un accès public libre pour ces
/// opérateurs à Malmö, contrairement à ce qu'on pensait.
/// - Voi publie du GBFS via son API MDS (mds.voiapp.io), mais elle
///   demande une authentification OAuth avec des identifiants par zone
///   — donc un accord commercial avec Voi, pas un accès public.
/// - Bolt a un point d'accès équivalent (mds.bolt.eu/gbfs/1),
///   probablement avec la même contrainte.
/// - Aucun flux GBFS public confirmé pour Malmö by bike (système
///   propriétaire, pas listé dans le registre GBFS officiel).
///
/// Cette intégration relève donc de la piste B2B (accords avec les
/// loueurs) identifiée dans la note de synthèse — pas d'un simple
/// branchement technique gratuit. Ce fichier définit la structure de
/// données et une implémentation qui accepte une URL de flux GBFS
/// authentifié une fois qu'un accord existe ; sans ça, utilise
/// `MicromobilityService.mock()` pour continuer à développer l'écran.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

class VehicleResult {
  final String id;
  final String provider; // 'malmo_by_bike', 'voi', 'bolt'
  final String vehicleType; // 'bicycle' ou 'scooter'
  final double latitude;
  final double longitude;
  final int? batteryPercent; // null pour les vélos non électriques

  VehicleResult({
    required this.id,
    required this.provider,
    required this.vehicleType,
    required this.latitude,
    required this.longitude,
    this.batteryPercent,
  });
}

class MicromobilityService {
  /// gbfsUrl : le flux `free_bike_status` (ou `vehicle_status` en GBFS
  /// v3) déjà authentifié pour ta zone, une fois l'accord obtenu avec
  /// l'opérateur. bearerToken : requis pour Voi/Bolt (voir doc
  /// ci-dessus) — laisse null si le flux est réellement public.
  final Map<String, ({String gbfsUrl, String? bearerToken})> _sources;

  MicromobilityService(this._sources);

  /// Version sans accord partenaire, pour développer/tester l'écran
  /// sans dépendre de credentials qu'on n'a pas encore.
  factory MicromobilityService.mock() => MicromobilityService({});

  Future<List<VehicleResult>> fetchNearby(String provider) async {
    final source = _sources[provider];
    if (source == null) {
      // Pas de flux configuré pour ce fournisseur (accord pas encore
      // en place) — on renvoie une liste vide plutôt qu'une exception,
      // pour que l'UI puisse afficher "pas encore disponible" au lieu
      // de planter.
      return [];
    }

    final headers = <String, String>{
      if (source.bearerToken != null) 'Authorization': 'Bearer ${source.bearerToken}',
    };

    final response = await http.get(Uri.parse(source.gbfsUrl), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('$provider a répondu ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final bikes = (data['data']?['bikes'] as List<dynamic>? ?? []);

    return bikes.map((b) {
      return VehicleResult(
        id: b['bike_id'] ?? b['vehicle_id'] ?? '',
        provider: provider,
        vehicleType: b['vehicle_type_id'] ?? 'bicycle',
        latitude: (b['lat'] as num).toDouble(),
        longitude: (b['lon'] as num).toDouble(),
        batteryPercent: b['current_fuel_percent'] != null
            ? ((b['current_fuel_percent'] as num) * 100).round()
            : null,
      );
    }).toList();
  }
}
