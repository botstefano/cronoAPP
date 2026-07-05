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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final provider = context.read<CronogramaProvider>();
    final auth = context.read<AuthProvider>();
    
    // 1. Cargar historial
    await provider.loadHistorial();
    
    // 2. Si ya tiene cronograma, consultar los detalles completos del mismo
    if (provider.historial.isNotEmpty) {
      final item = provider.historial.first;
      await provider.consultarCronograma(item.documento, item.tipodoc);
    } else {
      // Si no tiene cronograma, cargar información de su documento/deuda original
      if (auth.user != null) {
        String type = 'F';
        final docNum = auth.user!.username.trim();
        if (docNum.isNotEmpty) {
          final firstChar = docNum.substring(0, 1).toUpperCase();
          if (['F', 'B', 'C'].contains(firstChar)) {
            type = firstChar;
          }
        }
        await provider.loadDocumentoInfo(docNum, type);
      }
    }
    
    // 3. Cargar parámetros
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
                if (crono.loadingDocumentoInfo)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Cargando información de tu deuda...'),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (crono.documentoInfo != null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.azulMarino, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                'Deuda Pendiente',
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
                            'Actualmente tienes una deuda pendiente de pago asociada a tu cuenta corporativa. Puedes fraccionarla en cuotas mensuales para pagarla cómodamente.',
                            style: TextStyle(color: Colors.grey[600], height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.azulMarino.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                _DeudaRow(
                                  label: 'N° de Documento',
                                  value: auth.user?.username.trim() ?? '',
                                ),
                                _DeudaRow(
                                  label: 'Tipo de Documento',
                                  value: getTipoDocNombre(
                                    auth.user?.username.isNotEmpty == true
                                        ? auth.user!.username.substring(0, 1).toUpperCase()
                                        : 'F',
                                  ),
                                ),
                                _DeudaRow(
                                  label: 'Monto de la Deuda',
                                  value: currencyFormat.format(
                                    double.parse(crono.documentoInfo!['totalDeuda']?.toString() ?? '0.0'),
                                  ),
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const GenerarCronogramaScreen()),
                            ),
                            icon: const Icon(Icons.auto_graph),
                            label: const Text(
                              'Generar Cronograma de Pagos',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    if (crono.cronogramaActual != null)
                      IconButton(
                        icon: const Icon(Icons.share, color: AppTheme.azulMarino),
                        onPressed: () => _compartir(crono.cronogramaActual),
                        tooltip: 'Compartir cronograma',
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
