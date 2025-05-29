import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hello_world/login/services/auth_service.dart';
import 'package:hello_world/main.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          
          // Verificar si el email está verificado
          if (!user.emailVerified) {
            return EmailVerificationScreen();
          }
          
          return const DashboardScreen();
        }
        
        // Mientras se carga el estado de autenticación
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isSending = false;
  String _message = '';

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isSending = true;
      _message = '';
    });

    try {
      await _authService.sendEmailVerification();
      setState(() {
        _message = 'Email de verificación enviado. Por favor revisa tu bandeja de entrada.';
      });
    } catch (e) {
      setState(() {
        _message = 'Error al enviar el email: $e';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Email'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.mark_email_unread,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'Verifica tu correo electrónico',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hemos enviado un correo de verificación a tu dirección de email. Por favor, verifica tu correo para continuar.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _message,
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: _isSending ? null : _sendVerificationEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Reenviar correo de verificación'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                // Recargar el usuario para verificar si ya está verificado
                await FirebaseAuth.instance.currentUser?.reload();
                if (mounted) {
                  setState(() {});
                }
              },
              child: const Text('Ya verifiqué mi correo'),
            ),
            TextButton(
              onPressed: () async {
                await _authService.signOut();
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}