import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'detalle_equipo_page.dart';
import 'formulario_equipo.dart';
import 'equipo_form_provider.dart';
import 'sincronizacion_service.dart';
import 'dart:convert';

class MisSolicitudesPage extends StatefulWidget {
  final String rol;

  const MisSolicitudesPage({super.key, required this.rol});

  @override
  State<MisSolicitudesPage> createState() => _MisSolicitudesPageState();
}

class _MisSolicitudesPageState extends State<MisSolicitudesPage> {
  final String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
  DateTimeRange? _filtroFecha;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _verificarConectividad();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (mounted) {
        setState(() {
          _isOffline = results.contains(ConnectivityResult.none);
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _searchController.dispose();
    super.dispose();
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
    'fotoPlacaUrlAntigua', 'fotoPlacaAdicionalUrlAntigua', 'fotoGeneralUrlAntigua', 'es_edicion',
    'camposDinamicos'
  ];

  String _formatearValor(dynamic valor) {
    if (valor == null) return '';
    if (valor is Timestamp) {
      final d = valor.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    if (valor is String && DateTime.tryParse(valor) != null) {
      final d = DateTime.parse(valor);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return valor.toString();
  }

  Future<void> _verificarConectividad() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = results.contains(ConnectivityResult.none);
      });
    }
  }

