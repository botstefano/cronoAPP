import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cronograma_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_widget.dart';
import 'cronograma_detalle_screen.dart';

class GenerarCronogramaScreen extends StatefulWidget {
  final String? documento;
  final String? tipodoc;

  const GenerarCronogramaScreen({
    super.key,
    this.documento,
    this.tipodoc,
  });

  @override
  State<GenerarCronogramaScreen> createState() =>
      _GenerarCronogramaScreenState();
}

class _GenerarCronogramaScreenState extends State<GenerarCronogramaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentoCtrl = TextEditingController();
  final _cuotasCtrl = TextEditingController();
  String _tipodoc = 'F';

  @override
  void initState() {
    super.initState();
    // Si se proporcionaron documento y tipodoc, usarlos
    if (widget.documento != null && widget.tipodoc != null) {
      _documentoCtrl.text = widget.documento!;
      _tipodoc = widget.tipodoc!;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Cargar información del documento y su deuda en segundo plano
        context.read<CronogramaProvider>().loadDocumentoInfo(widget.documento!, widget.tipodoc!);
      });
    } else {
      // Si no, usar el username del usuario (comportamiento anterior)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = Provider.of<AuthProvider>(context, listen: false).user;
        if (user != null) {
          _documentoCtrl.text = user.username.trim();
          String type = 'F';
          if (user.username.isNotEmpty) {
            final firstChar = user.username.substring(0, 1).toUpperCase();
            if (['F', 'B', 'C'].contains(firstChar)) {
              type = firstChar;
            }
          }
          setState(() => _tipodoc = type);
          
          // Cargar información del documento y su deuda en segundo plano
          context.read<CronogramaProvider>().loadDocumentoInfo(user.username, type);
        }
      });
    }
  }

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

    if (success && mounted) {
      // Navegar a la pantalla de detalle del cronograma recién generado
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CronogramaDetalleScreen(),
        ),
      );
      _cuotasCtrl.clear();
    } else if (!success && mounted) {
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

  @override
  Widget build(BuildContext context) {
    final crono = context.watch<CronogramaProvider>();
    final auth = context.watch<AuthProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');

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
        title: const Text('Nuevo Cronograma'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Tarjeta Informativa Deuda ─────────────────────
                if (crono.loadingDocumentoInfo)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (crono.documentoInfo != null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.azulMarino),
                              const SizedBox(width: 8),
                              Text(
                                'Deuda Pendiente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _InfoRow(
                            label: 'Cliente',
                            value: crono.documentoInfo!['cliente'] ?? auth.user?.nombre ?? '',
                          ),
                          _InfoRow(
                            label: 'Documento',
                            value: '${getTipoDocNombre(_tipodoc)}: ${_documentoCtrl.text}',
                          ),
                          _InfoRow(
                            label: 'Total Deuda',
                            value: currencyFormat.format(
                              double.parse(crono.documentoInfo!['totalDeuda']?.toString() ?? '0.0'),
                            ),
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    color: AppTheme.rojoError.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.rojoError),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              crono.errorMessage ?? 'No se pudo obtener información del documento actual.',
                              style: const TextStyle(color: AppTheme.rojoError),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ─── Formulario ────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Parámetros de Fraccionamiento',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),

                          // Número de cuotas
                          TextFormField(
                            controller: _cuotasCtrl,
                            decoration: const InputDecoration(
                              labelText: 'N° de Cuotas',
                              hintText: 'Entre 1 y 36',
                              prefixIcon: Icon(Icons.format_list_numbered),
                              helperText: 'Elige en cuántas cuotas mensuales deseas pagar',
                            ),
                            validator: Validators.nroCuotas,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          const SizedBox(height: 24),

                          ElevatedButton.icon(
                            onPressed: (crono.isLoading || crono.documentoInfo == null) ? null : _generar,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _InfoRow({
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
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
