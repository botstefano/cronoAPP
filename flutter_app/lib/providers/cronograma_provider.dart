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
  
  Map<String, dynamic>? _documentoInfo;
  bool _loadingDocumentoInfo = false;

  CronogramaStatus get status => _status;
  Cronograma? get cronogramaActual => _cronogramaActual;
  List<HistorialItem> get historial => _historial;
  Map<String, dynamic>? get parametros => _parametros;
  String? get errorMessage => _errorMessage;
  bool get loadingHistorial => _loadingHistorial;
  bool get isLoading => _status == CronogramaStatus.loading;
  
  Map<String, dynamic>? get documentoInfo => _documentoInfo;
  bool get loadingDocumentoInfo => _loadingDocumentoInfo;

  CronogramaProvider(this._apiService);

  Future<void> loadDocumentoInfo(String documento, String tipodoc) async {
    _loadingDocumentoInfo = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _documentoInfo = await _apiService.validarDocumento(documento, tipodoc);
    } catch (e) {
      _errorMessage = extractErrorMessage(e);
      _documentoInfo = null;
    } finally {
      _loadingDocumentoInfo = false;
      notifyListeners();
    }
  }

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
      // Refrescar historial inmediatamente y esperar a que termine
      await loadHistorial();
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
    _errorMessage = null;
    notifyListeners();

    try {
      _historial = await _apiService.getHistorial();
      print('Historial cargado: ${_historial.length} items');
    } catch (e) {
      print('Error cargando historial: $e');
      _errorMessage = extractErrorMessage(e);
      _historial = [];
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

  Future<bool> pagarCuota(String documento, String tipodoc, int nroCuota) async {
    _status = CronogramaStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.pagarCuota(
        documento: documento,
        tipodoc: tipodoc,
        nroCuota: nroCuota,
      );
      
      // Recargar cronograma actual para actualizar estado
      _cronogramaActual = await _apiService.consultarCronograma(documento, tipodoc);
      _status = CronogramaStatus.success;
      
      // Recargar historial para actualizar totales/fechas en el listado
      await loadHistorial();
      return true;
    } catch (e) {
      _errorMessage = extractErrorMessage(e);
      _status = CronogramaStatus.error;
      notifyListeners();
      return false;
    }
  }

  void limpiarCronograma() {
    _cronogramaActual = null;
    _documentoInfo = null;
    _status = CronogramaStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
