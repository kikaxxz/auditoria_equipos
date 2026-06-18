import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'formulario_equipo.dart';
import 'equipo_form_provider.dart';
import 'equipos_list_provider.dart';
import 'generador_pdf.dart';
import 'sincronizacion_service.dart';
import 'image_cache_manager.dart';
import 'imagen_drive_widget.dart';

class DetalleEquipoPage extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> datosIniciales;
  final String rolUsuario;

  const DetalleEquipoPage({
    super.key,
    required this.documentId,
    required Map<String, dynamic> datos,
    required this.rolUsuario,
  }) : datosIniciales = datos;

  Future<void> _eliminarEquipo(BuildContext context, Map<String, dynamic> datosActuales) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1F5C3D)),
          );
        },
      );

      if (datosActuales['fotoPlacaUrl'] != null) {
        try {
          await SincronizacionService().eliminarImagenDrive(datosActuales['fotoPlacaUrl']);
          await ImageCacheManager.eliminarImagen(datosActuales['fotoPlacaUrl']);
        } catch (_) {}
      }
      if (datosActuales['fotoPlacaAdicionalUrl'] != null) {
        try {
          await SincronizacionService().eliminarImagenDrive(datosActuales['fotoPlacaAdicionalUrl']);
          await ImageCacheManager.eliminarImagen(datosActuales['fotoPlacaAdicionalUrl']);
        } catch (_) {}
      }
      if (datosActuales['fotoGeneralUrl'] != null) {
        try {
          await SincronizacionService().eliminarImagenDrive(datosActuales['fotoGeneralUrl']);
          await ImageCacheManager.eliminarImagen(datosActuales['fotoGeneralUrl']);
        } catch (_) {}
      }

      final String? area = datosActuales['areaProceso']?.toString();
      if (area != null && area.trim().isNotEmpty) {
        try {
          final docRef = FirebaseFirestore.instance.collection('metricas').doc('conteos_areas');
          final partes = area.split(' / ');
          final Map<String, dynamic> actualizaciones = {};
          String rutaAcumulada = '';
          for (int i = 0; i < partes.length; i++) {
            if (partes[i].trim().isEmpty) continue;
            if (i == 0) {
              rutaAcumulada = partes[i].trim();
            } else {
              rutaAcumulada += ' / ${partes[i].trim()}';
            }
            String safeKey = rutaAcumulada.replaceAll('/', '-').replaceAll('.', '-');
            actualizaciones[safeKey] = FieldValue.increment(-1);
          }
          if (actualizaciones.isNotEmpty) {
            await docRef.set(actualizaciones, SetOptions(merge: true));
          }
        } catch (_) {}
      }

      await FirebaseFirestore.instance.collection('equipos').doc(documentId).delete();
      
      if (context.mounted) {
        Navigator.of(context).pop();
        
        final listProvider = Provider.of<EquiposListProvider>(context, listen: false);
        listProvider.removerEquipoLocal(documentId);
        listProvider.cargarEquiposPorArea(datosActuales['areaProceso'] ?? '', reiniciar: true);
        
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _confirmarEliminacion(BuildContext context, Map<String, dynamic> datosActuales) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar Equipo'),
          content: const Text('¿Estás seguro de que deseas eliminar este registro de forma permanente?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF5F6368))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC362E)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _eliminarEquipo(context, datosActuales);
              },
              child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _editarEquipo(BuildContext context, Map<String, dynamic> datosActuales) async {
    final formProvider = Provider.of<EquipoFormProvider>(context, listen: false);
    formProvider.cargarLevantamientoExistente(documentId, datosActuales);
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormularioEquipoPage(rolUsuario: rolUsuario)),
    );
    
    if (result == true && context.mounted) {
      final listProvider = Provider.of<EquiposListProvider>(context, listen: false);
      listProvider.cargarEquiposPorArea(datosActuales['areaProceso'] ?? '', reiniciar: true);
    }
  }

  String _formatearFecha(dynamic timestamp) {
    if (timestamp == null) return 'No registrada';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final dia = date.day.toString().padLeft(2, '0');
      final mes = date.month.toString().padLeft(2, '0');
      final anio = date.year;
      final hora = date.hour.toString().padLeft(2, '0');
      final minuto = date.minute.toString().padLeft(2, '0');
      return '$dia/$mes/$anio $hora:$minuto';
    }
    return timestamp.toString();
  }

  Widget _buildFilaDato(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 400) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5F6368),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor.isEmpty ? 'N/D' : valor,
                  style: const TextStyle(
                    color: Color(0xFF1A1C1E),
                    fontSize: 14,
                  ),
                ),
              ],
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    etiqueta,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5F6368),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Text(
                    valor.isEmpty ? 'N/D' : valor,
                    style: const TextStyle(
                      color: Color(0xFF1A1C1E),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSeccionTarjeta(String titulo, List<Widget> hijos) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD9D9D9)),
      ),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F5C3D),
              ),
            ),
            const Divider(color: Color(0xFFD9D9D9), height: 24),
            ...hijos,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('equipos').doc(documentId).snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error'), backgroundColor: const Color(0xFF1F5C3D)),
            body: const Center(child: Text('Error al cargar los datos.')),
          );
        }

        if (snapshot.hasData && !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Equipo Eliminado'), backgroundColor: const Color(0xFF1F5C3D)),
            body: const Center(child: Text('Este equipo ya no existe en la base de datos.')),
          );
        }

        final datos = snapshot.hasData ? (snapshot.data!.data() as Map<String, dynamic>?) ?? datosIniciales : datosIniciales;

        final usuarioActual = FirebaseAuth.instance.currentUser;
        final String currentUid = usuarioActual?.uid.trim() ?? '';
        final String currentEmail = usuarioActual?.email?.trim().toLowerCase() ?? '';
        
        final String docUid = datos['uid_creador']?.toString().trim() ?? '';
        final String docEmail = datos['email_creador']?.toString().trim().toLowerCase() ?? '';
        final String docOriginal = datos['email_original']?.toString().trim().toLowerCase() ?? '';
        
        final bool esPropietario = currentUid.isNotEmpty && (
          docUid == currentUid || 
          docEmail == currentEmail ||
          docOriginal == currentEmail
        );
        
        final bool tienePermisosEliminar = rolUsuario == 'admin' || rolUsuario == 'supervisor';
        final bool esConsultor = rolUsuario == 'consultor';

        final fechaModificacion = datos['ultimaModificacion'] ?? 
                                  datos['sincronizadoEn'] ?? 
                                  datos['actualizadoEn'] ?? 
                                  datos['ultima_modificacion'];

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6F7),
          appBar: AppBar(
            title: Text(datos['codigo'] ?? 'Detalle del Equipo'),
            backgroundColor: const Color(0xFF1F5C3D),
            foregroundColor: const Color(0xFFFFFFFF),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => GeneradorPdf.generarReporteEquipo(context, datos),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSeccionTarjeta('Información Principal', [
                  _buildFilaDato('Código (Tag)', datos['codigo'] ?? ''),
                  _buildFilaDato('Nombre en Sistema', datos['nombre'] ?? ''),
                  _buildFilaDato('Descripción', datos['descripcion'] ?? ''),
                  _buildFilaDato('Equipo Padre', datos['equipoPadre'] ?? ''),
                  _buildFilaDato('Familia', datos['familia'] ?? ''),
                  _buildFilaDato('Área de Proceso', datos['areaProceso'] ?? ''),
                  _buildFilaDato('Ubicación Específica', datos['ubicacionTecnica'] ?? ''),
                  _buildFilaDato('Centro de Costo', datos['centro_costo'] ?? ''),
                ]),
                _buildSeccionTarjeta('Especificaciones Técnicas', [
                  _buildFilaDato('Marca', (datos['fabricante']?.toString().isNotEmpty == true ? datos['fabricante'] : datos['marca']) ?? ''),
                  _buildFilaDato('Modelo', datos['modelo'] ?? ''),
                  _buildFilaDato('Número de Serie', datos['numeroSerie'] ?? ''),
                  _buildFilaDato('Variable Medida', datos['variableMedida'] ?? ''),
                  _buildFilaDato('Señal E/S', datos['senalEntradaSalida'] ?? ''),
                  _buildFilaDato('Rango LRV', datos['rangoLrv']?.toString() ?? ''),
                  _buildFilaDato('Rango URV', datos['rangoUrv']?.toString() ?? ''),
                  _buildFilaDato('Unidad', datos['unidadIngenieria'] ?? ''),
                ]),
                _buildSeccionTarjeta('Estado y Registro', [
                  _buildFilaDato('Última Modificación', _formatearFecha(fechaModificacion)),
                  _buildFilaDato('Plan de Tareas', datos['plan_tareas'] ?? ''),
                  _buildFilaDato('Observaciones', datos['observacion'] ?? ''),
                  _buildFilaDato('Supervisor o Encargado', datos['supervisor'] ?? ''),
                  _buildFilaDato('Notas Importadas', datos['notas'] ?? ''),
                  _buildFilaDato(
                    'Registrado por', 
                    (datos['nombre_creador'] != null && datos['nombre_creador'].toString().trim().isNotEmpty) 
                        ? '${datos['nombre_creador']} (${datos['email_creador']})' 
                        : (datos['email_creador'] ?? 'No registrado')
                  ),
                ]),
                if (datos['fotoPlacaUrl'] != null || datos['fotoPlacaAdicionalUrl'] != null || datos['fotoGeneralUrl'] != null)
                  _buildSeccionTarjeta('Evidencia Visual', [
                    if (datos['fotoPlacaUrl'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Placa Técnica', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ImagenDriveWidget(
                              fileId: datos['fotoPlacaUrl'],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    if (datos['fotoPlacaAdicionalUrl'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Placa Técnica (Adicional)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ImagenDriveWidget(
                              fileId: datos['fotoPlacaAdicionalUrl'],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    if (datos['fotoGeneralUrl'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Equipo General', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5F6368))),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ImagenDriveWidget(
                              fileId: datos['fotoGeneralUrl'],
                            ),
                          ),
                        ],
                      ),
                  ]),
              ],
            ),
          ),
          bottomNavigationBar: esConsultor ? null : SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                border: Border(top: BorderSide(color: Color(0xFFD9D9D9))),
              ),
              child: Row(
                children: [
                  if (tienePermisosEliminar) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC362E),
                          side: const BorderSide(color: Color(0xFFDC362E)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _confirmarEliminacion(context, datos),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('ELIMINAR', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F5C3D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _editarEquipo(context, datos),
                      icon: const Icon(Icons.edit),
                      label: const Text('EDITAR', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}