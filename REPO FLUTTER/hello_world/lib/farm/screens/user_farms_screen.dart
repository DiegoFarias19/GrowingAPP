import 'package:flutter/material.dart';
import '../models/farm_model.dart';
import '../services/farm_service.dart';
import '../widgets/farm_card.dart';
import './farm_crops_screen.dart';
import './create_farm_screen.dart';

class UserFarmsScreen extends StatefulWidget {
  final String userUid;
  final bool showAppBar; // Se mantiene por compatibilidad, pero no se usa

  const UserFarmsScreen({
    Key? key,
    required this.userUid,
    this.showAppBar = true,
  }) : super(key: key);

  static const routeName = '/user-farms';

  @override
  _UserFarmsScreenState createState() => _UserFarmsScreenState();
}

class _UserFarmsScreenState extends State<UserFarmsScreen> {
  late Future<List<Farm>> _farmsFuture;
  final FarmService _farmService = FarmService();

  // --- Colores del Tema ---
  final Color _fabColor = const Color(0xff2c3e50);
  final Color _scaffoldBgColor = const Color(0xfff2f5f8);

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  void _loadFarms() {
    if (mounted) {
      setState(() {
        _farmsFuture = _farmService.fetchUserFarms(widget.userUid);
      });
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
                onPressed: _loadFarms,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _fabColor,
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
      // El AppBar ahora se gestiona en MainWrapper
      body: FutureBuilder<List<Farm>>(
        future: _farmsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildInfoMessage(
              Icons.error_outline,
              'Error al cargar tus granjas: ${snapshot.error}',
              isError: true,
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildInfoMessage(
              Icons.home_work_outlined,
              'No tienes granjas todavía. ¡Crea una para empezar!',
            );
          }

          final farms = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.9,
            ),
            itemCount: farms.length,
            itemBuilder: (context, index) {
              final farm = farms[index];
              return FarmCard(
                farm: farm,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FarmCropsScreen(farm: farm),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, CreateFarmScreen.routeName);
          if (result == true && mounted) {
            _loadFarms();
          }
        },
        tooltip: 'Crear Nueva Granja',
        icon: const Icon(Icons.add),
        label: const Text('Crear Granja'),
        backgroundColor: _fabColor,
      ),
    );
  }
}