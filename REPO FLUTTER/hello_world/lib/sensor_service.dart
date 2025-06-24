// lib/sensor_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardData {
  final String displayDate;
  final List<SensorReading> readings;

  DashboardData({required this.displayDate, required this.readings});

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var list = json['readings'] as List;
    List<SensorReading> readingsList =
        list.map((i) => SensorReading.fromJson(i)).toList();
    return DashboardData(
      displayDate: json['displayDate'] ?? 'Fecha no disponible',
      readings: readingsList,
    );
  }
}

class SensorReading {
  final String sensor;
  final String value;
  final String timestamp;

  SensorReading(
      {required this.sensor, required this.value, required this.timestamp});

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      sensor: json['sensor'] ?? '',
      value: json['value']?.toString() ?? '0',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class SensorService {
  static const String _baseUrl = 'https://list-sensor-readings-712174296076.northamerica-northeast1.run.app';
  static const String _relayUrl = 'https://send-bool-acloud-712174296076.europe-west1.run.app';

  static Future<DashboardData> fetchSensorReadings(String deviceId) async {
    // CORRECCIÓN: La URL base ya es el endpoint, no se necesita '/readings'.
    // El parámetro 'id' se pasa directamente.
    final uri = Uri.parse('$_baseUrl?id=$deviceId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return DashboardData.fromJson(json.decode(response.body));
      } else {
        print('Error en fetchSensorReadings: ${response.statusCode} ${response.body}');
        throw Exception('No se pudo cargar los datos del sensor.');
      }
    } catch (e) {
      print('Error en fetchSensorReadings: $e');
      throw Exception('No se pudo conectar al servidor.');
    }
  }

  static Future<void> updateRelayState(bool newState) async {
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({'state': newState});

    try {
      final response = await http.post(
        Uri.parse(_relayUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode != 200) {
        throw Exception('Fallo al actualizar el relé: ${response.body}');
      }
      print('Relé actualizado a: $newState');
    } catch (e) {
      print('Error en updateRelayState: $e');
      throw Exception('No se pudo conectar al servicio del relé.');
    }
  }
}