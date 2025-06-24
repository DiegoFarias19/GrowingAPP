import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/farm_model.dart';

class FarmService {
  final String _baseUrl =
      'https://list-user-farms-712174296076.europe-west1.run.app';

  Future<List<Farm>> fetchUserFarms(String userUid) async {
    final Uri url = Uri.parse('$_baseUrl?user_uid=$userUid');
    try {
      print('Fetching farms for user: $userUid from: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        List<Farm> farms =
            body
                .map(
                  (dynamic item) => Farm.fromJson(item as Map<String, dynamic>),
                )
                .toList();
        return farms;
      } else {
        print(
          'Failed to load farms for user $userUid. Status code: ${response.statusCode}',
        );
        print('Response body: ${response.body}');
        throw Exception(
          'Fallo al cargar granjas (código: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('Error fetching user farms: $e');
      throw Exception('Error al obtener granjas del usuario: $e');
    }
  }

  final String _createFarmUrl =
      'https://create-farm-http-712174296076.northamerica-northeast1.run.app';

  Future<Farm?> createFarm(
    String userUid,
    Map<String, dynamic> farmData /*, String? idToken */,
  ) async {
    // El user_uid va como query parameter para la Cloud Function create_farm_http
    final Uri url = Uri.parse('$_createFarmUrl?user_uid=$userUid');
    print(
      'FarmService: Creating farm for user $userUid at $url with data: $farmData',
    );

    // Si no pasas idToken como argumento, obténlo aquí si es necesario para la autorización
    // String? currentIdToken = idToken;
    // if (currentIdToken == null) {
    //   try {
    //     currentIdToken = await FirebaseAuth.instance.currentUser?.getIdToken(true); // true para forzar refresco
    //   } catch (e) {
    //     print("FarmService: Error obteniendo ID token para createFarm: $e");
    //     // Decide si continuar sin token o lanzar error
    //   }
    // }

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      // if (currentIdToken != null) 'Authorization': 'Bearer $currentIdToken',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(farmData), // farmData debe contener 'farm_name', etc.
      );

      if (response.statusCode == 201) {
        // Creado exitosamente
        print(
          'FarmService: Farm created successfully. Response: ${response.body}',
        );
        // La Cloud Function devuelve el objeto de la granja creada con 'id' y 'name'
        return Farm.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        print(
          'FarmService: Failed to create farm. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception(
          'Fallo al crear la granja (código: ${response.statusCode})',
        );
      }
    } catch (e) {
      print('FarmService: Error creating farm: $e');
      throw Exception('Error al crear la granja: $e');
    }
  }
}
