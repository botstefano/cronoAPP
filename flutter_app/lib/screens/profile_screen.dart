import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  
  bool _loading = false;
  bool _hidePasswords = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        _nombreCtrl.text = user.nombre;
      }
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();

    final success = await auth.updateProfile(
      nombre: _nombreCtrl.text.trim(),
      currentPassword: _currentPasswordCtrl.text.isNotEmpty ? _currentPasswordCtrl.text : null,
      newPassword: _newPasswordCtrl.text.isNotEmpty ? _newPasswordCtrl.text : null,
    );

    setState(() => _loading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppTheme.verdePago,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Error al actualizar perfil'),
            backgroundColor: AppTheme.rojoError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppTheme.grisClaro,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card informativa del Usuario
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 36,
                            backgroundColor: AppTheme.azulMarino,
                            child: Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.nombre ?? 'Cargando...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Documento: ${user?.username ?? ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campos de datos
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Editar Información',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nombre de Perfil
                          TextFormField(
                            controller: _nombreCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre / Razón Social',
                              prefixIcon: Icon(Icons.badge),
                              helperText: 'Nombre que se mostrará en los reportes y saludo.',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'El nombre es obligatorio';
                              }
                              if (v.trim().length < 3) {
                                return 'Debe tener al menos 3 caracteres';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cambiar Contraseña (Opcional)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Seguridad (Cambiar Contraseña)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _hidePasswords ? Icons.visibility : Icons.visibility_off,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _hidePasswords = !_hidePasswords);
                                },
                                tooltip: 'Mostrar contraseñas',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Contraseña Actual
                          TextFormField(
                            controller: _currentPasswordCtrl,
                            obscureText: _hidePasswords,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña Actual',
                              prefixIcon: Icon(Icons.lock_open),
                              helperText: 'Requerida únicamente si deseas cambiar la contraseña.',
                            ),
                            validator: (v) {
                              if (_newPasswordCtrl.text.isNotEmpty && (v == null || v.isEmpty)) {
                                return 'Ingresa tu contraseña actual';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Nueva Contraseña
                          TextFormField(
                            controller: _newPasswordCtrl,
                            obscureText: _hidePasswords,
                            decoration: const InputDecoration(
                              labelText: 'Nueva Contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                              helperText: 'Mínimo 6 caracteres.',
                            ),
                            validator: (v) {
                              if (v != null && v.isNotEmpty && v.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirmar Nueva Contraseña
                          TextFormField(
                            controller: _confirmPasswordCtrl,
                            obscureText: _hidePasswords,
                            decoration: const InputDecoration(
                              labelText: 'Confirmar Nueva Contraseña',
                              prefixIcon: Icon(Icons.lock),
                            ),
                            validator: (v) {
                              if (_newPasswordCtrl.text.isNotEmpty && v != _newPasswordCtrl.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Guardar Cambios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          if (_loading)
            const ContainerLoadingOverlay(),
        ],
      ),
    );
  }
}

class ContainerLoadingOverlay extends StatelessWidget {
  const ContainerLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Guardando cambios...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
