import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/cronograma_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_widget.dart';
import 'generar_cronograma_screen.dart';
import 'historial_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CronogramaProvider>().loadHistorial();
      context.read<CronogramaProvider>().loadParametros();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final crono = context.watch<CronogramaProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Calcular resumen desde historial
    final totalCronogramas = crono.historial.length;
    final totalAdeudado = crono.historial.fold<double>(
      0, (sum, h) => sum + h.totalConInteres);
    final proximaFecha = crono.historial
        .where((h) => h.primerVencimiento != null &&
            h.primerVencimiento!.isAfter(DateTime.now()))
        .map((h) => h.primerVencimiento!)
        .fold<DateTime?>(null, (min, date) =>
            min == null || date.isBefore(min) ? date : min);

    return Scaffold(
      backgroundColor: AppTheme.grisClaro,
      appBar: AppBar(
        title: Text('Hola, ${auth.user?.nombre ?? 'Usuario'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, auth),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => crono.loadHistorial(),
        color: AppTheme.azulMarino,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Cards de resumen ──────────────────────────────
              Row(
                children: [
                  _SummaryCard(
                    icon: Icons.receipt_long,
                    label: 'Cronogramas',
                    value: totalCronogramas.toString(),
                    color: AppTheme.azulMarino,
                  ),
                  const SizedBox(width: 12),
                  _SummaryCard(
                    icon: Icons.monetization_on,
                    label: 'Total adeudado',
                    value: currencyFormat.format(totalAdeudado),
                    color: AppTheme.verdePago,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (proximaFecha != null)
                Card(
                  color: AppTheme.naranjaAlerta.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppTheme.naranjaAlerta.withOpacity(0.4)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active,
                        color: AppTheme.naranjaAlerta),
                    title: const Text('Próxima cuota por vencer',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(dateFormat.format(proximaFecha),
                        style: const TextStyle(color: AppTheme.naranjaAlerta)),
                  ),
                ),
              
              // ─── Parámetros ────────────────────────────────────
              if (crono.parametros != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.settings, color: AppTheme.azulMarino),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Parámetros vigentes',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              'IGV: ${crono.parametros!['igv']}%  |  Tasa: ${crono.parametros!['tasaInteres']}%',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Text('Últimos cronogramas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // ─── Lista historial ───────────────────────────────
              if (crono.loadingHistorial)
                const LoadingWidget(message: 'Cargando historial...')
              else if (crono.historial.isEmpty)
                _EmptyHistorial()
              else
                ...crono.historial.take(5).map((h) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.azulMarino,
                          child: Text(h.tipodoc,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(h.documento.trim(),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${h.totalCuotas} cuotas — ${currencyFormat.format(h.totalConInteres)}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HistorialScreen()),
                        ),
                      ),
                    )),

              if (crono.historial.length > 5)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistorialScreen()),
                  ),
                  child: const Text('Ver todo el historial'),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GenerarCronogramaScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Cronograma'),
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

class _EmptyHistorial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No hay cronogramas generados',
                style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 8),
            Text('Presiona el botón + para crear uno',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}
