import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/cronograma_provider.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../widgets/cuota_card.dart';
import '../widgets/loading_widget.dart';

class GenerarCronogramaScreen extends StatefulWidget {
  const GenerarCronogramaScreen({super.key});

  @override
  State<GenerarCronogramaScreen> createState() =>
      _GenerarCronogramaScreenState();
}

class _GenerarCronogramaScreenState extends State<GenerarCronogramaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentoCtrl = TextEditingController();
  final _cuotasCtrl = TextEditingController();
  String _tipodoc = 'F';

  final List<Map<String, String>> _tiposDoc = [
    {'value': 'F', 'label': 'F — Factura'},
    {'value': 'B', 'label': 'B — Boleta'},
    {'value': 'C', 'label': 'C — Comprobante'},
  ];

  @override
  void dispose() {
    _documentoCtrl.dispose();
    _cuotasCtrl.dispose();
    super.dispose();
  }

  Future<void> _generar() async {
    if (!_formKey.currentState!.validate()) return;

    final crono = context.read<CronogramaProvider>();
    final success = await crono.generarCronograma(
      documento: _documentoCtrl.text.trim().toUpperCase(),
      tipodoc: _tipodoc,
      nroCuotas: int.parse(_cuotasCtrl.text.trim()),
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(crono.errorMessage ?? 'Error al generar cronograma'),
          backgroundColor: AppTheme.rojoError,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _limpiar() {
    _formKey.currentState?.reset();
    _documentoCtrl.clear();
    _cuotasCtrl.clear();
    setState(() => _tipodoc = 'F');
    context.read<CronogramaProvider>().limpiarCronograma();
  }

  Future<void> _compartir() async {
    final crono = context.read<CronogramaProvider>();
    if (crono.cronogramaActual == null) return;

    final c = crono.cronogramaActual!;
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    final buffer = StringBuffer();
    buffer.writeln('📋 CRONOGRAMA DE PAGO');
    buffer.writeln('Documento: ${c.documento.trim()} (${c.tipoDocNombre})');
    buffer.writeln('Total cuotas: ${c.totalCuotas}');
    buffer.writeln('Total a pagar: ${currencyFormat.format(c.totalConInteres)}');
    buffer.writeln('');
    buffer.writeln('DETALLE:');
    for (final cuota in c.cuotas) {
      buffer.writeln(
          'Cuota ${cuota.nroCuota}: ${currencyFormat.format(cuota.valorCuota)} — Vence: ${dateFormat.format(cuota.feVence)}');
    }
    buffer.writeln('');
    buffer.writeln('Generado con CronoApp');

    await Share.share(buffer.toString(),
        subject: 'Cronograma de pago — ${c.documento.trim()}');
  }

  @override
  Widget build(BuildContext context) {
    final crono = context.watch<CronogramaProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Cronograma'),
        actions: [
          if (crono.cronogramaActual != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _limpiar,
              tooltip: 'Nuevo',
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Formulario ────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Datos del documento',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),

                          // Documento
                          TextFormField(
                            controller: _documentoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'N° Documento',
                              hintText: 'Ej: 123456789',
                              prefixIcon: Icon(Icons.document_scanner),
                              helperText: 'Máximo 9 caracteres alfanuméricos',
                            ),
                            validator: Validators.documento,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 9,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]')),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Tipo documento
                          DropdownButtonFormField<String>(
                            value: _tipodoc,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Documento',
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: _tiposDoc
                                .map((t) => DropdownMenuItem(
                                      value: t['value'],
                                      child: Text(t['label']!),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _tipodoc = v ?? 'F'),
                          ),
                          const SizedBox(height: 16),

                          // Número de cuotas
                          TextFormField(
                            controller: _cuotasCtrl,
                            decoration: const InputDecoration(
                              labelText: 'N° de Cuotas',
                              hintText: 'Entre 1 y 36',
                              prefixIcon: Icon(Icons.format_list_numbered),
                              helperText: 'Máximo 36 cuotas',
                            ),
                            validator: Validators.nroCuotas,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 24),

                          ElevatedButton.icon(
                            onPressed: crono.isLoading ? null : _generar,
                            icon: const Icon(Icons.auto_graph),
                            label: const Text(
                              'Generar Cronograma',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ─── Resultado ─────────────────────────────────
                if (crono.cronogramaActual != null) ...[
                  const SizedBox(height: 20),

                  // Header del cronograma
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.azulMarino,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${crono.cronogramaActual!.tipoDocNombre} — ${crono.cronogramaActual!.documento.trim()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ResumenItem(
                                label: 'Cuotas',
                                value: crono.cronogramaActual!.totalCuotas
                                    .toString()),
                            _ResumenItem(
                                label: 'Total',
                                value: currencyFormat
                                    .format(crono.cronogramaActual!.totalConInteres)),
                            _ResumenItem(
                                label: 'Interés',
                                value: currencyFormat
                                    .format(crono.cronogramaActual!.totalInteres)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _compartir,
                                icon: const Icon(Icons.share,
                                    color: Colors.white),
                                label: const Text('Compartir',
                                    style: TextStyle(color: Colors.white)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text('Detalle de cuotas',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  ...crono.cronogramaActual!.cuotas.asMap().entries.map(
                    (entry) => CuotaCard(
                      cuota: entry.value,
                      isProxima: entry.key == 0,
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ],
            ),
          ),

          // Loading overlay
          if (crono.isLoading) const FullScreenLoading(),
        ],
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
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }
}
