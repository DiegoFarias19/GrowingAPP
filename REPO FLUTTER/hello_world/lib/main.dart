// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hello_world/device/screens/relay_control_screen.dart';
import 'package:hello_world/login/screen/forgot_password_screen.dart';
import 'package:hello_world/login/widgets/auth_wrapper.dart';
import 'package:hello_world/sensor_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hello_world/login/services/auth_service.dart';
import 'package:hello_world/login/screen/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hello_world/farm/screens/user_farms_screen.dart';
import 'package:hello_world/farm/screens/farm_crops_screen.dart';
import 'package:hello_world/farm/models/farm_model.dart';
import 'package:hello_world/farm/models/crop_model.dart';
import 'package:hello_world/farm/screens/create_farm_screen.dart';
import 'package:hello_world/device/screens/crop_devices_screen.dart';
import 'package:hello_world/device/screens/available_devices_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const InvernaderoApp());
}

class InvernaderoApp extends StatelessWidget {
  const InvernaderoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Growing APP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'NotoSans',
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
        ).copyWith(
          secondary: Colors.greenAccent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
          case UserFarmsScreen.routeName:
            final userUid = settings.arguments as String?;
            if (userUid != null) {
              return MaterialPageRoute(
                builder: (_) => UserFarmsScreen(userUid: userUid),
              );
            }
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
          case FarmCropsScreen.routeName:
            final farm = settings.arguments as Farm?;
            if (farm != null) {
              return MaterialPageRoute(
                builder: (_) => FarmCropsScreen(farm: farm),
              );
            }
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
          case CreateFarmScreen.routeName:
            return MaterialPageRoute(builder: (_) => const CreateFarmScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/forgot-password':
            return MaterialPageRoute(
              builder: (_) => const ForgotPasswordScreen(),
            );
          case CropDevicesScreen.routeName:
            final crop = settings.arguments as Crop?;
            if (crop != null) {
              return MaterialPageRoute(
                builder: (_) => CropDevicesScreen(crop: crop),
              );
            }
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
          case AvailableDevicesScreen.routeName:
            final cropId = settings.arguments as String?;
            if (cropId != null) {
              return MaterialPageRoute(
                builder: (_) => AvailableDevicesScreen(cropId: cropId),
              );
            }
            return MaterialPageRoute(builder: (_) => const AuthWrapper());

          case '/dashboard':
            final deviceId = settings.arguments as String?;
            if (deviceId != null) {
              return MaterialPageRoute(
                builder: (_) => DashboardScreen(deviceId: deviceId),
              );
            }
            return MaterialPageRoute(builder: (_) => const AuthWrapper());

          case RelayControlScreen.routeName:
            final deviceId = settings.arguments as String?;
            if (deviceId != null) {
              return MaterialPageRoute(
                builder: (_) => RelayControlScreen(deviceId: deviceId),
              );
            }
            return MaterialPageRoute(builder: (_) => const AuthWrapper());

          default:
            return MaterialPageRoute(builder: (_) => const AuthWrapper());
        }
      },
    );
  }
}

