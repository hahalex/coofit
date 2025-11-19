// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple Open-Meteo wrapper: current_weather endpoint
/// doc: https://open-meteo.com/en/docs
class WeatherService {
  /// Returns map: { 'temp': double (°C), 'weathercode': int } or null on error
  static Future<Map<String, dynamic>?> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true';
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final js = json.decode(resp.body);
      final cw = js['current_weather'];
      if (cw == null) return null;
      final temp = (cw['temperature'] as num).toDouble();
      final code = (cw['weathercode'] as int);
      return {'temp': temp, 'weathercode': code};
    } catch (e) {
      return null;
    }
  }

  /// Small helper to map weathercode -> icon name
  static String codeToIcon(int code) {
    // simplified grouping:
    if (code == 0) return 'sun'; // clear
    if (code == 1 || code == 2 || code == 3) return 'cloud';
    if ((code >= 45 && code <= 48) ||
        (code >= 51 && code <= 57) ||
        (code >= 61 && code <= 67) ||
        (code >= 80 && code <= 82)) {
      return 'rain';
    }
    if ((code >= 71 && code <= 79) || (code >= 85 && code <= 86)) return 'snow';
    return 'cloud';
  }
}
