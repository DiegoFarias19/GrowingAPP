import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential?> registerWithEmailAndPassword(
    String email, 
    String password
    ) async {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await userCredential.user?.sendEmailVerification();
        return userCredential;
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      }
    }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password
    ) async {
      try {
        return await _auth.signInWithEmailAndPassword(
          email: email, 
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        throw _handleAuthException(e);
      }
    }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
    
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Este usuario ha sido deshabilitado.';
      case 'user-not-found': 
        return 'No existe un usuario con este correo electrónico.';
      case 'wrong-password':
        return 'La contraseña es incorrecta.';
      case 'email-already-in-use':
        return 'Ya existe un usuario con este correo electrónico.';
      case 'operation-not-allowed':
        return 'La operación no está permitida.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'too-many-requests':
        return 'Ha superado el número máximo de intentos.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}