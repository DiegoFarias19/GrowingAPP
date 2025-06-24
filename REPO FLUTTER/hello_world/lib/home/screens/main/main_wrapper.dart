import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hello_world/farm/screens/user_farms_screen.dart';
import 'package:hello_world/farm/screens/scheduler_screen.dart';
import 'package:hello_world/login/services/auth_service.dart'; // Para el signOut

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  _MainWrapperState createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final List<String> _pageTitles = const ['Mis Granjas', 'Agenda', 'Ajustes', 'Perfil'];

  // --- Colores del Tema ---
  final Color _appBarColor = const Color(0xff2c3e50);
  final Color _scaffoldBgColor = const Color(0xfff2f5f8);

  @override
  void initState() {
    super.initState();
    final userUid = FirebaseAuth.instance.currentUser?.uid;

    if (userUid == null) {
      // Esto es un fallback, AuthWrapper no debería permitir llegar aquí sin un usuario.
      _pages = [const Center(child: Text("Error: Usuario no autenticado."))];
    } else {
      _pages = [
        UserFarmsScreen(userUid: userUid, showAppBar: false), // showAppBar es ahora irrelevante
        const SchedulerScreen(),
        const Center(child: Text('Próximamente: Ajustes')),
        const Center(child: Text('Próximamente: Perfil')),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    // AuthWrapper se encargará de redirigir a LoginScreen.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex], style: const TextStyle(color: Colors.white)),
        backgroundColor: _appBarColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: _signOut,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_work_outlined), label: 'Granjas'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _appBarColor,
        unselectedItemColor: Colors.grey.shade600,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}