// lib/device/screens/relay_control_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hello_world/sensor_service.dart';

class RelayControlScreen extends StatefulWidget {
  static const routeName = '/relay-control';
  final String deviceId;

  const RelayControlScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  _RelayControlScreenState createState() => _RelayControlScreenState();
}

class _RelayControlScreenState extends State<RelayControlScreen> {
  bool _isRelayOn = false;
  bool _isLoading = false;
  String? _feedbackMessage;

  void _toggleRelay(bool currentState) async {
    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
    });

    try {
      final newState = !currentState;
      await SensorService.updateRelayState(newState);
      setState(() {
        _isRelayOn = newState;
        _feedbackMessage = 'Relé ${_isRelayOn ? "encendido" : "apagado"} correctamente.';
      });
    } catch (e) {
      setState(() {
        _feedbackMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f5f8),
      appBar: AppBar(
        title: const Text('Control del Relé', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff2c3e50),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Estado del Relé',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isRelayOn ? 'ENCENDIDO' : 'APAGADO',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _isRelayOn ? Colors.green.shade600 : Colors.red.shade600,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: _isLoading ? null : () => _toggleRelay(_isRelayOn),
                child: AnimatedPowerButton(isRelayOn: _isRelayOn, isLoading: _isLoading),
              ),
              const SizedBox(height: 60),
              if (_isLoading)
                const CircularProgressIndicator(),
              if (_feedbackMessage != null && !_isLoading)
                Text(
                  _feedbackMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _feedbackMessage!.startsWith('Error') ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedPowerButton extends StatelessWidget {
  final bool isRelayOn;
  final bool isLoading;

  const AnimatedPowerButton({
    Key? key,
    required this.isRelayOn,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isRelayOn ? Colors.green.shade500 : Colors.grey.shade700;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isRelayOn ? Colors.green.shade100 : Colors.grey.shade300,
        boxShadow: [
          // Sombra exterior
          BoxShadow(
            color: isRelayOn ? Colors.green.withOpacity(0.3) : Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 5,
            offset: const Offset(5, 5),
          ),
          // Sombra interior (para efecto de profundidad)
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 15,
            spreadRadius: 5,
            offset: const Offset(-5, -5),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.power_settings_new,
          size: 80,
          color: color,
        ),
      ),
    );
  }
}