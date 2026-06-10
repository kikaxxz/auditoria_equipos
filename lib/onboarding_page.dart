import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_page.dart';

class OnboardingPage extends StatefulWidget {
  final String email;
  final String rol;

  const OnboardingPage({super.key, required this.email, required this.rol});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  String _primerNombre = '';
  String _segundoNombre = '';
  String _primerApellido = '';
  String _segundoApellido = '';
  bool _guardando = false;

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _guardando = true;
    });

    try {
      // Concatenación en memoria local
      final partesNombre = [
        _primerNombre, 
        _segundoNombre, 
        _primerApellido, 
        _segundoApellido
      ].where((parte) => parte.isNotEmpty).join(' ').trim();
      
      await FirebaseAuth.instance.currentUser?.updateDisplayName(partesNombre);
      
      await FirebaseFirestore.instance.collection('usuarios').doc(widget.email).update({
        'nombre_completo': partesNombre,
        'perfil_completado': true,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(rol: widget.rol),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de acceso: $e')),
        );
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: const Text(
          'Completar Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1F5C3D),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFD9D9D9)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.person_outline, size: 64, color: Color(0xFF1F5C3D)),
                      const SizedBox(height: 16),
                      const Text(
                        'Bienvenido al Sistema ISA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Por favor, ingresa tus datos personales para continuar. Esta acción solo se realiza una vez.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF5F6368)),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        initialValue: widget.email,
                        readOnly: true,
                        style: const TextStyle(
                          color: Color(0xFF1A1C1E),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          filled: true,
                          fillColor: const Color(0xFFF5F6F7),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: widget.rol.toUpperCase(),
                        readOnly: true,
                        style: const TextStyle(
                          color: Color(0xFF1A1C1E),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Rol Asignado',
                          filled: true,
                          fillColor: const Color(0xFFF5F6F7),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isSmallScreen) ...[
                        TextFormField(
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Primer Nombre *',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                          onSaved: (val) => _primerNombre = val!.trim(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Segundo Nombre',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSaved: (val) => _segundoNombre = val?.trim() ?? '',
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Primer Nombre *',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                                onSaved: (val) => _primerNombre = val!.trim(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Segundo Nombre',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onSaved: (val) => _segundoNombre = val?.trim() ?? '',
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      if (isSmallScreen) ...[
                        TextFormField(
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Primer Apellido *',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                          onSaved: (val) => _primerApellido = val!.trim(),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Segundo Apellido',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onSaved: (val) => _segundoApellido = val?.trim() ?? '',
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Primer Apellido *',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                                onSaved: (val) => _primerApellido = val!.trim(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Segundo Apellido',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onSaved: (val) => _segundoApellido = val?.trim() ?? '',
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F5C3D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _guardando ? null : _guardarPerfil,
                        child: _guardando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'GUARDAR Y CONTINUAR',
                                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        icon: const Icon(Icons.logout, color: Color(0xFFDC362E)),
                        label: const Text('Cerrar Sesión', style: TextStyle(color: Color(0xFFDC362E))),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}