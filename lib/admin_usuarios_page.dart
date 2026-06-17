import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsuariosPage extends StatefulWidget {
  const AdminUsuariosPage({super.key});

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  final _formKey = GlobalKey<FormState>();
  String _nuevoEmail = '';
  String _nuevoRol = 'tecnico';
  String _terminoBusqueda = '';
  late Stream<QuerySnapshot> _usuariosStream;

  @override
  void initState() {
    super.initState();
    _usuariosStream = FirebaseFirestore.instance.collection('usuarios').snapshots();
  }

  void _agregarUsuario() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Autorizar Nuevo Usuario', style: TextStyle(color: Color(0xFF1A1C1E))),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico (Google)',
                    labelStyle: const TextStyle(color: Color(0xFF5F6368)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF1F5C3D), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val == null || !val.contains('@') ? 'Correo inválido' : null,
                  onSaved: (val) => _nuevoEmail = val!.trim().toLowerCase(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _nuevoRol,
                  decoration: InputDecoration(
                    labelText: 'Rol del Sistema',
                    labelStyle: const TextStyle(color: Color(0xFF5F6368)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF1F5C3D), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'tecnico', child: Text('Técnico')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                    DropdownMenuItem(value: 'consultor', child: Text('Consultor')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _nuevoRol = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF5F6368))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F5C3D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Navigator.pop(context);
                  try {
                    await FirebaseFirestore.instance.collection('usuarios').doc(_nuevoEmail).set({
                      'rol': _nuevoRol,
                      'perfil_completado': false,
                    });
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de permisos.')));
                    }
                  }
                }
              },
              child: const Text('AUTORIZAR', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _eliminarUsuario(String email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Revocar Acceso', style: TextStyle(color: Color(0xFF1A1C1E))),
          content: Text('¿Estás seguro de que deseas eliminar a $email de la lista blanca? Perderá acceso inmediato al sistema.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF5F6368))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC362E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await FirebaseFirestore.instance.collection('usuarios').doc(email).delete();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de permisos.')));
                  }
                }
              },
              child: const Text('REVOCAR', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  IconData _obtenerIconoRol(String rol) {
  switch (rol) {
    case 'admin':
      return Icons.admin_panel_settings;
    case 'supervisor':
      return Icons.fact_check;
    case 'consultor':
      return Icons.visibility;
    case 'tecnico':
    default:
      return Icons.engineering;
  }
}

Color _obtenerColorRol(String rol) {
  switch (rol) {
    case 'admin':
      return const Color(0xFF1F5C3D);
    case 'supervisor':
      return const Color(0xFFA6C85A);
    case 'consultor':
      return const Color(0xFF2F7A4F);
    case 'tecnico':
    default:
      return const Color(0xFF5F6368);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: const Text(
          'Control de Accesos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1F5C3D),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Container(
                color: const Color(0xFFF5F6F7),
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar por nombre o correo...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF1F5C3D)),
                    filled: true,
                    fillColor: const Color(0xFFFFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: (valor) {
                    setState(() {
                      _terminoBusqueda = valor.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _usuariosStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D)));
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error al cargar la base de datos.', style: TextStyle(color: Color(0xFF5F6368))));
                    }
                    
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(child: Text('No hay usuarios registrados en el sistema.', style: TextStyle(color: Color(0xFF5F6368))));
                    }

                    final filtrados = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final email = doc.id.toLowerCase();
                      final nombre = (data['nombre_completo'] as String?)?.toLowerCase() ?? '';
                      return email.contains(_terminoBusqueda) || nombre.contains(_terminoBusqueda);
                    }).toList();

                    if (filtrados.isEmpty) {
                      return const Center(
                        child: Text(
                          'No se encontraron coincidencias.',
                          style: TextStyle(color: Color(0xFF5F6368), fontSize: 16),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                      itemCount: filtrados.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                      final email = filtrados[index].id;
                      final data = filtrados[index].data() as Map<String, dynamic>;
                      final rol = data['rol'] ?? 'tecnico';
                      final nombreCompleto = data['nombre_completo'] as String?;

                      final String titulo = (nombreCompleto != null && nombreCompleto.trim().isNotEmpty) 
                          ? nombreCompleto 
                          : 'Pendiente de registro';

                      final colorRol = _obtenerColorRol(rol);
                      final iconoRol = _obtenerIconoRol(rol);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: colorRol.withValues(alpha: 0.1),
                            child: Icon(
                              iconoRol, 
                              color: colorRol,
                            ),
                          ),
                          title: Text(
                            titulo, 
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1C1E))
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(email, style: const TextStyle(color: Color(0xFF5F6368), fontSize: 13)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorRol.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  rol.toUpperCase(), 
                                  style: TextStyle(
                                    color: colorRol,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5
                                  )
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC362E)),
                            onPressed: () => _eliminarUsuario(email),
                          ),
                        ),
                      );
                    },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1F5C3D),
        foregroundColor: Colors.white,
        onPressed: _agregarUsuario,
        icon: const Icon(Icons.person_add),
        label: const Text('Autorizar Correo', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}