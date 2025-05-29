import 'dart:convert';
import 'package:http/http.dart' as http;

class SensorReading {
  final String sensor; // Ej: "temperature" o "humidity"
  final String value;
  final String timestamp;

  SensorReading({
    required this.sensor,
    required this.value,
    required this.timestamp,
  });

  // Constructor estático para construir desde un valor específico
  factory SensorReading.fromValue({
    required String sensor,
    required dynamic value,
    required String timestamp,
  }) {
    return SensorReading(
      sensor: sensor,
      value: value?.toString() ?? 'N/A',
      timestamp: timestamp,
    );
  }
}


class SensorService {
  static const String _baseUrl =
      'https://list-sensor-readings-712174296076.northamerica-northeast1.run.app/readings';

  static Future<List<SensorReading>> fetchSensorReadings() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data'];

      List<SensorReading> readings = [];

      for (var item in data) {
        final timestamp = item['timestamp'];

        if (item['temperature'] != null) {
          readings.add(SensorReading.fromValue(
              sensor: 'Temperatura',
              value: item['temperature'],
              timestamp: timestamp));
        }

        if (item['humidity'] != null) {
          readings.add(SensorReading.fromValue(
              sensor: 'Humedad',
              value: item['humidity'],
              timestamp: timestamp));
        }
      }

      return readings;
    } else {
      throw Exception('Error al obtener datos del servidor');
    }
  }

  static Future<List<SensorReading>> fetchDummySensorReadings() async {
  await Future.delayed(const Duration(seconds: 1)); // Simula carga
  return [
    SensorReading(sensor: 'Temperatura', value: '32°C', timestamp: '2025-05-24 10:30'),
    SensorReading(sensor: 'Humedad', value: '60%', timestamp: '2025-05-24 10:30'),
    SensorReading(sensor: 'Luz', value: '180 lux', timestamp: '2025-05-24 10:30'),
  ];
}
}