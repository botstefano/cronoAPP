import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/cronograma_provider.dart';
import '../models/cronograma.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/cuota_card.dart';
import 'generar_cronograma_screen.dart';
import 'profile_screen.dart';
import 'cronograma_detalle_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    final provider = context.read<CronogramaProvider>();
    final auth = context.read<AuthProvider>();
    
    // 1. Cargar documentos del cliente
    await provider.loadDocumentosCliente();
    
    // 2. Cargar historial
    await provider.loadHistorial();
    
    // 3. Si ya tiene cronograma, consultar los detalles completos del mismo
    if (provider.historial.isNotEmpty) {
      final item = provider.historial.first;
      await provider.consultarCronograma(item.documento, item.tipodoc);
    } else {
      // Si no tiene cronograma, cargar información del primer documento
      if (provider.documentosCliente.isNotEmpty) {
        final doc = provider.documentosCliente.first;
        await provider.loadDocumentoInfo(doc['documento'], doc['tipodoc']);
      }
    }
    
    // 4. Cargar parámetros
    await provider.loadParametros();
  }

  Future<void> _compartir(final cronoActual) async {
    if (cronoActual == null) return;

    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    final buffer = StringBuffer();
    buffer.writeln('📋 CRONOGRAMA DE PAGO ACTIVO');
    buffer.writeln('Documento: ${cronoActual.documento.trim()} (${cronoActual.tipoDocNombre})');
    buffer.writeln('Total cuotas: ${cronoActual.totalCuotas}');
    buffer.writeln('Total a pagar: ${currencyFormat.format(cronoActual.totalConInteres)}');
    buffer.writeln('');
    buffer.writeln('DETALLE DE CUOTAS:');
    for (final cuota in cronoActual.cuotas) {
      buffer.writeln(
          'Cuota ${cuota.nroCuota}: ${currencyFormat.format(cuota.valorCuota)} — Vence: ${dateFormat.format(cuota.feVence)}');
    }
    buffer.writeln('');
    buffer.writeln('Generado con CronoApp');

    await Share.share(buffer.toString(),
        subject: 'Cronograma de pago activo — ${cronoActual.documento.trim()}');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final crono = context.watch<CronogramaProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    final tieneCronograma = crono.historial.isNotEmpty;

    // Calcular próxima cuota del cronograma actual
    DateTime? proximaFecha;
    double? proximoMonto;
    if (crono.cronogramaActual != null && crono.cronogramaActual!.cuotas.isNotEmpty) {
      final proxCuota = crono.cronogramaActual!.cuotas.first;
      proximaFecha = proxCuota.feVence;
      proximoMonto = proxCuota.valorCuota;
    }

    String getTipoDocNombre(String type) {
      switch (type) {
        case 'F': return 'Factura';
        case 'B': return 'Boleta';
        case 'C': return 'Comprobante';
        default: return type;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.grisClaro,
      appBar: AppBar(
        title: Text('Hola, ${auth.user?.nombre ?? 'Usuario'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            tooltip: 'Mi Perfil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, auth),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.azulMarino,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── LISTA DE DOCUMENTOS (SIEMPRE VISIBLE) ───────────────────
              if (crono.loadingDocumentosCliente)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cargando tus documentos...'),
                        ],
                      ),
                    ),
                  ),
                )
              else if (crono.documentosCliente.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.folder_open, color: AppTheme.azulMarino, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tus Documentos (${crono.documentosCliente.length})',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                'Selecciona un documento para generar su cronograma de pagos.',
                                style: TextStyle(color: Colors.grey[600], height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              ...crono.documentosCliente.map((doc) {
                                final docNum = doc['documento'];
                                final tipoDoc = doc['tipodoc'];
                                final totalDeuda = double.parse(doc['totaldeuda']?.toString() ?? '0.0');

                                // Verificar si este documento ya tiene cronograma
                                final tieneCronograma = crono.historial.any(
                                  (item) => item.documento == docNum && item.tipodoc == tipoDoc
                                );

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.azulMarino.withOpacity(0.1),
                                      child: Text(tipoDoc, style: TextStyle(color: AppTheme.azulMarino, fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(docNum),
                                    subtitle: Text('Deuda: ${currencyFormat.format(totalDeuda)}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (tieneCronograma)
                                          Icon(Icons.check_circle, color: AppTheme.verdePago, size: 20),
                                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                                      ],
                                    ),
                                    onTap: () async {
                                      if (tieneCronograma) {
                                        // Navegar a detalle del cronograma existente
                                        await crono.consultarCronograma(docNum, tipoDoc);
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const CronogramaDetalleScreen()),
                                          );
                                        }
                                      } else {
                                        // Navegar a generar nuevo cronograma
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => GenerarCronogramaScreen(documento: docNum, tipodoc: tipoDoc)),
                                        );
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Card(
                    color: AppTheme.rojoError.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.rojoError),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  crono.errorMessage ?? 'No tienes una deuda activa registrada o hubo un error al consultar.',
                                  style: const TextStyle(color: AppTheme.rojoError, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshData,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Está seguro que desea salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
