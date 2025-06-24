// lib/farm/services/device_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_model.dart'; // Asegúrate que la ruta sea correcta

class DeviceService {
  // Reemplaza estas URLs base con tus URLs reales de Cloud Functions o backend
  final String _baseUrl =
      "https://merge-device-crop-712174296076.northamerica-northeast1.run.app"; // Ejemplo

  // Endpoint para obtener dispositivos por crop_id
  // Asume GET <_baseUrl>/getCropDevices?crop_id=<cropId>
  Future<List<Device>> fetchCropDevices(String cropId) async {
    final Uri url = Uri.parse(
      '$_baseUrl/getCropDevices?crop_id=$cropId',
    ); // Ajusta el nombre del endpoint
    print('Fetching devices for crop $cropId from: $url');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        List<Device> devices =
            body
                .map(
                  (dynamic item) =>
                      Device.fromJson(item as Map<String, dynamic>),
                )
                .toList();
        print(
          'Devices fetched successfully: ${devices.length} for crop $cropId',
        );
        return devices;
      } else {
        print(
          'Failed to load devices for crop $cropId. Status code: ${response.statusCode}',
        );
        print('Response body: ${response.body}');
        throw Exception(
          'Fallo al cargar dispositivos (código: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('Error fetching crop devices: $e');
      throw Exception('Error al obtener dispositivos del cultivo: $e');
    }
  }

  // Endpoint para obtener dispositivos disponibles (state == false)
  // Asume GET <_baseUrl>/getAvailableDevices
  Future<List<Device>> fetchAvailableDevices() async {
    final Uri url = Uri.parse(
      '$_baseUrl/getAvailableDevices',
    ); // Ajusta el nombre del endpoint
    print('Fetching available devices from: $url');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        List<Device> devices =
            body
                .map(
                  (dynamic item) =>
                      Device.fromJson(item as Map<String, dynamic>),
                )
                .toList();
        print('Available devices fetched successfully: ${devices.length}');
        return devices;
      } else {
        print(
          'Failed to load available devices. Status code: ${response.statusCode}',
        );
        print('Response body: ${response.body}');
        throw Exception(
          'Fallo al cargar dispositivos disponibles (código: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('Error fetching available devices: $e');
      throw Exception('Error al obtener dispositivos disponibles: $e');
    }
  }

  // Endpoint para asociar un dispositivo a un cultivo
  // Asume POST <_baseUrl>/associateDeviceToCrop
  // Cuerpo del POST: { "device_id": "...", "crop_id": "..." }
  Future<void> associateDeviceToCrop(String deviceId, String cropId) async {
    final Uri url = Uri.parse(
      '$_baseUrl/associateDeviceToCrop',
    ); // Ajusta el nombre del endpoint
    print('Associating device $deviceId to crop $cropId via: $url');
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'device_id': deviceId,
          'crop_id': cropId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content también es éxito
        print('Device $deviceId associated successfully with crop $cropId.');
        // El backend debería cambiar el 'state' del dispositivo a true
      } else {
        print(
          'Failed to associate device $deviceId. Status code: ${response.statusCode}',
        );
        print('Response body: ${response.body}');
        throw Exception(
          'Fallo al asociar dispositivo (código: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('Error associating device: $e');
      throw Exception('Error al asociar dispositivo: $e');
    }
  }
}