// --- LoginScreen (sin cambios) ---
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

  // --- Colores del Tema ---
  final Color _primaryColor = const Color(0xff2c3e50);

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
        // AuthWrapper se encargará de la navegación.
      } on FirebaseAuthException catch (e) {
        String message;
        switch (e.code) {
          case 'user-not-found':
          case 'INVALID_LOGIN_CREDENTIALS':
          case 'wrong-password':
            message = 'Correo o contraseña incorrectos.';
            break;
          case 'invalid-email':
            message = 'El formato del correo es inválido.';
            break;
          case 'too-many-requests':
            message = 'Demasiados intentos. Intenta más tarde.';
            break;
          case 'network-request-failed':
            message = 'Error de red. Verifica tu conexión.';
            break;
          default:
            message = e.message ?? 'Error de autenticación desconocido.';
        }
        setState(() { _errorMessage = message; });
      } catch (e) {
        setState(() { _errorMessage = 'Ocurrió un error inesperado.'; });
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
    );
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
            color: Colors.black.withOpacity(0.4),
            colorBlendMode: BlendMode.darken,
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Invernadero Inteligente',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          decoration: _buildInputDecoration('Correo electrónico', Icons.email_outlined),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa tu correo';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: _buildInputDecoration('Contraseña', Icons.lock_outline),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                            child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: _primaryColor)),
                          ),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                : const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('¿No tienes una cuenta?'),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/register'),
                              child: Text('Regístrate', style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
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

// --- DASHBOARD SCREEN (CÓDIGO CORREGIDO Y OPTIMIZADO) ---
class DashboardScreen extends StatefulWidget {
  final String deviceId;
  const DashboardScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- PASO 1: Campos de estado centralizados ---
  DashboardData? _dashboardData;
  double? _latestTemp;
  double? _latestHum;
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSensorData(); // Carga inicial
    // --- PASO 4: Refresco automático ---
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadSensorData(isRefresh: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Importante para evitar fugas de memoria
    super.dispose();
  }

  // --- PASO 2: Lógica de carga refactorizada ---
  Future<void> _loadSensorData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await SensorService.fetchSensorReadings(widget.deviceId);
      double? temp;
      double? hum;

      // Recorrer la lista para obtener el ÚLTIMO valor de cada sensor
      if (data.readings.isNotEmpty) {
        for (final r in data.readings) {
          if (r.sensor.toLowerCase() == 'temperature') {
            temp = double.tryParse(r.value);
          }
          if (r.sensor.toLowerCase() == 'humidity') {
            hum = double.tryParse(r.value);
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _latestTemp = temp;
          _latestHum = hum;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error al cargar datos: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f5f8),
      appBar: AppBar(
        title: const Text('Dashboard del Sensor', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff2c3e50),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSensorData(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_dashboardData == null || _dashboardData!.readings.isEmpty) {
      return const Center(child: Text('No hay datos de sensor para mostrar.'));
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: const Color(0xff34495e),
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Center(
              child: Text(
                'Mostrando datos de: ${_dashboardData!.displayDate}',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              // --- PASO 3: Usar los campos de estado en las cards ---
              SensorCard(
                title: 'Temperatura',
                value: _latestTemp != null ? '${_latestTemp!.toStringAsFixed(1)}°C' : '--',
                icon: Icons.thermostat,
                color: Colors.orange,
              ),
              SensorCard(
                title: 'Humedad',
                value: _latestHum != null ? '${_latestHum!.toStringAsFixed(1)}%' : '--',
                icon: Icons.water_drop,
                color: Colors.blue,
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ModernLineChart(
              readings: _dashboardData!.readings,
              sensorType: 'temperature',
              title: 'Temperatura (°C)',
              gradientColors: const [Colors.orange, Colors.red],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ModernLineChart(
              readings: _dashboardData!.readings,
              sensorType: 'humidity',
              title: 'Humedad (%)',
              gradientColors: const [Colors.blue, Colors.lightBlueAccent],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.power, color: Colors.white),
              label: const Text('Accionar Relé', style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RelayControlScreen.routeName,
                  arguments: widget.deviceId,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff34495e),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- SensorCard (sin cambios) ---
class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const SensorCard(
      {Key? key,
      required this.title,
      required this.value,
      required this.icon,
      required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- ModernLineChart (sin cambios) ---
class ModernLineChart extends StatelessWidget {
  final List<SensorReading> readings;
  final String sensorType;
  final String title;
  final List<Color> gradientColors;

  const ModernLineChart({
    Key? key,
    required this.readings,
    required this.sensorType,
    required this.title,
    required this.gradientColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final spots = _getSpotsForSensor(readings, sensorType);
    if (spots.isEmpty) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('No hay datos de $title para mostrar.')),
      );
    }

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff34495e))),
            const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                    getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 6,
                        getTitlesWidget: (value, meta) {
                          final style = const TextStyle(
                              color: Colors.black54, fontSize: 10);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('${value.toInt()}:00', style: style),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                          color: Colors.grey.withOpacity(0.2), width: 1)),
                  minX: 0,
                  maxX: 23,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(colors: gradientColors),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: gradientColors
                              .map((color) => color.withOpacity(0.3))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final hour = spot.x.toInt();
                          final minute = ((spot.x - hour) * 60).round();
                          final time =
                              '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                          return LineTooltipItem(
                            '$time\n${spot.y.toStringAsFixed(1)} ${sensorType == 'temperature' ? '°C' : '%'}',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getSpotsForSensor(
      List<SensorReading> readings, String sensorType) {
    final sensorReadings = readings
        .where((r) => r.sensor.toLowerCase() == sensorType)
        .toList();

    if (sensorReadings.isEmpty) return [];

    final List<FlSpot> spots = [];
    for (var reading in sensorReadings) {
      final timestamp = DateTime.tryParse(reading.timestamp)?.toLocal();
      final value = double.tryParse(reading.value);

      if (timestamp != null && value != null) {
        final hourDecimal = timestamp.hour + (timestamp.minute / 60.0);
        spots.add(FlSpot(hourDecimal, value));
      }
    }

    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }
}