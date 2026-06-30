import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'formulario_equipo.dart';
import 'equipo_form_provider.dart';
import 'equipos_list_provider.dart';
import 'generador_pdf.dart';
import 'sincronizacion_service.dart';
import 'image_cache_manager.dart';
import 'imagen_drive_widget.dart';

const Color _isaPrimary = Color(0xFF1F5C3D);
const Color _isaBackground = Color(0xFFF5F6F7);
const Color _isaTextPrimary = Color(0xFF1A1C1E);
const Color _isaTextSecondary = Color(0xFF5F6368);
const Color _isaDivider = Color(0xFFEBEBEB);

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
            child: CircularProgressIndicator(strokeWidth: 3, color: _isaPrimary),
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC362E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _confirmarEliminacion(BuildContext context, Map<String, dynamic> datosActuales) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC362E), size: 28),
              SizedBox(width: 12),
              Text('Eliminar Equipo', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas eliminar este registro de forma permanente? Esta acción no se puede deshacer.',
            style: TextStyle(color: _isaTextSecondary, height: 1.5),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCELAR', style: TextStyle(color: _isaTextSecondary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC362E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _eliminarEquipo(context, datosActuales);
              },
              child: const Text('ELIMINAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ],
        );
      },
    );
  }

  void _editarEquipo(BuildContext context, Map<String, dynamic> datosActuales) async {
    HapticFeedback.lightImpact();
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

  void _mostrarDetalleRuta(BuildContext context, String fullPath, String titulo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final partes = fullPath.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E2E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isaTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: partes.asMap().entries.map((entry) {
                      final isLast = entry.key == partes.length - 1;
                      return Chip(
                        label: Text(
                          entry.value,
                          style: TextStyle(
                            color: isLast ? Colors.white : _isaPrimary,
                            fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: isLast ? _isaPrimary : _isaPrimary.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumPath(String path) {
    final partes = path.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (partes.isEmpty) return const Text('No especificado', style: TextStyle(color: _isaTextSecondary, fontStyle: FontStyle.italic));
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: partes.map((part) {
            final isLast = part == partes.last;
            return Container(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLast ? _isaPrimary.withValues(alpha: 0.1) : _isaBackground,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isLast ? _isaPrimary.withValues(alpha: 0.3) : _isaDivider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      part,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                        color: isLast ? _isaPrimary : _isaTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isLast) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFD9D9D9))),
                ],
              ),
            );
          }).toList(),
        );
      }
    );
  }

  Widget _buildFilaDato(BuildContext context, String etiqueta, String valor, {bool esRuta = false}) {
    final bool isEmpty = valor.isEmpty;
    final String displayValue = isEmpty ? 'No especificado' : valor;

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 450;
        return Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: isMobile ? double.infinity : constraints.maxWidth * 0.35,
              child: Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 6.0 : 0),
                child: Text(
                  etiqueta.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9AA0A6),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              flex: isMobile ? 0 : 1,
              child: esRuta && !isEmpty
                  ? _buildPremiumPath(valor)
                  : SelectableText(
                      displayValue,
                      style: TextStyle(
                        color: isEmpty ? const Color(0xFF9AA0A6) : _isaTextPrimary,
                        fontSize: 15,
                        fontWeight: isEmpty ? FontWeight.normal : FontWeight.w500,
                        fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                        height: 1.4,
                      ),
                    ),
            ),
          ],
        );
      },
    );

    if (esRuta && !isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: InkWell(
          onTap: () {
             HapticFeedback.selectionClick();
            _mostrarDetalleRuta(context, valor, etiqueta);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isaDivider),
            ),
            child: Row(
              children: [
                Expanded(child: content),
                const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: Icon(Icons.open_in_full_rounded, size: 18, color: Color(0xFFD9D9D9)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: content,
    );
  }

  Widget _buildSeccionTarjeta(String titulo, IconData icono, List<Widget> hijos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _isaDivider),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1C1E).withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isaPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: _isaPrimary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isaTextPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: _isaDivider, height: 1),
            const SizedBox(height: 16),
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
            appBar: AppBar(title: const Text('Error'), backgroundColor: _isaPrimary),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFDC362E)),
                  const SizedBox(height: 16),
                  Text('Error al cargar los datos: ${snapshot.error}', style: const TextStyle(color: _isaTextSecondary)),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: _isaBackground,
            appBar: AppBar(title: const Text('Equipo Eliminado'), backgroundColor: _isaPrimary),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_rounded, size: 64, color: _isaTextSecondary),
                  SizedBox(height: 16),
                  Text('Este equipo ya no existe en la base de datos.', style: TextStyle(fontSize: 16, color: _isaTextSecondary)),
                ],
              ),
            ),
          );
        }

        final datos = snapshot.hasData ? (snapshot.data!.data() as Map<String, dynamic>?) ?? datosIniciales : datosIniciales;

        final bool puedeEditar = rolUsuario == 'admin' || rolUsuario == 'supervisor' || rolUsuario == 'tecnico';
        final bool puedeEliminar = rolUsuario == 'admin' || rolUsuario == 'supervisor';

        final fechaModificacion = datos['ultimaModificacion'] ?? 
                                  datos['sincronizadoEn'] ?? 
                                  datos['actualizadoEn'] ?? 
                                  datos['ultima_modificacion'];
                                  
        // Extracción del diccionario dinámico
        final Map<String, dynamic> camposDinamicos = datos['camposDinamicos'] != null 
            ? Map<String, dynamic>.from(datos['camposDinamicos']) 
            : {};

        return Scaffold(
          backgroundColor: _isaBackground,
          appBar: AppBar(
            title: Text(
              datos['codigo'] ?? 'Detalle del Equipo',
              style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
            backgroundColor: _isaPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('Descargar Ficha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    GeneradorPdf.generarReporteEquipo(context, datos);
                  },
                ),
              ),
              if (puedeEditar || puedeEliminar)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  onSelected: (value) {
                    if (value == 'editar') {
                      _editarEquipo(context, datos);
                    } else if (value == 'eliminar') {
                      _confirmarEliminacion(context, datos);
                    }
                  },
                  itemBuilder: (context) => [
                    if (puedeEditar)
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, color: _isaPrimary, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Editar Registro',
                              style: TextStyle(color: _isaTextPrimary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    if (puedeEliminar)
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Color(0xFFDC362E), size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Eliminar Equipo',
                              style: TextStyle(color: Color(0xFFDC362E), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  children: [
                    _buildSeccionTarjeta('Información Principal', Icons.info_outline_rounded, [
                      _buildFilaDato(context, 'Código (Tag)', datos['codigo'] ?? ''),
                      _buildFilaDato(context, 'Nombre en Sistema', datos['nombre'] ?? ''),
                      _buildFilaDato(context, 'Descripción', datos['descripcion'] ?? ''),
                      _buildFilaDato(context, 'Equipo Padre', datos['equipoPadre'] ?? ''),
                      _buildFilaDato(context, 'Familia', datos['familia'] ?? ''),
                      _buildFilaDato(context, 'Área de Proceso', datos['areaProceso'] ?? '', esRuta: true),
                      _buildFilaDato(context, 'Ubicación Específica', datos['ubicacionTecnica'] ?? '', esRuta: true),
                      _buildFilaDato(context, 'Centro de Costo', datos['centro_costo'] ?? ''),
                    ]),
                    _buildSeccionTarjeta('Especificaciones Técnicas', Icons.precision_manufacturing_rounded, [
                      _buildFilaDato(context, 'Marca', (datos['fabricante']?.toString().isNotEmpty == true ? datos['fabricante'] : datos['marca']) ?? ''),
                      _buildFilaDato(context, 'Modelo', datos['modelo'] ?? ''),
                      _buildFilaDato(context, 'Número de Serie', datos['numeroSerie'] ?? ''),
                      _buildFilaDato(context, 'Variable Medida', datos['variableMedida'] ?? ''),
                      _buildFilaDato(context, 'Señal E/S', datos['senalEntradaSalida'] ?? ''),
                      _buildFilaDato(context, 'Rango LRV', datos['rangoLrv']?.toString() ?? ''),
                      _buildFilaDato(context, 'Rango URV', datos['rangoUrv']?.toString() ?? ''),
                      _buildFilaDato(context, 'Unidad', datos['unidadIngenieria'] ?? ''),
                    ]),
                    
                    // Renderizado Dinámico de los Campos Adicionales
                    if (camposDinamicos.isNotEmpty)
                      _buildSeccionTarjeta('Campos Personalizados', Icons.label_important_outline_rounded, 
                        camposDinamicos.entries.map((e) => _buildFilaDato(context, e.key, e.value.toString())).toList()
                      ),

                    _buildSeccionTarjeta('Estado y Registro', Icons.history_rounded, [
                      _buildFilaDato(context, 'Última Modificación', _formatearFecha(fechaModificacion)),
                      _buildFilaDato(context, 'Plan de Tareas', datos['plan_tareas'] ?? ''),
                      _buildFilaDato(context, 'Observaciones', datos['observacion'] ?? ''),
                      _buildFilaDato(context, 'Supervisor o Encargado', datos['supervisor'] ?? ''),
                      _buildFilaDato(context, 'Notas Importadas', datos['notas'] ?? ''),
                      _buildFilaDato(
                        context,
                        'Registrado por', 
                        (datos['nombre_creador'] != null && datos['nombre_creador'].toString().trim().isNotEmpty) 
                            ? '${datos['nombre_creador']} (${datos['email_creador']})' 
                            : (datos['email_creador'] ?? 'No registrado')
                      ),
                    ]),
                    if (datos['fotoPlacaUrl'] != null || datos['fotoPlacaAdicionalUrl'] != null || datos['fotoGeneralUrl'] != null)
                      _buildSeccionTarjeta('Evidencia Visual', Icons.photo_camera_rounded, [
                        if (datos['fotoPlacaUrl'] != null) ...[
                          const Text('PLACA TÉCNICA', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF9AA0A6), fontSize: 11, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _isaDivider),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ImagenDriveWidget(fileId: datos['fotoPlacaUrl']),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        if (datos['fotoPlacaAdicionalUrl'] != null) ...[
                          const Text('PLACA TÉCNICA (ADICIONAL)', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF9AA0A6), fontSize: 11, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _isaDivider),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ImagenDriveWidget(fileId: datos['fotoPlacaAdicionalUrl']),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        if (datos['fotoGeneralUrl'] != null) ...[
                          const Text('EQUIPO GENERAL', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF9AA0A6), fontSize: 11, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _isaDivider),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ImagenDriveWidget(fileId: datos['fotoGeneralUrl']),
                            ),
                          ),
                        ],
                      ]),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}