class Cuota {
  final int nroCuota;
  final double importe;
  final double interes;
  final double igvInteres;
  final double valorCuota;
  final DateTime feVence;
  final String estado; // 'p' = pendiente, 'c' = cancelado/pagado

  Cuota({
    required this.nroCuota,
    required this.importe,
    required this.interes,
    required this.igvInteres,
    required this.valorCuota,
    required this.feVence,
    required this.estado,
  });

  factory Cuota.fromJson(Map<String, dynamic> json) {
    return Cuota(
      nroCuota: json['nroCuota'],
      importe: double.parse(json['importe'].toString()),
      interes: double.parse(json['interes'].toString()),
      igvInteres: double.parse(json['igvInteres'].toString()),
      valorCuota: double.parse(json['valorCuota'].toString()),
      feVence: DateTime.parse(json['feVence']),
      estado: json['estado'] ?? 'p',
    );
  }

  Map<String, dynamic> toJson() => {
        'nroCuota': nroCuota,
        'importe': importe,
        'interes': interes,
        'igvInteres': igvInteres,
        'valorCuota': valorCuota,
        'feVence': feVence.toIso8601String(),
        'estado': estado,
      };
}

class Cronograma {
  final String documento;
  final String tipodoc;
  final DateTime? fechaGeneracion;
  final int totalCuotas;
  final List<Cuota> cuotas;

  Cronograma({
    required this.documento,
    required this.tipodoc,
    this.fechaGeneracion,
    required this.totalCuotas,
    required this.cuotas,
  });

  double get totalImporte => cuotas.fold(0, (sum, c) => sum + c.importe);
  double get totalInteres => cuotas.fold(0, (sum, c) => sum + c.interes);
  double get totalIgvInteres => cuotas.fold(0, (sum, c) => sum + c.igvInteres);
  double get totalConInteres => cuotas.fold(0, (sum, c) => sum + c.valorCuota);
  DateTime? get primerVencimiento => cuotas.isNotEmpty ? cuotas.first.feVence : null;
  DateTime? get ultimoVencimiento => cuotas.isNotEmpty ? cuotas.last.feVence : null;

  String get tipoDocNombre {
    switch (tipodoc) {
      case 'F':
        return 'Factura';
      case 'B':
        return 'Boleta';
      case 'C':
        return 'Comprobante';
      default:
        return tipodoc;
    }
  }

  factory Cronograma.fromJson(Map<String, dynamic> json) {
    return Cronograma(
      documento: json['documento'],
      tipodoc: json['tipodoc'],
      fechaGeneracion: json['fechaGeneracion'] != null
          ? DateTime.parse(json['fechaGeneracion'])
          : null,
      totalCuotas: json['totalCuotas'],
      cuotas: (json['cronograma'] as List)
          .map((c) => Cuota.fromJson(c))
          .toList(),
    );
  }
}

class HistorialItem {
  final String documento;
  final String tipodoc;
  final int totalCuotas;
  final double totalImporte;
  final double totalConInteres;
  final DateTime? primerVencimiento;
  final DateTime? ultimoVencimiento;

  HistorialItem({
    required this.documento,
    required this.tipodoc,
    required this.totalCuotas,
    required this.totalImporte,
    required this.totalConInteres,
    this.primerVencimiento,
    this.ultimoVencimiento,
  });

  factory HistorialItem.fromJson(Map<String, dynamic> json) {
    return HistorialItem(
      documento: json['documento'],
      tipodoc: json['tipodoc'],
      totalCuotas: int.parse(json['totalCuotas'].toString()),
      totalImporte: double.parse(json['totalImporte'].toString()),
      totalConInteres: double.parse(json['totalConInteres'].toString()),
      primerVencimiento: json['primerVencimiento'] != null
          ? DateTime.parse(json['primerVencimiento'])
          : null,
      ultimoVencimiento: json['ultimoVencimiento'] != null
          ? DateTime.parse(json['ultimoVencimiento'])
          : null,
    );
  }
}
