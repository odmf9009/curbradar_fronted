import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'api_service.dart';
import 'socket_service.dart';
import 'proximity_service.dart';
import '../config/api_config.dart';

/// Servicio de autenticación.
///
/// Flujo:
/// 1. Login via Firebase (Google, Apple o Email/Password) → obtiene ID Token
/// 2. Envía el token al backend (/auth/verify)
/// 3. El backend crea/retorna el usuario en MongoDB
/// 4. El ApiService inyecta el token automáticamente en cada request
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ApiService _api = ApiService();

  /// Stream de estado de autenticación de Firebase
  Stream<User?> get userStream => _auth.authStateChanges();

  /// UID del usuario actual en Firebase
  String? get currentUserUid => _auth.currentUser?.uid;

  /// Indica si el usuario actual es un invitado (no logueado)
  bool get isGuest => _auth.currentUser == null;

  /// Login con Apple → verifica en el backend
  Future<Map<String, dynamic>?> signInWithApple({String? fcmToken}) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final AuthCredential credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await _auth.signInWithCredential(credential);

      // Verificar en el backend y obtener el perfil MongoDB
      return await _verifyWithBackend(fcmToken: fcmToken);
    } catch (e) {
      print('[Auth] Error Apple Sign In: $e');
      rethrow;
    }
  }

  /// Login con Google → verifica en el backend
  Future<Map<String, dynamic>?> signInWithGoogle({String? fcmToken}) async {
    try {
      await _googleSignIn.signOut(); // Fuerza selector de cuenta

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      // Verificar en el backend y obtener el perfil MongoDB
      return await _verifyWithBackend(fcmToken: fcmToken);
    } catch (e) {
      rethrow;
    }
  }

  /// Login con Email y Password
  Future<Map<String, dynamic>?> signInWithEmail(
    String email,
    String password, {
    String? fcmToken,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return await _verifyWithBackend(fcmToken: fcmToken);
    } catch (e) {
      rethrow;
    }
  }

  /// Registro con Email y Password
  Future<Map<String, dynamic>?> signUpWithEmail(
    String email,
    String password, {
    String? fcmToken,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return await _verifyWithBackend(fcmToken: fcmToken);
    } catch (e) {
      rethrow;
    }
  }

  /// Llama al backend para crear/obtener el perfil del usuario en MongoDB.
  /// Retorna el mapa del usuario o null si falla.
  Future<Map<String, dynamic>?> _verifyWithBackend({String? fcmToken}) async {
    try {
      final response = await _api.post(
        ApiConfig.authVerify,
        data: fcmToken != null ? {'fcmToken': fcmToken} : {},
      );
      return response.data['user'] as Map<String, dynamic>?;
    } on DioException catch (e) {
      print('[Auth] Error verificando con backend: ${ApiService.extractErrorMessage(e)}');
      return null;
    }
  }

  /// Cierra sesión en Firebase y el backend
  Future<void> signOut() async {
    try {
      await _api.post(ApiConfig.authLogout);
    } catch (_) {}
    
    // Detener servicios activos
    SocketService().disconnect();
    ProximityService().stopMonitoring();

    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
