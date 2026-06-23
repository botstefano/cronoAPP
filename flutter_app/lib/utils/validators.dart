class Validators {
  static String? documento(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de documento es requerido';
    }
    if (value.trim().length > 9) {
      return 'El documento no puede tener más de 9 caracteres';
    }
    if (!RegExp(r'^[A-Z0-9]+$', caseSensitive: false).hasMatch(value.trim())) {
      return 'Solo letras y números permitidos';
    }
    return null;
  }

  static String? nroCuotas(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El número de cuotas es requerido';
    }
    final n = int.tryParse(value.trim());
    if (n == null) return 'Ingrese un número válido';
    if (n < 1) return 'Mínimo 1 cuota';
    if (n > 36) return 'Máximo 36 cuotas';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'El usuario es requerido';
    if (value.trim().length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}
