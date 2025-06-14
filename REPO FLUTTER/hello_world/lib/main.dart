import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hello_world/login/screen/forgot_password_screen.dart';
import 'package:hello_world/login/widgets/auth_wrapper.dart';
import 'package:hello_world/sensor_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hello_world/login/services/auth_service.dart';
import 'package:hello_world/login/screen/register_screen.dart';
import 'package:google_fonts/google_fonts.dart';



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
                        textTheme: GoogleFonts.poppinsTextTheme(),
                        primarySwatch: Colors.green,
                      ),
      initialRoute: '/',
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/detalle': (context) => const CultivoDetailScreen(),
        '/control': (context) => const ControlScreen()
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
          )
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
                                              buildStyledLineChart(
                                                spots: getSpots(readings, 'Temperatura'),
                                                labels: getTimestamps(readings, 'Temperatura', onlyHour: true),
                                                title: 'Historial de Temperatura',
                                                maxLimit: 30,
                                                color: Colors.orange,
                                              ),
                                              buildStyledLineChart(
                                                spots: getSpots(readings, 'Humedad'),
                                                labels: getTimestamps(readings, 'Humedad', onlyHour: true),
                                                title: 'Historial de Humedad',
                                                maxLimit: 80,
                                                color: Colors.blue,
                                              ),
                                            ],
                                          ),
                                        )
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: buildBottomNavBar(context, 0),
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
    final isWithinLimit = value <= max;
    final percentage = (value / max).clamp(0.0, 1.0);
    final color = isWithinLimit ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 10,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              Column(
                children: [
                  Icon(
                    isWithinLimit ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    color: color,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${value.toStringAsFixed(1)} $unit',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
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
      bottomNavigationBar: buildBottomNavBar(context, 1),
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

List<String> getTimestamps(List<SensorReading> readings, String type, {bool onlyHour = false}) {
  return readings
      .where((r) => r.sensor.contains(type))
      .take(10)
      .map((r) {
        final dateTime = DateTime.tryParse(r.timestamp);
        if (dateTime == null) return '';
        return onlyHour ? '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}' : r.timestamp;
      })
      .toList();
}


Widget buildSmoothTemperatureChart(List<FlSpot> spots, List<String> timestamps) {
  return Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial de Temperatura',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < timestamps.length) {
                        return Text(
                          timestamps[index],
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (spots.length - 1).toDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.deepPurpleAccent,
                  barWidth: 4,
                  belowBarData: BarAreaData(show: true, color: Colors.deepPurple.withOpacity(0.2)),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(radius: 4, color: Colors.deepPurple, strokeWidth: 1.5, strokeColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildSmoothHumidityChart(List<FlSpot> spots, List<String> timestamps) {
  return Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial de Humedad',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < timestamps.length) {
                        return Text(
                          timestamps[index],
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (spots.length - 1).toDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.teal,
                  barWidth: 4,
                  belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.2)),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(radius: 4, color: Colors.teal, strokeWidth: 1.5, strokeColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool state = true;
  final String endpoint = 'flutter';

  Future<void> sendState() async {
    final response = await Uri.parse(endpoint);
    try {
      final res = await http.post(
        response,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "pid": "2563552d-50c1-4ad8-932b-835056f85d01",
          "state": state
        }),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state ? 'Actuador encendido' : 'Actuador apagado',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          backgroundColor: state ? Colors.green : Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: Text(
          'Control Manual',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF388E3C),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Control de Luz 💡',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF212121),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                OnOffButton(
                        initialState: state,
                        onToggle: (value) {
                          setState(() {
                            state = value;
                          });
                        },
                      ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: sendState,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: Text(
                    'Enviar',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF388E3C),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14.0, horizontal: 24.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavBar(context, 2),
    );
  }
}

class OnOffButton extends StatefulWidget {
  final bool initialState;
  final Function(bool) onToggle;

  const OnOffButton({
    super.key,
    required this.initialState,
    required this.onToggle,
  });

  @override
  State<OnOffButton> createState() => _OnOffButtonState();
}

class _OnOffButtonState extends State<OnOffButton> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.initialState;
  }

  void toggleButton() {
    setState(() {
      isOn = !isOn;
      widget.onToggle(isOn);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleButton,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 180,
        height: 56,
        decoration: BoxDecoration(
          color: isOn ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 24,
              child: Text(
                isOn ? 'ENCENDIDO' : 'APAGADO',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOn ? Icons.power : Icons.power_off,
                  color: isOn ? Colors.green : Colors.red,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

Widget buildBottomNavBar(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    selectedItemColor: Colors.green,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Detalle'),
      BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Control'),
    ],
    onTap: (index) {
      if (index == 0) {
        Navigator.pushNamed(context, '/dashboard');
      } else if (index == 1) {
        Navigator.pushNamed(context, '/detalle');
      } else if (index == 2) {
        Navigator.pushNamed(context, '/control');
      }
    },
  );
}

Widget buildStyledLineChart({
  required List<FlSpot> spots,
  required List<String> labels,
  required String title,
  required double maxLimit,
  Color color = Colors.blueAccent,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.white,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)}',
                        GoogleFonts.robotoMono(fontSize: 14, color: Colors.black),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  spots: spots,
                  color: color,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.2),
                  ),
                  barWidth: 3,
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 10,
                    getTitlesWidget: (value, _) => Text(
                      '${value.toInt()}',
                      style: GoogleFonts.poppins(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      return index < labels.length
                          ? Transform.rotate(
                              angle: 0, // ya no vertical
                              child: Text(
                                labels[index],
                                style: GoogleFonts.poppins(fontSize: 10),
                              ),
                            )
                          : const Text('');
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: maxLimit,
                  color: Colors.redAccent,
                  strokeWidth: 2,
                  dashArray: [4, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    labelResolver: (_) => 'Límite: $maxLimit',
                    style: GoogleFonts.robotoMono(
                        color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(),
                  bottom: BorderSide(),
                ),
              ),
              minX: 0,
              maxX: (labels.length - 1).toDouble(),
            ),
          ),
        ),
      ],
    ),
  );
}



