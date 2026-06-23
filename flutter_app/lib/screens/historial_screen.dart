import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/cronograma_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_widget.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  String _filtro = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CronogramaProvider>().loadHistorial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final crono = context.watch<CronogramaProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    final historialFiltrado = crono.historial.where((h) {
      if (_filtro.isEmpty) return true;
      return h.documento.toLowerCase().contains(_filtro.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Cronogramas'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por documento...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filtro.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _filtro = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _filtro = v),
            ),
          ),

          if (crono.loadingHistorial)
            const Expanded(
                child: LoadingWidget(message: 'Cargando historial...'))
          else if (historialFiltrado.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _filtro.isEmpty
                          ? 'No hay cronogramas generados'
                          : 'No se encontraron resultados',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => crono.loadHistorial(),
                color: AppTheme.azulMarino,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: historialFiltrado.length,
                  itemBuilder: (context, index) {
                    final h = historialFiltrado[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.azulMarino,
                          child: Text(
                            h.tipodoc,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          h.documento.trim(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${h.totalCuotas} cuotas — ${currencyFormat.format(h.totalConInteres)}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              children: [
                                const Divider(),
                                _DetailRow(
                                  label: 'Importe base',
                                  value: currencyFormat.format(h.totalImporte),
                                ),
                                _DetailRow(
                                  label: 'Total con interés',
                                  value: currencyFormat.format(h.totalConInteres),
                                  bold: true,
                                ),
                                if (h.primerVencimiento != null)
                                  _DetailRow(
                                    label: 'Primer vencimiento',
                                    value: dateFormat.format(h.primerVencimiento!),
                                  ),
                                if (h.ultimoVencimiento != null)
                                  _DetailRow(
                                    label: 'Último vencimiento',
                                    value: dateFormat.format(h.ultimoVencimiento!),
                                  ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    crono.consultarCronograma(
                                        h.documento.trim(), h.tipodoc);
                                    // Navegar a detalle
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Ver cronograma completo'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DetailRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? AppTheme.azulMarino : null,
            ),
          ),
        ],
      ),
    );
  }
}
