import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/cronograma.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api'; // Cambiar en producción
  static const _storage = FlutterSecureStorage();

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Interceptor para agregar token JWT automáticamente
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expirado → limpiar storage
          _storage.delete(key: 'jwt_token');
        }
        return handler.next(error);
      },
    ));
  }

  // ─── AUTH ─────────────────────────────────────────────────────

  Future<User> login(String username, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });

    final data = response.data['data'];
    final token = data['token'];

    // Guardar token
    await _storage.write(key: 'jwt_token', value: token);

    return User(
      id: data['user']['id'],
      username: data['user']['username'],
      nombre: data['user']['nombre'],
      token: token,
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  // ─── CRONOGRAMA ───────────────────────────────────────────────

  Future<Cronograma> generarCronograma({
    required String documento,
    required String tipodoc,
    required int nroCuotas,
  }) async {
    final response = await _dio.post('/cronograma/generar', data: {
      'documento': documento,
      'tipodoc': tipodoc,
      'nroCuotas': nroCuotas,
    });

    return Cronograma.fromJson(response.data['data']);
  }

  Future<Cronograma> consultarCronograma(String documento, String tipodoc) async {
    final response = await _dio.get('/cronograma/$documento/$tipodoc');
    return Cronograma.fromJson(response.data['data']);
  }

  Future<List<HistorialItem>> getHistorial({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get('/cronograma/historial', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });

    return (response.data['data'] as List)
        .map((item) => HistorialItem.fromJson(item))
        .toList();
  }

  Future<Map<String, dynamic>> getParametros() async {
    final response = await _dio.get('/cronograma/parametros');
    return response.data['data'];
  }

  Future<Map<String, dynamic>?> validarDocumento(
      String documento, String tipodoc) async {
    try {
      final response = await _dio.post('/cronograma/documento/validar', data: {
        'documento': documento,
        'tipodoc': tipodoc,
      });
      return response.data['data'];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

// Helper para extraer mensajes de error de Dio
String extractErrorMessage(dynamic error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'];
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de conexión agotado. Verifique su conexión.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar al servidor. Verifique su red.';
      default:
        return 'Error de red: ${error.message}';
    }
  }
  return error.toString();
}
