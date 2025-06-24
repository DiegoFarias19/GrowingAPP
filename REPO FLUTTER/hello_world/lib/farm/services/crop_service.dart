import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crop_model.dart';

class CropService {
  final String _baseUrl =
      'https://get-farm-crops-712174296076.northamerica-northeast1.run.app';

  Future<List<Crop>> fetchFarmCrops(String farmId) async {
    final Uri url = Uri.parse('$_baseUrl?farm_id=$farmId');
    try {
      print('Fetching crops for farm $farmId from: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        List<Crop> crops =
            body
                .map(
                  (dynamic item) => Crop.fromJson(item as Map<String, dynamic>),
                )
                .toList();
        print(
          'Crops fetched successfully: ${crops.length} crops for farm $farmId',
        );
        return crops;
      } else {
        print(
          'Failed to load crops for farm $farmId. Status code: ${response.statusCode}',
        );
        print('Response body: ${response.body}');
        throw Exception(
          'Fallo al cargar cultivos (código: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('Error fetching farm crops: $e');
      throw Exception('Error al obtener cultivos de la granja: $e');
    }
  }
}
