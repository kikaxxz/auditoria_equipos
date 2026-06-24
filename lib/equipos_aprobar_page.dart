import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sincronizacion_service.dart';
import 'configuracion_provider.dart';

class _VisorImagenDialogo extends StatefulWidget {
  final String titulo;
  final String fileId;

  const _VisorImagenDialogo({required this.titulo, required this.fileId});

  @override
  State<_VisorImagenDialogo> createState() => _VisorImagenDialogoState();
}

class _VisorImagenDialogoState extends State<_VisorImagenDialogo> {
  static final Map<String, String> _cacheImagenesBase64 = {};
  late Future<String?> _futureImagen;

  @override
  void initState() {
    super.initState();
    if (_cacheImagenesBase64.containsKey(widget.fileId)) {
      _futureImagen = Future.value(_cacheImagenesBase64[widget.fileId]);
    } else {
      _futureImagen = SincronizacionService.descargarImagenDriveBase64(widget.fileId).then((base64) {
        if (base64 != null) {
          _cacheImagenesBase64[widget.fileId] = base64;
        }
        return base64;
      });
    }
  }

  void _mostrarImagenCompleta(BuildContext context, String base64Data, String titulo) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Hero(
              tag: widget.fileId,
              child: Image.memory(base64Decode(base64Data)),
            ),
          ),
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5F6368), fontSize: 12, letterSpacing: 0.5),
                ),
                const Icon(Icons.zoom_out_map, size: 16, color: Color(0xFF5F6368)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEBEBEB)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: FutureBuilder<String?>(
                key: ValueKey(_futureImagen),
                future: _futureImagen,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 150,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1F5C3D),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    try {
                      return GestureDetector(
                        onTap: () => _mostrarImagenCompleta(context, snapshot.data!, widget.titulo),
                        child: Hero(
                          tag: widget.fileId,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: Image.memory(
                                base64Decode(snapshot.data!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    } catch (_) {
                      return _buildErrorImagen();
                    }
                  }
                  return _buildErrorImagen();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorImagen() {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, color: Color(0xFFD9D9D9), size: 40),
            SizedBox(height: 12),
            Text('Evidencia gráfica no disponible', style: TextStyle(color: Color(0xFF5F6368), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class EquiposAprobarPage extends StatefulWidget {
  final String rol;

  const EquiposAprobarPage({super.key, required this.rol});

  @override
  State<EquiposAprobarPage> createState() => _EquiposAprobarPageState();
}

class _EquiposAprobarPageState extends State<EquiposAprobarPage> {
  // Lógica de Sincronización inalterada
  Future<void> _aprobarSolicitud(String idPendiente, Map<String, dynamic> datosPropuestos, String tipoOperacion, String? idOriginal) async {
    try {
      final List<String> urlsAEliminar = [];
      if (datosPropuestos.containsKey('fotoPlacaUrlAntigua')) { urlsAEliminar.add(datosPropuestos['fotoPlacaUrlAntigua']); datosPropuestos.remove('fotoPlacaUrlAntigua'); }
      if (datosPropuestos.containsKey('fotoPlacaAdicionalUrlAntigua')) { urlsAEliminar.add(datosPropuestos['fotoPlacaAdicionalUrlAntigua']); datosPropuestos.remove('fotoPlacaAdicionalUrlAntigua'); }
      if (datosPropuestos.containsKey('fotoGeneralUrlAntigua')) { urlsAEliminar.add(datosPropuestos['fotoGeneralUrlAntigua']); datosPropuestos.remove('fotoGeneralUrlAntigua'); }
      
      datosPropuestos.remove('urls_subidas_temporalmente');

      for (String url in urlsAEliminar) {
        SincronizacionService().eliminarImagenDrive(url);
      }

      String? areaAntigua;
      if (tipoOperacion == 'modificacion' && idOriginal != null) {
        final docOriginal = await FirebaseFirestore.instance.collection('equipos').doc(idOriginal).get();
        if (docOriginal.exists) {
          areaAntigua = docOriginal.data()?['areaProceso']?.toString();
        }
      }

      final batch = FirebaseFirestore.instance.batch();
      final refPendiente = FirebaseFirestore.instance.collection('ediciones_pendientes').doc(idPendiente);

      if (tipoOperacion == 'creacion') {
        final refNuevoEquipo = FirebaseFirestore.instance.collection('equipos').doc();
        datosPropuestos['sincronizadoEn'] = FieldValue.serverTimestamp();
        batch.set(refNuevoEquipo, datosPropuestos);
      } else if (tipoOperacion == 'modificacion' && idOriginal != null && idOriginal.isNotEmpty) {
        final refEquipoActual = FirebaseFirestore.instance.collection('equipos').doc(idOriginal);
        datosPropuestos['actualizadoEn'] = FieldValue.serverTimestamp();
        batch.update(refEquipoActual, datosPropuestos);
      }

      final docMetricasRef = FirebaseFirestore.instance.collection('metricas').doc('conteos_areas');
      final Map<String, dynamic> actualizacionesContadores = {};

      void generarActualizaciones(String area, int incremento) {
        final partes = area.split(' / ');
        String rutaAcumulada = '';
        for (int i = 0; i < partes.length; i++) {
          if (partes[i].trim().isEmpty) continue;
          rutaAcumulada = i == 0 ? partes[i].trim() : '$rutaAcumulada / ${partes[i].trim()}';
          String safeKey = rutaAcumulada.replaceAll('/', '-').replaceAll('.', '-');
          if (safeKey.isNotEmpty) {
            actualizacionesContadores[safeKey] = FieldValue.increment(incremento);
          }
        }
      }

      final String? areaNueva = datosPropuestos['areaProceso']?.toString();

      if (tipoOperacion == 'creacion' && areaNueva != null && areaNueva.trim().isNotEmpty) {
        generarActualizaciones(areaNueva, 1);
      } else if (tipoOperacion == 'modificacion') {
        if (areaAntigua != areaNueva) {
          if (areaAntigua != null && areaAntigua.trim().isNotEmpty) { generarActualizaciones(areaAntigua, -1); }
          if (areaNueva != null && areaNueva.trim().isNotEmpty) { generarActualizaciones(areaNueva, 1); }
        }
      }

      if (actualizacionesContadores.isNotEmpty) {
        batch.set(docMetricasRef, actualizacionesContadores, SetOptions(merge: true));
      }

      batch.delete(refPendiente);
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud aprobada e indicadores actualizados', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF1F5C3D), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar la aprobación'), backgroundColor: Color(0xFFDC362E), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _rechazarSolicitud(String idPendiente) async {
    final TextEditingController motivoController = TextEditingController();

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Devolver a Técnico', style: TextStyle(color: Color(0xFFDC362E), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Especifique el motivo para que el operador pueda corregir el levantamiento:', style: TextStyle(fontSize: 14, color: Color(0xFF5F6368))),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo de corrección',
                alignLabelWithHint: true,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDC362E))),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF5F6368))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC362E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (motivoController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('DEVOLVER', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (!mounted) return;
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D))),
        );

        await FirebaseFirestore.instance.collection('ediciones_pendientes').doc(idPendiente).update({
          'estado': 'rechazado',
          'motivo_rechazo': motivoController.text.trim(),
          'fecha_rechazo': FieldValue.serverTimestamp(),
          'rechazado_por': FirebaseAuth.instance.currentUser?.email,
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro devuelto al técnico exitosamente.'), backgroundColor: Color(0xFFF57F17), behavior: SnackBarBehavior.floating),
          );
          Navigator.pop(context); 
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al procesar la devolución: $e'), backgroundColor: const Color(0xFFDC362E), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  Widget _buildTreeSelectionNode(TreeNode node, ConfiguracionProvider config, Map<String, dynamic> datosEditados, StateSetter setStateDialog, BuildContext context) {
    if (node.isLeaf) {
      return ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 24, top: 4, bottom: 4),
        title: Text(node.name, style: const TextStyle(fontSize: 14, color: Color(0xFF1A1C1E))),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF1F5C3D).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.device_hub, color: Color(0xFF1F5C3D), size: 18),
        ),
        trailing: const Icon(Icons.check_circle_outline, color: Color(0xFF1F5C3D)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setStateDialog(() {
            datosEditados['areaProceso'] = node.fullPath;
          });
          Navigator.pop(context);
        },
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.only(left: 16, right: 24),
        title: Text(node.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E))),
        leading: const Icon(Icons.folder_open, color: Color(0xFF1F5C3D)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: node.children.values.map((c) => _buildTreeSelectionNode(c, config, datosEditados, setStateDialog, context)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorArea(BuildContext context, ConfiguracionProvider config, Map<String, dynamic> datosEditados, StateSetter setStateDialog) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEBEBEB)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Navegador de Ubicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F5C3D))),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF5F6368)),
                      splashRadius: 24,
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                  children: config.arbolJerarquico.children.values.map((child) => _buildTreeSelectionNode(child, config, datosEditados, setStateDialog, bottomSheetContext)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoRevision(BuildContext context, String idPendiente, Map<String, dynamic> documento) {
    final datosPropuestosOriginales = documento['datos_propuestos'] as Map<String, dynamic>? ?? {};
    
    String? idOriginal = documento['id_equipo_original'] ?? 
                         datosPropuestosOriginales['id_equipo_original'] ?? 
                         datosPropuestosOriginales['id_documento'];

    if (idOriginal != null && idOriginal.trim().isEmpty) {
      idOriginal = null;
    }

    String tipoOperacion = documento['tipo_operacion'] ?? datosPropuestosOriginales['tipo_operacion'] ?? 'creacion';
    
    if (tipoOperacion == 'modificacion' && idOriginal == null) {
      tipoOperacion = 'creacion';
    }
    
    Map<String, dynamic> datosEditados = Map.from(datosPropuestosOriginales);
    bool enModoEdicion = false;
    final config = Provider.of<ConfiguracionProvider>(context, listen: false);

    Future<DocumentSnapshot>? futureOriginalDoc;
    if (tipoOperacion == 'modificacion' && idOriginal != null) {
      futureOriginalDoc = FirebaseFirestore.instance.collection('equipos').doc(idOriginal).get();
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 700,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tipoOperacion == 'creacion' ? 'Revisión de Nuevo Equipo' : 'Revisión de Modificación',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F5C3D)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tag: ${datosPropuestosOriginales['codigo'] ?? 'Sin asignar'}',
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: enModoEdicion ? 'Ver Vista Previa' : 'Editar Registro',
                                child: IconButton(
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, anim) => RotationTransition(turns: child.key == const ValueKey('edit') ? Tween<double>(begin: 0.75, end: 1).animate(anim) : anim, child: FadeTransition(opacity: anim, child: child)),
                                    child: Icon(
                                      enModoEdicion ? Icons.visibility : Icons.edit_document, 
                                      key: ValueKey(enModoEdicion ? 'view' : 'edit'),
                                      color: const Color(0xFF1F5C3D),
                                    ),
                                  ),
                                  splashRadius: 24,
                                  onPressed: () => setStateDialog(() => enModoEdicion = !enModoEdicion),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close, color: Color(0xFF5F6368)),
                                splashRadius: 24,
                                onPressed: () => Navigator.pop(dialogContext),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          )
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFEBEBEB))),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: enModoEdicion 
                            ? _buildVistaEdicion(context, datosEditados, config, setStateDialog)
                            : (tipoOperacion == 'creacion'
                                ? _buildVistaCreacion(datosEditados)
                                : _buildVistaModificacion(idOriginal, datosEditados, futureOriginalDoc)),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Color(0xFFEBEBEB))),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _rechazarSolicitud(idPendiente),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFDC362E),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Devolver', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline, size: 20),
                            label: Text(enModoEdicion ? 'Aprobar Cambios' : 'Aprobar Solicitud', style: const TextStyle(fontWeight: FontWeight.w600)),
                            onPressed: () {
                              bool fueModificado = false;
                              for (var key in datosEditados.keys) {
                                if (datosEditados[key] != datosPropuestosOriginales[key]) {
                                  fueModificado = true;
                                  break;
                                }
                              }

                              if (fueModificado) {
                                final adminRef = FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Admin';
                                final originalRef = datosEditados['solicitado_por'] ?? 'Técnico';
                                if (!originalRef.contains('Editado por')) {
                                  datosEditados['solicitado_por'] = '$originalRef / Editado por $adminRef';
                                }
                              }
                              _aprobarSolicitud(idPendiente, datosEditados, tipoOperacion, idOriginal);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F5C3D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  final Map<String, String> _etiquetas = {
    'codigo': 'Código (Tag)', 'descripcion': 'Descripción', 'nombre': 'Nombre en Sistema',
    'familia': 'Familia', 'areaProceso': 'Área de Proceso', 'ubicacionTecnica': 'Ubicación Técnica',
    'centro_costo': 'Centro de Costo', 'equipoPadre': 'Equipo Padre', 'marca': 'Marca',
    'modelo': 'Modelo', 'numeroSerie': 'No. Serie', 'variableMedida': 'Variable Medida',
    'senalEntradaSalida': 'Señal E/S', 'rangoLrv': 'Rango LRV', 'rangoUrv': 'Rango URV',
    'unidadIngenieria': 'Unidad', 'supervisor': 'Supervisor / Encargado', 'plan_tareas': 'Plan de Tareas',
    'observacion': 'Observaciones'
  };

  final List<String> _ocultos = [
    'id_levantamiento', 'id_transaccion', 'uid_creador', 'email_creador', 'email_original',
    'nombre_creador', 'fotoPlacaUrl', 'fotoPlacaAdicionalUrl', 'fotoGeneralUrl',
    'urls_subidas_temporalmente', 'sincronizadoEn', 'ultimaModificacion', 'codigo_minuscula',
    'fotoPlacaUrlAntigua', 'fotoPlacaAdicionalUrlAntigua', 'fotoGeneralUrlAntigua'
  ];

  String _formatearValor(dynamic valor) {
    if (valor == null) return '';
    if (valor is Timestamp) {
      final d = valor.toDate();
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    }
    if (valor is String && DateTime.tryParse(valor) != null) {
      final d = DateTime.parse(valor);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    }
    return valor.toString();
  }

  // WIDGET UI/UX: Breadcrumbs para textos extremadamente largos (Rutas de ISA)
  Widget _buildPremiumPath(String path) {
    if (path.isEmpty) return const Text('Vacío', style: TextStyle(color: Color(0xFF5F6368)));
    final parts = path.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: parts.map((part) {
        final isLast = part == parts.last;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isLast ? const Color(0xFF1F5C3D).withValues(alpha: 0.1) : const Color(0xFFF5F6F7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isLast ? const Color(0xFF1F5C3D).withValues(alpha: 0.3) : const Color(0xFFEBEBEB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                part,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                  color: isLast ? const Color(0xFF1F5C3D) : const Color(0xFF5F6368),
                ),
              ),
              if (!isLast) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFD9D9D9))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVistaEdicion(BuildContext context, Map<String, dynamic> datosEditados, ConfiguracionProvider config, StateSetter setStateDialog) {
    final entradasFiltradas = datosEditados.entries.where((e) {
      return !_ocultos.contains(e.key) && e.key != 'solicitado_por' && e.key != 'fechaVerificacion';
    }).toList();

    return SingleChildScrollView(
      key: const ValueKey('edicion'),
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0), 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 24),
                SizedBox(width: 12),
                Expanded(child: Text('Estás editando la propuesta directamente antes de aprobarla. Asegúrate de verificar los datos con el técnico en sitio si es necesario.', style: TextStyle(color: Color(0xFFE65100), fontSize: 13, height: 1.4))),
              ],
            ),
          ),
          ...entradasFiltradas.map((e) {
            final k = e.key;
            final v = e.value;
            final etiqueta = _etiquetas[k] ?? k.toUpperCase();

            final inputDecoration = InputDecoration(
              labelText: etiqueta, 
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1F5C3D), width: 1.5)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            );

            if (v is Timestamp) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextFormField(
                  initialValue: _formatearValor(v),
                  decoration: inputDecoration.copyWith(fillColor: const Color(0xFFF5F6F7)),
                  readOnly: true,
                ),
              );
            }

            if (k == 'areaProceso') {
              String valorActual = v?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () => _mostrarSelectorArea(context, config, datosEditados, setStateDialog),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: inputDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          valorActual.isNotEmpty ? valorActual.split(' / ').last : 'Toque para seleccionar...',
                          style: TextStyle(color: valorActual.isNotEmpty ? const Color(0xFF1A1C1E) : const Color(0xFF5F6368), fontSize: 15, fontWeight: valorActual.isNotEmpty ? FontWeight.w600 : FontWeight.normal),
                        ),
                        if (valorActual.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildPremiumPath(valorActual),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (['familia', 'marca', 'unidadIngenieria'].contains(k)) {
              List<String> opciones = [];
              if (k == 'familia') opciones = List.from(config.familias);
              if (k == 'marca') opciones = List.from(config.marcas);
              if (k == 'unidadIngenieria') opciones = List.from(config.unidades);

              String valorActual = v?.toString() ?? '';
              if (valorActual.isNotEmpty && !opciones.contains(valorActual)) {
                opciones.add(valorActual);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: valorActual.isNotEmpty ? valorActual : null,
                  menuMaxHeight: 300, 
                  decoration: inputDecoration,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  items: opciones.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) {
                    if (val != null) setStateDialog(() => datosEditados[k] = val);
                  },
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextFormField(
                initialValue: v?.toString() ?? '',
                decoration: inputDecoration,
                onChanged: (val) => datosEditados[k] = val,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVistaCreacion(Map<String, dynamic> datosPropuestos) {
    final entradasFiltradas = datosPropuestos.entries.where((e) {
      return !_ocultos.contains(e.key) && e.value != null && e.value.toString().trim().isNotEmpty;
    }).toList();

    return SingleChildScrollView(
      key: const ValueKey('creacion'),
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...entradasFiltradas.map((e) {
            final etiqueta = _etiquetas[e.key] ?? e.key.toUpperCase();
            final valorFormateado = _formatearValor(e.value);
            final esRutaLarga = e.key == 'areaProceso' || e.key == 'ubicacionTecnica';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEBEBEB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5F6368), fontSize: 11, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  esRutaLarga ? _buildPremiumPath(valorFormateado) : Text(valorFormateado, style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 15)),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          if (datosPropuestos['fotoPlacaUrl'] != null || datosPropuestos['fotoPlacaAdicionalUrl'] != null || datosPropuestos['fotoGeneralUrl'] != null)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('EVIDENCIA FOTOGRÁFICA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF5F6368), letterSpacing: 1.0)),
            ),
          if (datosPropuestos['fotoPlacaUrl'] != null) _VisorImagenDialogo(titulo: 'FOTO DE PLACA TÉCNICA', fileId: datosPropuestos['fotoPlacaUrl']),
          if (datosPropuestos['fotoPlacaAdicionalUrl'] != null) _VisorImagenDialogo(titulo: 'FOTO DE PLACA ADICIONAL', fileId: datosPropuestos['fotoPlacaAdicionalUrl']),
          if (datosPropuestos['fotoGeneralUrl'] != null) _VisorImagenDialogo(titulo: 'FOTO GENERAL', fileId: datosPropuestos['fotoGeneralUrl']),
        ],
      ),
    );
  }

  Widget _buildVistaModificacion(String? idOriginal, Map<String, dynamic> datosPropuestos, Future<DocumentSnapshot>? futureOriginalDoc) {
    if (futureOriginalDoc == null) {
      return const Center(child: Text('ID original no válido.'));
    }

    return FutureBuilder<DocumentSnapshot>(
      key: const ValueKey('modificacion'),
      future: futureOriginalDoc,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D)));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('El equipo original ya no existe en la base de datos.', style: TextStyle(color: Color(0xFF5F6368))));
        }

        final datosOriginales = snapshot.data!.data() as Map<String, dynamic>;
        
        final clavesModificadas = datosPropuestos.keys.where((k) {
          if (_ocultos.contains(k)) return false;
          final valorPropuesto = _formatearValor(datosPropuestos[k]);
          final valorOriginal = _formatearValor(datosOriginales[k]);
          return valorPropuesto != valorOriginal && (valorPropuesto.isNotEmpty || valorOriginal.isNotEmpty);
        }).toList();

        final bool cambioPlaca = datosPropuestos['fotoPlacaUrl'] != null && datosPropuestos['fotoPlacaUrl'] != datosOriginales['fotoPlacaUrl'];
        final bool cambioPlacaAdic = datosPropuestos['fotoPlacaAdicionalUrl'] != null && datosPropuestos['fotoPlacaAdicionalUrl'] != datosOriginales['fotoPlacaAdicionalUrl'];
        final bool cambioGeneral = datosPropuestos['fotoGeneralUrl'] != null && datosPropuestos['fotoGeneralUrl'] != datosOriginales['fotoGeneralUrl'];

        if (clavesModificadas.isEmpty && !cambioPlaca && !cambioPlacaAdic && !cambioGeneral) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: Color(0xFF1F5C3D), size: 48),
                SizedBox(height: 16),
                Text('No hay cambios detectados con respecto al original.', style: TextStyle(color: Color(0xFF5F6368), fontSize: 15)),
              ],
            )
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.compare_arrows, color: Color(0xFF5F6368), size: 20),
                    SizedBox(width: 12),
                    Text('Comparativa de modificaciones propuestas', style: TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              ...clavesModificadas.map((k) {
                final etiqueta = _etiquetas[k] ?? k.toUpperCase();
                final valorOriginal = _formatearValor(datosOriginales[k]);
                final valorNuevo = _formatearValor(datosPropuestos[k]);
                
                // UX: Detectar strings gigantescos para cambiar el diseño de la tarjeta (Responsive Diff)
                final esMuyLargo = valorOriginal.length > 35 || valorNuevo.length > 35;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEBEBEB)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF5F6368), letterSpacing: 0.5)),
                      ),
                      const Divider(height: 1, color: Color(0xFFEBEBEB)),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: esMuyLargo 
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Valor Original', style: TextStyle(fontSize: 10, color: Color(0xFFDC362E), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  k.toLowerCase().contains('area') ? _buildPremiumPath(valorOriginal) : Text(valorOriginal.isEmpty ? 'Vacío' : valorOriginal, style: const TextStyle(color: Color(0xFFDC362E), decoration: TextDecoration.lineThrough, fontSize: 14)),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Icon(Icons.arrow_downward, size: 16, color: Color(0xFFD9D9D9))),
                                  const Text('Nuevo Valor', style: TextStyle(fontSize: 10, color: Color(0xFF1F5C3D), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  k.toLowerCase().contains('area') ? _buildPremiumPath(valorNuevo) : Text(valorNuevo.isEmpty ? 'Vacío' : valorNuevo, style: const TextStyle(color: Color(0xFF1F5C3D), fontWeight: FontWeight.w600, fontSize: 15)),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(color: const Color(0xFFDC362E).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFDC362E).withValues(alpha: 0.1))),
                                      child: Text(valorOriginal.isEmpty ? 'Vacío' : valorOriginal, style: const TextStyle(color: Color(0xFFDC362E), decoration: TextDecoration.lineThrough, fontSize: 14)),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Icon(Icons.arrow_forward_rounded, size: 20, color: Color(0xFFD9D9D9)),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(color: const Color(0xFF1F5C3D).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1F5C3D).withValues(alpha: 0.2))),
                                      child: Text(valorNuevo.isEmpty ? 'Vacío' : valorNuevo, style: const TextStyle(color: Color(0xFF1F5C3D), fontWeight: FontWeight.w600, fontSize: 14)),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                );
              }),
              if (cambioPlaca || cambioPlacaAdic || cambioGeneral)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                  child: Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFEBEBEB))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text('EVIDENCIA GRÁFICA ACTUALIZADA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF1F5C3D).withValues(alpha: 0.8), letterSpacing: 1.0)),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFEBEBEB))),
                    ],
                  ),
                ),
              if (cambioPlaca) _VisorImagenDialogo(titulo: 'NUEVA FOTO DE PLACA TÉCNICA', fileId: datosPropuestos['fotoPlacaUrl']!),
              if (cambioPlacaAdic) _VisorImagenDialogo(titulo: 'NUEVA FOTO DE PLACA ADICIONAL', fileId: datosPropuestos['fotoPlacaAdicionalUrl']!),
              if (cambioGeneral) _VisorImagenDialogo(titulo: 'NUEVA FOTO GENERAL', fileId: datosPropuestos['fotoGeneralUrl']!),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: const Text('Equipos por Aprobar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: const Color(0xFF1F5C3D),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // UX: Centrado perfecto en monitores anchos
          child: StreamBuilder<QuerySnapshot>(
            stream: (widget.rol == 'admin' || widget.rol == 'supervisor')
                ? FirebaseFirestore.instance.collection('ediciones_pendientes')
                    .where('estado', isEqualTo: 'pendiente')
                    .orderBy('fecha_solicitud', descending: true)
                    .snapshots()
                : FirebaseFirestore.instance.collection('ediciones_pendientes')
                    .where('solicitado_por', isEqualTo: FirebaseAuth.instance.currentUser?.email)
                    .where('estado', isEqualTo: 'pendiente')
                    .orderBy('fecha_solicitud', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt_rounded, size: 72, color: Color(0xFFD9D9D9)),
                      SizedBox(height: 16),
                      Text('No hay equipos pendientes de aprobación', style: TextStyle(fontSize: 16, color: Color(0xFF5F6368), fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final datosPropuestos = data['datos_propuestos'] as Map<String, dynamic>? ?? {};
                  
                  final esModificacion = data['tipo_operacion'] == 'modificacion';
                  final tag = datosPropuestos['codigo'] ?? 'Sin TAG';
                  final nombre = datosPropuestos['nombre'] ?? datosPropuestos['descripcion'] ?? 'Sin nombre';

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: const Color(0xFFEBEBEB), width: 1),
                      ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _mostrarDialogoRevision(context, doc.id, data),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: esModificacion ? const Color(0xFFF57F17).withValues(alpha: 0.1) : const Color(0xFF1F5C3D).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                esModificacion ? Icons.edit_note_rounded : Icons.add_box_rounded,
                                color: esModificacion ? const Color(0xFFF57F17) : const Color(0xFF1F5C3D),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1C1E)), overflow: TextOverflow.ellipsis),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFEBEBEB))
                                        ),
                                        child: Text(
                                          esModificacion ? 'MODIFICACIÓN' : 'CREACIÓN',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: esModificacion ? const Color(0xFFF57F17) : const Color(0xFF1F5C3D), letterSpacing: 0.5),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(nombre, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368))),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 14, color: Color(0xFF5F6368)),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(data['solicitado_por'] ?? 'Desconocido', style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)), overflow: TextOverflow.ellipsis)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Icon(Icons.chevron_right_rounded, color: Color(0xFFD9D9D9)),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}