  Future<void> _seleccionarRangoFechas(BuildContext context) async {
    final rangoInicial = _filtroFecha ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final rangoSeleccionado = await showDateRangePicker(
      context: context,
      initialDateRange: rangoInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1F5C3D),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A1C1E),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (rangoSeleccionado != null) {
      setState(() {
        _filtroFecha = rangoSeleccionado;
      });
    }
  }

  void _limpiarFiltro() {
    setState(() {
      _filtroFecha = null;
    });
  }

  List<DocumentSnapshot> _filtrarDocs(List<DocumentSnapshot> docs, String campoFecha) {
    if (_filtroFecha == null) return docs;
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data[campoFecha] as Timestamp?;
      if (timestamp == null) return false;
      final date = timestamp.toDate();
      final start = _filtroFecha!.start.subtract(const Duration(seconds: 1));
      final end = _filtroFecha!.end.add(const Duration(days: 1, seconds: -1));
      return date.isAfter(start) && date.isBefore(end);
    }).toList();
  }

  Future<void> _eliminarSolicitudBase(dynamic docId, List<dynamic> urlsTemporales, String mensaje, {bool isOffline = false}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D))),
    );

    try {
      if (!isOffline) {
        for (var url in urlsTemporales) {
          await SincronizacionService().eliminarImagenDrive(url.toString());
        }
        await FirebaseFirestore.instance.collection('ediciones_pendientes').doc(docId.toString()).delete();
      } else {
        await Hive.box('equipos_pendientes').delete(docId);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: const Color(0xFF1F5C3D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al procesar la solicitud.'),
            backgroundColor: const Color(0xFFDC362E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _confirmarDescarte(String docId, List<dynamic> urlsTemporales) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC362E), size: 28),
            SizedBox(width: 12),
            Text('Descartar Solicitud', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este registro rechazado? Esta acción no se puede deshacer.',
          style: TextStyle(color: Color(0xFF5F6368), height: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.w600)),
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
              Navigator.pop(dialogContext);
              _eliminarSolicitudBase(docId, urlsTemporales, 'Solicitud descartada permanentemente.');
            },
            child: const Text('DESCARTAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  void _confirmarCancelacion(dynamic docId, List<dynamic> urlsTemporales, bool isOffline) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFDC362E), size: 28),
            SizedBox(width: 12),
            Text('Cancelar Envío', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cancelar esta solicitud? No se enviará a revisión.',
          style: TextStyle(color: Color(0xFF5F6368), height: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('VOLVER', style: TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.w600)),
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
              Navigator.pop(dialogContext);
              _eliminarSolicitudBase(docId, urlsTemporales, 'Solicitud cancelada exitosamente.', isOffline: isOffline);
            },
            child: const Text('CANCELAR ENVÍO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  void _corregirSolicitud(String docId, Map<String, dynamic> data) async {
    final formProvider = Provider.of<EquipoFormProvider>(context, listen: false);
    
    final datosFormulario = Map<String, dynamic>.from(data['datos_propuestos'] ?? {});
    datosFormulario['id_transaccion'] = docId;
    datosFormulario['tipo_operacion'] = data['tipo_operacion'];
    datosFormulario['es_edicion'] = data['tipo_operacion'] == 'modificacion';
    
    formProvider.cargarLevantamientoExistente(
      data['id_equipo_original'] ?? '',
      datosFormulario,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormularioEquipoPage(rolUsuario: widget.rol)),
    );
  }

  void _mostrarDetalles(Map<String, dynamic> datosPropuestos) {
    final entradasFiltradas = datosPropuestos.entries.where((e) {
      return !_ocultos.contains(e.key) && 
             e.value != null && 
             e.value.toString().trim().isNotEmpty && 
             !e.key.toLowerCase().contains('base64');
    }).toList();

    final Map<String, dynamic> camposDinamicos = datosPropuestos['camposDinamicos'] != null 
        ? Map<String, dynamic>.from(datosPropuestos['camposDinamicos']) 
        : {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE0E2E5))),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E2E5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Detalles de la Solicitud',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E), letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ...entradasFiltradas.map((e) {
                    final etiqueta = _etiquetas[e.key] ?? e.key.toUpperCase();
                    final valorFormateado = _formatearValor(e.value);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E2E5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            etiqueta.toUpperCase(), 
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF5F6368), fontSize: 11, letterSpacing: 0.5)
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            valorFormateado, 
                            style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 15, fontWeight: FontWeight.w500)
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  if (camposDinamicos.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('CAMPOS PERSONALIZADOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF5F6368), letterSpacing: 1.0)),
                    ),
                    ...camposDinamicos.entries.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E2E5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.key.toUpperCase(), 
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF5F6368), fontSize: 11, letterSpacing: 0.5)
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              e.value.toString(), 
                              style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 15, fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),
                  if (datosPropuestos['fotoPlacaUrl'] != null) 
                    _VisorImagenDialogo(titulo: 'FOTO DE PLACA TÉCNICA', fileId: datosPropuestos['fotoPlacaUrl']),
                  if (datosPropuestos['fotoPlacaAdicionalUrl'] != null) 
                    _VisorImagenDialogo(titulo: 'FOTO DE PLACA ADICIONAL', fileId: datosPropuestos['fotoPlacaAdicionalUrl']),
                  if (datosPropuestos['fotoGeneralUrl'] != null) 
                    _VisorImagenDialogo(titulo: 'FOTO GENERAL', fileId: datosPropuestos['fotoGeneralUrl']),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1C1E).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5C3D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CERRAR DETALLES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(dynamic timestamp) {
    if (timestamp == null) return 'Fecha no disponible';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }
    final dia = date.day.toString().padLeft(2, '0');
    final mes = date.month.toString().padLeft(2, '0');
    final anio = date.year;
    return '$dia/$mes/$anio';
  }

  String _formatearRangoFechas() {
    if (_filtroFecha == null) return '';
    final start = _filtroFecha!.start;
    final end = _filtroFecha!.end;
    return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';
  }

  Widget _buildListaVacia(IconData icono, String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1F5C3D).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 64, color: const Color(0xFF1F5C3D).withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            mensaje, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF5F6368)), 
            textAlign: TextAlign.center
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por TAG o Nombre...',
          hintStyle: const TextStyle(color: Color(0xFF5F6368)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1F5C3D)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF5F6368)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE0E2E5), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF1F5C3D), width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildTarjetaPendiente(Map<String, dynamic> data, dynamic docId, {bool isOffline = false}) {
    final datosPropuestos = (data['datos_propuestos'] is Map) 
        ? Map<String, dynamic>.from(data['datos_propuestos']) 
        : Map<String, dynamic>.from(data);
    
    final esModificacion = data['tipo_operacion'] == 'modificacion' || datosPropuestos['es_edicion'] == true;
    final urlsTemporales = datosPropuestos['urls_subidas_temporalmente'] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1C1E).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isOffline ? const Color(0xFFF57F17).withValues(alpha: 0.5) : const Color(0xFFE0E2E5), 
          width: isOffline ? 1.5 : 1
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F5C3D).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        esModificacion ? 'MODIFICACIÓN' : 'NUEVO REGISTRO',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F5C3D), fontSize: 11, letterSpacing: 0.5),
                      ),
                    ),
                    if (isOffline) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF57F17).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFFF57F17)),
                      ),
                    ],
                  ],
                ),
                Text(
                  _formatearFecha(data['fecha_solicitud'] ?? DateTime.now().toIso8601String()),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF5F6368)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              datosPropuestos['codigo'] ?? 'Sin TAG',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1C1E), letterSpacing: -0.2),
            ),
            const SizedBox(height: 6),
            Text(
              datosPropuestos['nombre'] ?? datosPropuestos['descripcion'] ?? 'Sin nombre',
              style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isOffline) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFF57F17)),
                  const SizedBox(width: 6),
                  const Text(
                    'Esperando conexión para envío',
                    style: TextStyle(fontSize: 12, color: Color(0xFFF57F17), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC362E),
                      side: const BorderSide(color: Color(0xFFDC362E)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmarCancelacion(docId, urlsTemporales, isOffline),
                    child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5C3D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _mostrarDetalles(datosPropuestos),
                    child: const Text('VER DETALLES', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaRechazada(String docId, Map<String, dynamic> data) {
    final datosPropuestos = data['datos_propuestos'] as Map<String, dynamic>? ?? {};
    final urlsTemporales = datosPropuestos['urls_subidas_temporalmente'] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC362E).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFDC362E).withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC362E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, color: Color(0xFFDC362E), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'REQUIERE CORRECCIÓN',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC362E), fontSize: 11, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatearFecha(data['fecha_rechazo'] as Timestamp?),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF5F6368)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              datosPropuestos['codigo'] ?? 'Sin TAG',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1C1E), letterSpacing: -0.2),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E2E5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.comment_rounded, size: 14, color: Color(0xFF5F6368)),
                      SizedBox(width: 6),
                      Text('Comentario de revisión:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF5F6368))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['motivo_rechazo'] ?? 'No especificado',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1C1E), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5F6368),
                      side: const BorderSide(color: Color(0xFFE0E2E5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _confirmarDescarte(docId, urlsTemporales),
                    child: const Text('DESCARTAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5C3D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _corregirSolicitud(docId, data),
                    child: const Text('CORREGIR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaAprobada(String docId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E2E5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1C1E).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleEquipoPage(
                documentId: docId,
                datos: data,
                rolUsuario: widget.rol,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F5C3D).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF1F5C3D), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['codigo'] ?? 'Sin TAG', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1C1E))
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['nombre'] ?? data['descripcion'] ?? 'Sin nombre', 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF5F6368), fontSize: 14)
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aprobado: ${_formatearFecha(data['sincronizadoEn'] as Timestamp?)}', 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1F5C3D))
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD9D9D9), size: 28),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserEmail == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6F7),
        appBar: AppBar(title: const Text('Mis Solicitudes'), backgroundColor: const Color(0xFF1F5C3D)),
        body: const Center(child: Text('Error de autenticación')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F7),
        appBar: AppBar(
          title: const Text('Mis Solicitudes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          backgroundColor: const Color(0xFF1F5C3D),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          centerTitle: true,
          actions: [
            if (_filtroFecha != null)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(_formatearRangoFechas(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _limpiarFiltro,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.date_range_rounded),
              tooltip: 'Filtrar por fecha',
              onPressed: () => _seleccionarRangoFechas(context),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(_isOffline ? 72 : 56),
            child: Column(
              children: [
                if (_isOffline)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFF57F17),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Sin conexión - Modo lectura local',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                const TabBar(
                  indicatorColor: Colors.white,
                  indicatorWeight: 4,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  tabs: [
                    Tab(text: 'En Revisión'),
                    Tab(text: 'Correcciones'),
                    Tab(text: 'Aprobadas'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: TabBarView(
              children: [
                ValueListenableBuilder(
                  valueListenable: Hive.box('equipos_pendientes').listenable(),
                  builder: (context, Box box, _) {
                    final localEntries = box.toMap().entries.where((entry) {
                      final data = Map<String, dynamic>.from(entry.value);
                      return data['email_creador'] == currentUserEmail || data['solicitado_por'] == currentUserEmail;
                    }).toList();

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('ediciones_pendientes')
                          .where('solicitado_por', isEqualTo: currentUserEmail)
                          .where('estado', isEqualTo: 'pendiente')
                          .orderBy('fecha_solicitud', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && localEntries.isEmpty) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D)));
                        }

                        List<Map<String, dynamic>> combinedDocs = [];
                        
                        for (var entry in localEntries) {
                          combinedDocs.add({
                            'id': entry.key,
                            'data': Map<String, dynamic>.from(entry.value),
                            'isOffline': true,
                          });
                        }

                        if (snapshot.hasData) {
                          final docsFiltrados = _filtrarDocs(snapshot.data!.docs, 'fecha_solicitud');
                          for (var doc in docsFiltrados) {
                            combinedDocs.add({
                              'id': doc.id,
                              'data': doc.data() as Map<String, dynamic>,
                              'isOffline': false,
                            });
                          }
                        }

                        if (combinedDocs.isEmpty) {
                          return _buildListaVacia(Icons.pending_actions_rounded, 'No tienes solicitudes en revisión en este momento.');
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          itemCount: combinedDocs.length,
                          itemBuilder: (context, index) {
                            final item = combinedDocs[index];
                            return _buildTarjetaPendiente(
                              item['data'], 
                              item['id'],
                              isOffline: item['isOffline']
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('ediciones_pendientes')
                      .where('solicitado_por', isEqualTo: currentUserEmail)
                      .where('estado', isEqualTo: 'rechazado')
                      .orderBy('fecha_rechazo', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildListaVacia(Icons.thumb_up_alt_outlined, 'No tienes solicitudes devueltas para corrección.');
                    }
                    final docsFiltrados = _filtrarDocs(snapshot.data!.docs, 'fecha_rechazo');
                    if (docsFiltrados.isEmpty) {
                      return _buildListaVacia(Icons.event_busy_rounded, 'No hay registros en este rango de fechas.');
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      itemCount: docsFiltrados.length,
                      itemBuilder: (context, index) {
                        return _buildTarjetaRechazada(docsFiltrados[index].id, docsFiltrados[index].data() as Map<String, dynamic>);
                      },
                    );
                  },
                ),
                Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('equipos')
                            .where('email_creador', isEqualTo: currentUserEmail)
                            .orderBy('sincronizadoEn', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D)));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return _buildListaVacia(Icons.inventory_2_outlined, 'Aún no tienes equipos aprobados en la base de datos.');
                          }
                          
                          var docsFiltrados = _filtrarDocs(snapshot.data!.docs, 'sincronizadoEn');
                          
                          if (_searchQuery.isNotEmpty) {
                            docsFiltrados = docsFiltrados.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final tag = (data['codigo'] ?? '').toString().toLowerCase();
                              final nombre = (data['nombre'] ?? data['descripcion'] ?? '').toString().toLowerCase();
                              return tag.contains(_searchQuery) || nombre.contains(_searchQuery);
                            }).toList();
                          }

                          if (docsFiltrados.isEmpty) {
                            return _buildListaVacia(Icons.search_off_rounded, 'No se encontraron equipos con esa búsqueda.');
                          }
                          
                          return ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                            itemCount: docsFiltrados.length,
                            itemBuilder: (context, index) {
                              return _buildTarjetaAprobada(docsFiltrados[index].id, docsFiltrados[index].data() as Map<String, dynamic>);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
          backgroundColor: Colors.black,
          title: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.memory(base64Decode(base64Data)),
          ),
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E2E5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1C1E).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF5F6368), fontSize: 11, letterSpacing: 0.5),
                ),
                const Icon(Icons.zoom_out_map_rounded, size: 16, color: Color(0xFF5F6368)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E2E5)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<String?>(
              future: _futureImagen,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D))),
                  );
                }
                if (snapshot.hasData && snapshot.data != null) {
                  try {
                    return GestureDetector(
                      onTap: () => _mostrarImagenCompleta(context, snapshot.data!, widget.titulo),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: Image.memory(
                            base64Decode(snapshot.data!),
                            fit: BoxFit.contain,
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
        ],
      ),
    );
  }

  Widget _buildErrorImagen() {
    return const SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, color: Color(0xFFD9D9D9), size: 48),
            SizedBox(height: 12),
            Text('Evidencia gráfica no disponible', style: TextStyle(color: Color(0xFF5F6368), fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}