import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/device_service.dart';
import '../widgets/device_card.dart';

class AvailableDevicesScreen extends StatefulWidget {
  final String cropId;

  const AvailableDevicesScreen({Key? key, required this.cropId}) : super(key: key);

  static const String routeName = '/available-devices';

  @override
  _AvailableDevicesScreenState createState() => _AvailableDevicesScreenState();
}

class _AvailableDevicesScreenState extends State<AvailableDevicesScreen> {
  late Future<List<Device>> _availableDevicesFuture;
  final DeviceService _deviceService = DeviceService();
  bool _isAssociating = false;

  // --- Colores del Tema ---
  final Color _appBarColor = const Color(0xff2c3e50);
  final Color _scaffoldBgColor = const Color(0xfff2f5f8);

  @override
  void initState() {
    super.initState();
    _loadAvailableDevices();
  }

  void _loadAvailableDevices() {
    setState(() {
      _availableDevicesFuture = _deviceService.fetchAvailableDevices();
    });
  }

  Future<void> _associateDevice(Device device) async {
    if (_isAssociating) return;

    setState(() { _isAssociating = true; });

    try {
      await _deviceService.associateDeviceToCrop(device.deviceId, widget.cropId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${device.deviceName} asociado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asociar ${device.deviceName}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() { _isAssociating = false; });
      }
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
                onPressed: _loadAvailableDevices,
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
        title: const Text('Seleccionar Dispositivo', style: TextStyle(color: Colors.white)),
        backgroundColor: _appBarColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Device>>(
            future: _availableDevicesFuture,
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
                  'No hay dispositivos disponibles para asociar.',
                );
              }

              final devices = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: DeviceCard(
                      device: device,
                      onTap: () => _associateDevice(device),
                    ),
                  );
                },
              );
            },
          ),
          if (_isAssociating)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Asociando dispositivo...', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}