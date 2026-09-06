import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class WeatherConditions {
  final double airTemperatureC;
  final double windSpeedMs;
  final double feelsLikeC;

  WeatherConditions({
    required this.airTemperatureC,
    required this.windSpeedMs,
    required this.feelsLikeC,
  });

  double get windSpeedKmh => windSpeedMs * 3.6;
}

/// Météo via l'API ouverte de SMHI (institut météo suédois).
///
/// ATTENTION — SMHI a supprimé son ancienne API (catégorie `pmp3g`) le
/// 31 mars 2026 ; elle renvoie un 404 depuis. Ce service utilise le
/// nouvel endpoint (`snow1g`), dont la structure de données est plate
/// (`data.air_temperature` au lieu d'un tableau `parameters`). Vérifié
/// via recherche au moment d'écrire ce fichier, mais n'a pas pu être
/// testé avec un vrai appel réseau dans cet environnement — confirme
/// avec un `curl` avant de t'y fier :
/// curl "https://opendata-download-metfcst.smhi.se/api/category/snow1g/version/1/geotype/point/lon/13.19/lat/55.60/data.json"
class WeatherService {
  static const _endpoint =
      'https://opendata-download-metfcst.smhi.se/api/category/snow1g/version/1/geotype/point';

  /// SMHI utilise 9999 comme valeur "manquante" — à filtrer, pas à
  /// afficher tel quel.
  static const _missingValueSentinel = 9999.0;

  Future<WeatherConditions> fetchCurrentConditions({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse('$_endpoint/lon/$lon/lat/$lat/data.json');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('SMHI a répondu ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final timeSeries = data['timeSeries'] as List<dynamic>;
    if (timeSeries.isEmpty) {
      throw Exception('SMHI : aucune prévision renvoyée pour ce point');
    }

    // Le premier élément correspond à l'échéance la plus proche.
    final current = (timeSeries.first as Map<String, dynamic>)['data'] as Map<String, dynamic>;

    final temp = _readValue(current, 'air_temperature');
    final windSpeed = _readValue(current, 'wind_speed');

    if (temp == null || windSpeed == null) {
      throw Exception('SMHI : température ou vent manquant dans la réponse');
    }

    return WeatherConditions(
      airTemperatureC: temp,
      windSpeedMs: windSpeed,
      feelsLikeC: _windChill(temp, windSpeed * 3.6),
    );
  }

  double? _readValue(Map<String, dynamic> data, String key) {
    final raw = data[key];
    if (raw == null) return null;
    final value = (raw as num).toDouble();
    return value == _missingValueSentinel ? null : value;
  }

  /// Formule de refroidissement éolien (JAG/TI 2001), valable pour une
  /// température <= 10°C et un vent > 4.8 km/h — sinon la température
  /// ressentie est simplement la température de l'air.
  double _windChill(double tempC, double windKmh) {
    if (tempC > 10 || windKmh <= 4.8) return tempC;
    final v016 = math.pow(windKmh, 0.16).toDouble();
    return 13.12 + 0.6215 * tempC - 11.37 * v016 + 0.3965 * tempC * v016;
  }
}
