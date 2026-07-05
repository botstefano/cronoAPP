import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cronograma.dart';
import '../utils/app_theme.dart';

class CuotaCard extends StatelessWidget {
  final Cuota cuota;
  final bool isProxima;
  final bool isCuotaDeTurno;
  final VoidCallback? onPayPressed;

  const CuotaCard({
    super.key,
    required this.cuota,
    this.isProxima = false,
    this.isCuotaDeTurno = false,
    this.onPayPressed,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/ ');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final vencida = cuota.feVence.isBefore(DateTime.now()) && cuota.estado.toLowerCase() != 'c';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isProxima ? 5 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isProxima
            ? const BorderSide(color: AppTheme.azulMarino, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.azulMarino,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Cuota ${cuota.nroCuota}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (isProxima) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.naranjaAlerta.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'PRÓXIMA',
                          style: TextStyle(
                            color: AppTheme.naranjaAlerta,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      vencida ? Icons.warning_amber : Icons.calendar_today,
                      size: 14,
                      color: vencida ? AppTheme.rojoError : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(cuota.feVence),
                      style: TextStyle(
                        fontSize: 13,
                        color: vencida ? AppTheme.rojoError : Colors.grey[700],
                        fontWeight: vencida ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    label: 'Importe',
                    value: currencyFormat.format(cuota.importe),
                    icon: Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'Interés',
                    value: currencyFormat.format(cuota.interes),
                    icon: Icons.trending_up,
                    color: Colors.orange[700]!,
                  ),
                ),
                Expanded(
                  child: _InfoItem(
                    label: 'IGV Int.',
                    value: currencyFormat.format(cuota.igvInteres),
                    icon: Icons.receipt,
                    color: Colors.purple[700]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.azulMarino.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'TOTAL: ${currencyFormat.format(cuota.valorCuota)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.azulMarino,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Estado / Badge
                if (cuota.estado.toLowerCase() == 'c')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.verdePago.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.verdePago, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'PAGADA',
                          style: TextStyle(
                            color: AppTheme.verdePago,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Pendiente
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCuotaDeTurno
                          ? AppTheme.naranjaAlerta.withOpacity(0.12)
                          : Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCuotaDeTurno ? Icons.play_circle_outline : Icons.lock_outline,
                          color: isCuotaDeTurno ? AppTheme.naranjaAlerta : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isCuotaDeTurno ? 'SIGUIENTE A PAGAR' : 'BLOQUEADA',
                          style: TextStyle(
                            color: isCuotaDeTurno ? AppTheme.naranjaAlerta : Colors.grey[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Botón de Pago si es la cuota de turno activa
                  if (isCuotaDeTurno && onPayPressed != null)
                    ElevatedButton.icon(
                      onPressed: onPayPressed,
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text(
                        'PAGAR',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.azulMarino,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppTheme.azulMarino,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        Text(value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            )),
      ],
    );
  }
}
