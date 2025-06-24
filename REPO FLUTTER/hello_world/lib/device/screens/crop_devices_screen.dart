import 'package:flutter/material.dart';
import '../../farm/models/crop_model.dart';
import '../models/device_model.dart';
import '../services/device_service.dart';
import '../widgets/device_card.dart';
import './available_devices_screen.dart';

class CropDevicesScreen extends StatefulWidget {
  final Crop crop;

  const CropDevicesScreen({Key? key, required this.crop}) : super(key: key);

  static const String routeName = '/crop-devices';

  @override
  _CropDevicesScreenState createState() => _CropDevicesScreenState();
}

class _CropDevicesScreenState extends State<CropDevicesScreen> {
  late Future<List<Device>> _devicesFuture;
  final DeviceService _deviceService = DeviceService();

  // --- Colores del Tema ---
  final Color _appBarColor = const Color(0xff2c3e50);
  final Color _scaffoldBgColor = const Color(0xfff2f5f8);

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  void _loadDevices() {
    setState(() {
      _devicesFuture = _deviceService.fetchCropDevices(widget.crop.cropId);
    });
  }

  void _navigateAndRefresh() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvailableDevicesScreen(cropId: widget.crop.cropId),
      ),
    );
    if (result == true) {
      _loadDevices();
    }
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
                onPressed: _loadDevices,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _appBarColor,
                  foregroundColor: Colors.white
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
        title: Text('Dispositivos en ${widget.crop.cropName}', style: TextStyle(color: Colors.white)),
        backgroundColor: _appBarColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Device>>(
        future: _devicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildInfoMessage(
              Icons.error_outline,
              'Error al cargar dispositivos: ${snapshot.error}',
              isError: true,
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildInfoMessage(
              Icons.devices_other_outlined,
              'No hay dispositivos asociados a este cultivo.',
            );
          }

          final devices = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.2,
            ),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/dashboard', arguments: device.deviceId);
                },
                child: DeviceCard(device: device),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateAndRefresh,
        label: const Text('Añadir Dispositivo'),
        icon: const Icon(Icons.add_circle_outline),
        backgroundColor: _appBarColor,
      ),
    );
  }
}