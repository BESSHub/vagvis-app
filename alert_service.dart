import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/alert_model.dart';

class AlertService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> sendAlert({
    required String alertType,
    required double lat,
    required double lng,
    String? lineNumber,
    String? stopAreaName,
    String? message,
  }) async {
    await _client.from('alerts').insert({
      'alert_type': alertType,
      'location': 'POINT($lng $lat)',
      'line_number': lineNumber,
      'stop_area_name': stopAreaName,
      'message': message,
    });
  }

  Future<List<SkaneAlertModel>> fetchNearbyAlerts(double lat, double lng) async {
    final response = await _client.rpc('get_nearby_alerts', params: {
      'user_lat': lat,
      'user_lng': lng,
      'radius_meters': 3000,
    });

    final List<dynamic> data = response as List<dynamic>;
    return data.map((item) => SkaneAlertModel.fromJson(item)).toList();
  }

  /// value = 1 pour "Bekräfta", -1 pour "Inte längre aktuellt".
  Future<void> voteAlert({
    required String alertId,
    required String userId,
    required int value,
  }) async {
    assert(value == 1 || value == -1, 'value doit être 1 ou -1');
    await _client.rpc('vote_alert', params: {
      'p_alert_id': alertId,
      'p_user_id': userId,
      'p_vote_value': value,
    });
  }
}
