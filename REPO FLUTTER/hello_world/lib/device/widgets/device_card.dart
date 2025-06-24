// lib/farm/widgets/device_card.dart
import 'package:flutter/material.dart';
import '../models/device_model.dart'; // Ajusta la ruta si es necesario

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceCard({Key? key, required this.device, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap, // Se usará para seleccionar un dispositivo disponible
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                device.deviceName,
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.0),
              Text(
                'ID: ${device.deviceId}',
                style: TextStyle(fontSize: 12.0, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.0),
              Text(
                'Estado: ${device.state ? "Asociado" : "Disponible"}',
                style: TextStyle(
                  fontSize: 12.0,
                  color: device.state ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (device.state && device.cropId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Cultivo ID: ${device.cropId}',
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
