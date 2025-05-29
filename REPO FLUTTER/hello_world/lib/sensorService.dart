// services/sensor_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hello_world/sensor_service.dart';

class SensorService {
  static const String _url = 'https://list-sensor-readings-712174296076.northamerica-northeast1.run.app/readings';

  static Future<List<SensorReading>> fetchSensorReadings() async {
  final response = await http.get(Uri.parse(_url));

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
          timestamp: timestamp,
        ));
      }

      if (item['humidity'] != null) {
        readings.add(SensorReading.fromValue(
          sensor: 'Humedad',
          value: item['humidity'],
          timestamp: timestamp,
        ));
      }
    }

    return readings;
  } else {
    throw Exception('Error al obtener datos del servidor');
  }
}



}
