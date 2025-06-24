import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../models/farm_model.dart';
import '../services/crop_service.dart';
import '../widgets/crop_card.dart';
import '../../device/screens/crop_devices_screen.dart';

class FarmCropsScreen extends StatefulWidget {
  final Farm farm;

  const FarmCropsScreen({Key? key, required this.farm}) : super(key: key);

  static const String routeName = '/farm-crops';

  @override
  _FarmCropsScreenState createState() => _FarmCropsScreenState();
}

class _FarmCropsScreenState extends State<FarmCropsScreen> {
  late Future<List<Crop>> _cropsFuture;
  final CropService _cropService = CropService();

  // --- Colores del Tema ---
  final Color _appBarColor = const Color(0xff2c3e50);
  final Color _scaffoldBgColor = const Color(0xfff2f5f8);

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  void _loadCrops() {
    setState(() {
      _cropsFuture = _cropService.fetchFarmCrops(widget.farm.farmId);
    });
  }

  Widget _buildInfoMessage(IconData icon, String message, {bool isError = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: isError ? Colors.red.shade300 : Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            if (isError) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadCrops,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _appBarColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      appBar: AppBar(
        title: Text('Cultivos en ${widget.farm.farmName}', style: TextStyle(color: Colors.white)),
        backgroundColor: _appBarColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Crop>>(
        future: _cropsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildInfoMessage(
              Icons.error_outline,
              'Error al cargar cultivos: ${snapshot.error}',
              isError: true,
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildInfoMessage(
              Icons.eco_outlined,
              'No hay cultivos en esta granja.',
            );
          }

          final crops = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.9,
            ),
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final crop = crops[index];
              return CropCard(
                crop: crop,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CropDevicesScreen(crop: crop),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}