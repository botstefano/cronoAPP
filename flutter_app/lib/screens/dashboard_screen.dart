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
              // ─── CASO 1: NO TIENE CRONOGRAMA GENERADO ───────────────────
              if (!tieneCronograma) ...[
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
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.azulMarino.withOpacity(0.1),
                                      child: Text(tipoDoc, style: TextStyle(color: AppTheme.azulMarino, fontWeight: FontWeight.bold)),
                                    ),
                                    title: Text(docNum),
                                    subtitle: Text('Deuda: ${currencyFormat.format(totalDeuda)}'),
                                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                                    onTap: () {
                                      // Navegar a generar cronograma con este documento
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => GenerarCronogramaScreen(documento: docNum, tipodoc: tipoDoc)),
                                      );
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

              // ─── CASO 2: SÍ TIENE CRONOGRAMA GENERADO ───────────────────
              if (tieneCronograma) ...[
                // Tarjetas de Resumen del Cronograma
                Row(
                  children: [
                    _SummaryCard(
                      icon: Icons.receipt_long,
                      label: 'N° de Cuotas',
                      value: crono.historial.first.totalCuotas.toString(),
                      color: AppTheme.azulMarino,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      icon: Icons.monetization_on,
                      label: 'Total con Intereses',
                      value: currencyFormat.format(crono.historial.first.totalConInteres),
                      color: AppTheme.verdePago,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lista de documentos para generar nuevos cronogramas
                if (crono.documentosCliente.isNotEmpty) ...[
                  const SizedBox(height: 20),
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
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.azulMarino.withOpacity(0.1),
                                  child: Text(tipoDoc, style: TextStyle(color: AppTheme.azulMarino, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(docNum),
                                subtitle: Text('Deuda: ${currencyFormat.format(totalDeuda)}'),
                                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => GenerarCronogramaScreen(documento: docNum, tipodoc: tipoDoc)),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Próximo Vencimiento
                if (proximaFecha != null && proximoMonto != null)
                  Card(
                    color: AppTheme.naranjaAlerta.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppTheme.naranjaAlerta.withOpacity(0.3)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active, color: AppTheme.naranjaAlerta, size: 28),
                      title: const Text(
                        'Próxima Cuota por Vencer',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Vence: ${dateFormat.format(proximaFecha)}',
                        style: const TextStyle(color: AppTheme.naranjaAlerta, fontSize: 13),
                      ),
                      trailing: Text(
                        currencyFormat.format(proximoMonto),
                        style: const TextStyle(
                          color: AppTheme.naranjaAlerta,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),

                // Calendario de Pagos Inline
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tus Cuotas de Pago',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.azulMarino),
                    ),
                    Row(
                      children: [
                        if (crono.cronogramaActual != null)
                          IconButton(
                            icon: const Icon(Icons.share, color: AppTheme.azulMarino),
                            onPressed: () => _compartir(crono.cronogramaActual),
                            tooltip: 'Compartir cronograma',
                          ),
                        TextButton.icon(
                          onPressed: () async {
                            final item = crono.historial.first;
                            await crono.consultarCronograma(item.documento, item.tipodoc);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CronogramaDetalleScreen(),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.visibility, color: AppTheme.azulMarino),
                          label: const Text('Ver completo'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.azulMarino,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (crono.isLoading)
                  const LoadingWidget(message: 'Cargando cuotas...')
                else if (crono.cronogramaActual != null)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: crono.cronogramaActual!.cuotas.length,
                    itemBuilder: (context, index) {
                      final cuota = crono.cronogramaActual!.cuotas[index];
                      final indexPrimerPendiente = crono.cronogramaActual!.cuotas
                          .indexWhere((c) => c.estado.toLowerCase() == 'p');
                      final isDeTurno = index == indexPrimerPendiente;
                      final isProxima = index == indexPrimerPendiente;

                      return CuotaCard(
                        cuota: cuota,
                        isProxima: isProxima,
                        isCuotaDeTurno: isDeTurno,
                        onPayPressed: () => _confirmarPago(context, crono, cuota),
                      );
                    },
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('No se pudieron cargar los detalles del cronograma.'),
                      ),
                    ),
                  ),
              ],

              // Parámetros
              if (crono.parametros != null) ...[
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.settings, color: AppTheme.azulMarino),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Parámetros vigentes del sistema',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'IGV: ${crono.parametros!['igv']}%  |  Tasa de Interés: ${crono.parametros!['tasaInteres']}%',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarPago(BuildContext context, CronogramaProvider provider, Cuota cuota) {
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Simular Pago de Cuota'),
        content: Text('¿Está seguro de simular el pago de la Cuota N° ${cuota.nroCuota} por un importe total de ${currencyFormat.format(cuota.valorCuota)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final doc = provider.cronogramaActual!.documento;
              final type = provider.cronogramaActual!.tipodoc;
              final success = await provider.pagarCuota(doc, type, cuota.nroCuota);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pago de la Cuota N° ${cuota.nroCuota} registrado con éxito.'),
                      backgroundColor: AppTheme.verdePago,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage ?? 'Error al procesar pago'),
                      backgroundColor: AppTheme.rojoError,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmar Pago'),
          ),
        ],
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

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeudaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DeudaRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color: isBold ? AppTheme.azulMarino : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
