import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/farm_model.dart';
import '../services/farm_service.dart';

class CreateFarmScreen extends StatefulWidget {
  static const String routeName = '/create-farm';

  const CreateFarmScreen({Key? key}) : super(key: key);

  @override
  _CreateFarmScreenState createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends State<CreateFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _farmService = FarmService();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  String? _userUid;

  // --- Colores del Tema ---
  final Color _appBarColor = const Color(0xff2c3e50);
  final Color _scaffoldBgColor = const Color(0xfff2f5f8);

  @override
  void initState() {
    super.initState();
    _getCurrentUserUid();
  }

  Future<void> _getCurrentUserUid() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() { _userUid = currentUser.uid; });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Debes estar autenticado.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID de usuario.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final farmData = {
      'farm_name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
    };

    try {
      await _farmService.createFarm(_userUid!, farmData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Granja creada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear la granja: $e')),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _appBarColor.withOpacity(0.7)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _appBarColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      appBar: AppBar(
        title: const Text('Crear Nueva Granja', style: TextStyle(color: Colors.white)),
        backgroundColor: _appBarColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: <Widget>[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputDecoration(
                    'Nombre de la Granja *',
                    'Ej: Granja El Sol',
                    Icons.label_important_outline_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Ingresa el nombre.';
                    if (value.trim().length < 3) return 'Debe tener al menos 3 caracteres.';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _locationController,
                  decoration: _buildInputDecoration(
                    'Ubicación',
                    'Ej: Quito, Pichincha',
                    Icons.location_on_outlined,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _buildInputDecoration(
                    'Descripción',
                    'Detalles sobre la granja...',
                    Icons.notes_outlined,
                  ),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: _isLoading ? Container() : const Icon(Icons.save_alt_rounded),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      : const Text('Guardar Granja'),
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appBarColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}