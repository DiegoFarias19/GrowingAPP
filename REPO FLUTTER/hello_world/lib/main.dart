// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:hello_world/login/screen/forgot_password_screen.dart';
import 'package:hello_world/login/widgets/auth_wrapper.dart';
import 'package:hello_world/sensor_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hello_world/login/services/auth_service.dart';
import 'package:hello_world/login/screen/register_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const InvernaderoApp());
}

class InvernaderoApp extends StatelessWidget {
  const InvernaderoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invernadero Inteligente',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'NotoSans', // ← Aquí agregas la fuente
      ),
      home: const AuthWrapper(),
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/detalle': (context) => const CultivoDetailScreen(),
      },
    );
  }
}

// Pantalla de Login
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/invernadero-login.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.6)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Invernadero Inteligente',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu correo';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('¿No tienes una cuenta?'),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: const Text('Regístrate'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla principal de Dashboard
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Panel de Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
          IconButton(icon: const Icon(Icons.logout),
          onPressed: () async {
            await AuthService().signOut();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/');
            }
          })
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<SensorReading>>(
          future: SensorService.fetchSensorReadings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay lecturas disponibles'));
            }

            final readings = snapshot.data!;
            //print(readings);
            final temp = readings.firstWhere(
                (r) => r.sensor == 'Temperatura',
                orElse: () => SensorReading(sensor: 'Temperatura', value: '0', timestamp: ''));
            final hum = readings.firstWhere(
                (r) => r.sensor == 'Humedad',
                orElse: () => SensorReading(sensor: 'Humedad', value: '0', timestamp: ''));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SensorGauge(label: 'Temperatura', value: double.tryParse(temp.value) ?? 0, max: 30, unit: '°C'),
                    SensorGauge(label: 'Humedad', value: double.tryParse(hum.value) ?? 0, max: 100, unit: '%'),
                  ],
                ),
                const SizedBox(height: 24),
                                Expanded(
                  child: ListView(
                    children: [
                      buildLineChart(getSpots(readings, 'Temperatura'), getTimestamps(readings, 'Temperatura'), 'Historial de Temperatura', 30),
                      buildLineChart(getSpots(readings, 'Humedad'), getTimestamps(readings, 'Humedad'), 'Historial de Humedad', 80),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Detalle'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/detalle');
          }
        },
      ),
    );
  }
}

class SensorGauge extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final String unit;

  const SensorGauge({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / max).clamp(0.0, 1.0);
    final isAlert = value > max;

    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: percentage * 100,
                  color: isAlert ? Colors.red : Colors.yellow,
                  radius: 40,
                  title: '${value.toStringAsFixed(1)}$unit',
                  titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                PieChartSectionData(
                  value: (1 - percentage) * 100,
                  color: Colors.grey.shade200,
                  radius: 40,
                  title: '',
                ),
              ],
              centerSpaceRadius: 0,
              sectionsSpace: 0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// Detalle del cultivo
class CultivoDetailScreen extends StatelessWidget {
  const CultivoDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Detalle del cultivo'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cultivo 1 - Ciclo Germinación - Día 1',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Image.asset('assets/images/cultivo_detalle.jpg', height: 160, fit: BoxFit.cover),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3 / 2,
                children: const [
                  _DetailCard('🌡️ Temperatura', '30°C'),
                  _DetailCard('💧 Humedad', '50%'),
                  _DetailCard('☀️ Luz', '180 lux'),
                  _DetailCard('Estado', 'Óptimo'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Detalle'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/dashboard');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/detalle');
          }
        },
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String value;

  const _DetailCard(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

FirebaseMessaging messaging = FirebaseMessaging.instance;

void setupFCM() async {
  NotificationSettings settings = await messaging.requestPermission();
  
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Mensaje recibido en primer plano: ${message.notification?.title}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Usuario tocó la notificación');
  });

  String? token = await messaging.getToken();
  print('Token FCM: $token');
}

List<FlSpot> getSpots(List<SensorReading> readings, String type) {
  final filtered = readings
      .where((r) => r.sensor.contains(type))
      .take(10)
      .toList();

  return List.generate(filtered.length, (i) {
    final value = double.tryParse(filtered[i].value) ?? 0;
    return FlSpot(i.toDouble(), value);
  });
}

List<String> getTimestamps(List<SensorReading> readings, String type) {
  return readings
      .where((r) => r.sensor.contains(type))
      .take(10)
      .map((r) => r.timestamp)
      .toList();
}

Widget buildLineChart(List<FlSpot> spots, List<String> labels, String title, double maxLimit) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: spots,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: maxLimit,
                    color: Colors.red,
                    strokeWidth: 2,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.centerRight,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      labelResolver: (_) => 'Límite: $maxLimit',
                    ),
                  )
                ]),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < labels.length) {
                          return Text(labels[index], style: const TextStyle(fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, interval: 10),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}



