import 'package:flutter/material.dart';
import '../models/cronograma.dart';
import '../services/api_service.dart';

enum CronogramaStatus { idle, loading, success, error }

class CronogramaProvider extends ChangeNotifier {
  final ApiService _apiService;

  CronogramaStatus _status = CronogramaStatus.idle;
  Cronograma? _cronogramaActual;
  List<HistorialItem> _historial = [];
  Map<String, dynamic>? _parametros;
  String? _errorMessage;
  bool _loadingHistorial = false;

  CronogramaStatus get status => _status;
  Cronograma? get cronogramaActual => _cronogramaActual;
  List<HistorialItem> get historial => _historial;
  Map<String, dynamic>? get parametros => _parametros;
  String? get errorMessage => _errorMessage;
  bool get loadingHistorial => _loadingHistorial;
  bool get isLoading => _status == CronogramaStatus.loading;

  CronogramaProvider(this._apiService);

  Future<bool> generarCronograma({
    required String documento,
    required String tipodoc,
    required int nroCuotas,
  }) async {
    _status = CronogramaStatus.loading;
    _errorMessage = null;
    _cronogramaActual = null;
    notifyListeners();

    try {
      _cronogramaActual = await _apiService.generarCronograma(
        documento: documento,
        tipodoc: tipodoc,
        nroCuotas: nroCuotas,
      );
      _status = CronogramaStatus.success;
      notifyListeners();
      // Refrescar historial en background
      loadHistorial();
      return true;
    } catch (e) {
      _errorMessage = extractErrorMessage(e);
      _status = CronogramaStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> consultarCronograma(String documento, String tipodoc) async {
    _status = CronogramaStatus.loading;
    notifyListeners();

    try {
      _cronogramaActual = await _apiService.consultarCronograma(documento, tipodoc);
      _status = CronogramaStatus.success;
    } catch (e) {
      _errorMessage = extractErrorMessage(e);
      _status = CronogramaStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadHistorial() async {
    _loadingHistorial = true;
    notifyListeners();

    try {
      _historial = await _apiService.getHistorial();
    } catch (e) {
      // Silencioso — el historial es secundario
    } finally {
      _loadingHistorial = false;
      notifyListeners();
    }
  }

  Future<void> loadParametros() async {
    try {
      _parametros = await _apiService.getParametros();
      notifyListeners();
    } catch (_) {}
  }

  void limpiarCronograma() {
    _cronogramaActual = null;
    _status = CronogramaStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
