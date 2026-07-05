import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/cronograma_provider.dart';
import '../models/cronograma.dart';
import '../utils/app_theme.dart';
import '../widgets/cuota_card.dart';

class CronogramaDetalleScreen extends StatelessWidget {
  const CronogramaDetalleScreen({super.key});

  Future<void> _compartir(BuildContext context, final cronoActual) async {
    if (cronoActual == null) return;

    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    final buffer = StringBuffer();
    buffer.writeln('📋 CRONOGRAMA DE PAGO');
    buffer.writeln('Documento: ${cronoActual.documento.trim()} (${cronoActual.tipoDocNombre})');
    buffer.writeln('Total cuotas: ${cronoActual.totalCuotas}');
    buffer.writeln('Total a pagar: ${currencyFormat.format(cronoActual.totalConInteres)}');
    buffer.writeln('');
    buffer.writeln('DETALLE:');
    for (final cuota in cronoActual.cuotas) {
      buffer.writeln(
          'Cuota ${cuota.nroCuota}: ${currencyFormat.format(cuota.valorCuota)} — Vence: ${dateFormat.format(cuota.feVence)}');
    }
    buffer.writeln('');
    buffer.writeln('Generado con CronoApp');

    await Share.share(buffer.toString(),
        subject: 'Cronograma de pago — ${cronoActual.documento.trim()}');
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

  @override
  Widget build(BuildContext context) {
    final crono = context.watch<CronogramaProvider>();
    final c = crono.cronogramaActual;
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

    return Scaffold(
      backgroundColor: AppTheme.grisClaro,
      appBar: AppBar(
        title: const Text('Detalles del Cronograma'),
        actions: [
          if (c != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _compartir(context, c),
              tooltip: 'Compartir cronograma',
            ),
        ],
      ),
      body: c == null
          ? const Center(
              child: Text(
                'No hay información del cronograma disponible.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Cabecera Resumen ─────────────────────────────
                  Card(
                    color: AppTheme.azulMarino,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 48,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${c.tipoDocNombre} — ${c.documento.trim()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cronograma activo fraccionado en cuotas',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                          const Divider(color: Colors.white24, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ResumenItem(
                                label: 'N° Cuotas',
                                value: c.totalCuotas.toString(),
                              ),
                              _ResumenItem(
                                label: 'Importe Base',
                                value: currencyFormat.format(c.totalImporte),
                              ),
                              _ResumenItem(
                                label: 'Total a Pagar',
                                value: currencyFormat.format(c.totalConInteres),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                'Interés total: ${currencyFormat.format(c.totalInteres)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'IGV Interés: ${currencyFormat.format(c.totalIgvInteres)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Calendario de Cuotas ─────────────────────────
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, color: AppTheme.azulMarino),
                      SizedBox(width: 8),
                      Text(
                        'Calendario de Cuotas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.azulMarino,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: c.cuotas.length,
                    itemBuilder: (context, index) {
                      final cuota = c.cuotas[index];
                      final indexPrimerPendiente = c.cuotas
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
                  ),
                  const SizedBox(height: 24),

                  // ─── Botones de Acción ────────────────────────────
                  ElevatedButton(
                    onPressed: () {
                      // Volver al Dashboard (pantalla principal)
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.azulMarino,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Volver al Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _ResumenItem extends StatelessWidget {
  final String label;
  final String value;

  const _ResumenItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
