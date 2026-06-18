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
    'fotoPlacaUrlAntigua', 'fotoPlacaAdicionalUrlAntigua', 'fotoGeneralUrlAntigua', 'es_edicion'
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
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D))),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar la solicitud.'), backgroundColor: Color(0xFFDC362E)),
        );
      }
    }
  }

  void _confirmarDescarte(String docId, List<dynamic> urlsTemporales) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Descartar Solicitud'),
        content: const Text('¿Estás seguro de que deseas eliminar este registro rechazado? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR', style: TextStyle(color: Color(0xFF5F6368))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC362E)),
            onPressed: () {
              Navigator.pop(dialogContext);
              _eliminarSolicitudBase(docId, urlsTemporales, 'Solicitud descartada permanentemente.');
            },
            child: const Text('DESCARTAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarCancelacion(dynamic docId, List<dynamic> urlsTemporales, bool isOffline) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar Envío'),
        content: const Text('¿Estás seguro de que deseas cancelar esta solicitud? No se enviará a revisión.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('VOLVER', style: TextStyle(color: Color(0xFF5F6368))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC362E)),
            onPressed: () {
              Navigator.pop(dialogContext);
              _eliminarSolicitudBase(docId, urlsTemporales, 'Solicitud cancelada exitosamente.', isOffline: isOffline);
            },
            child: const Text('CANCELAR ENVÍO', style: TextStyle(color: Colors.white)),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles Enviados', style: TextStyle(color: Color(0xFF1F5C3D), fontWeight: FontWeight.bold)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...entradasFiltradas.map((e) {
                final etiqueta = _etiquetas[e.key] ?? e.key.toUpperCase();
                final valorFormateado = _formatearValor(e.value);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEBEBEB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5F6368), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(valorFormateado, style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 14)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              if (datosPropuestos['fotoPlacaUrl'] != null) 
                _VisorImagenDialogo(titulo: 'FOTO DE PLACA TÉCNICA', fileId: datosPropuestos['fotoPlacaUrl']),
              if (datosPropuestos['fotoPlacaAdicionalUrl'] != null) 
                _VisorImagenDialogo(titulo: 'FOTO DE PLACA ADICIONAL', fileId: datosPropuestos['fotoPlacaAdicionalUrl']),
              if (datosPropuestos['fotoGeneralUrl'] != null) 
                _VisorImagenDialogo(titulo: 'FOTO GENERAL', fileId: datosPropuestos['fotoGeneralUrl']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CERRAR', style: TextStyle(color: Color(0xFF1F5C3D))),
          ),
        ],
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
    return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year} - ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
  }

  Widget _buildListaVacia(IconData icono, String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 64, color: const Color(0xFFD9D9D9)),
          const SizedBox(height: 16),
          Text(mensaje, style: const TextStyle(fontSize: 16, color: Color(0xFF5F6368)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por TAG o Nombre...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF1F5C3D)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF5F6368)),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isOffline ? const Color(0xFFF57F17) : const Color(0xFFD9D9D9), width: isOffline ? 1.5 : 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF57F17).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        esModificacion ? 'MODIFICACIÓN' : 'NUEVO REGISTRO',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF57F17), fontSize: 11),
                      ),
                    ),
                    if (isOffline) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.cloud_off, size: 16, color: Color(0xFFF57F17)),
                    ],
                  ],
                ),
                Text(
                  _formatearFecha(data['fecha_solicitud'] ?? DateTime.now().toIso8601String()),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              datosPropuestos['codigo'] ?? 'Sin TAG',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1C1E)),
            ),
            const SizedBox(height: 4),
            Text(
              datosPropuestos['nombre'] ?? datosPropuestos['descripcion'] ?? 'Sin nombre',
              style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
            ),
            if (isOffline) ...[
              const SizedBox(height: 12),
              const Text(
                'Esperando conexión de red para envío',
                style: TextStyle(fontSize: 12, color: Color(0xFFF57F17), fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC362E),
                      side: const BorderSide(color: Color(0xFFDC362E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _confirmarCancelacion(docId, urlsTemporales, isOffline),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5C3D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _mostrarDetalles(datosPropuestos),
                    child: const Text('Ver Detalles'),
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
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDC362E), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: Color(0xFFDC362E), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'REQUIERE CORRECCIÓN',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC362E), fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  _formatearFecha(data['fecha_rechazo'] as Timestamp?),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              datosPropuestos['codigo'] ?? 'Sin TAG',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1C1E)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDC362E).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Motivo del rechazo:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFFDC362E))),
                  const SizedBox(height: 4),
                  Text(
                    data['motivo_rechazo'] ?? 'No especificado',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A1C1E)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC362E),
                      side: const BorderSide(color: Color(0xFFDC362E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _confirmarDescarte(docId, urlsTemporales),
                    child: const Text('Descartar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F5C3D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _corregirSolicitud(docId, data),
                    child: const Text('Corregir'),
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD9D9D9), width: 0.8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1F5C3D).withValues(alpha: 0.1),
          child: const Icon(Icons.check_circle, color: Color(0xFF1F5C3D)),
        ),
        title: Text(data['codigo'] ?? 'Sin TAG', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(data['nombre'] ?? data['descripcion'] ?? 'Sin nombre', maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Aprobado el: ${_formatearFecha(data['sincronizadoEn'] as Timestamp?)}', style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_red_eye, color: Color(0xFF1F5C3D)),
          onPressed: () {
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserEmail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis Solicitudes'), backgroundColor: const Color(0xFF1F5C3D)),
        body: const Center(child: Text('Error de autenticación')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F7),
        appBar: AppBar(
          title: const Text('Mis Solicitudes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFF1F5C3D),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          actions: [
            if (_filtroFecha != null)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(_formatearRangoFechas(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _limpiarFiltro,
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: () => _seleccionarRangoFechas(context),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(_isOffline ? 68 : 48),
            child: Column(
              children: [
                if (_isOffline)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFDC362E),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text(
                      'Sin conexión - Mostrando datos locales',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                const TabBar(
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
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
        body: TabBarView(
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
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D)));
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
                      return _buildListaVacia(Icons.pending_actions, 'No tienes solicitudes en revisión');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
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
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildListaVacia(Icons.check_circle_outline, 'No tienes solicitudes devueltas');
                }
                final docsFiltrados = _filtrarDocs(snapshot.data!.docs, 'fecha_rechazo');
                if (docsFiltrados.isEmpty) {
                  return _buildListaVacia(Icons.event_busy, 'No hay registros en este rango de fechas');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
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
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D)));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildListaVacia(Icons.inventory_2_outlined, 'No tienes equipos aprobados aún');
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
                        return _buildListaVacia(Icons.search_off, 'No se encontraron equipos con esa búsqueda');
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
          title: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 16)),
          iconTheme: const IconThemeData(color: Colors.white),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5F6368), fontSize: 12),
                ),
                const Icon(Icons.zoom_out_map, size: 14, color: Color(0xFF5F6368)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FutureBuilder<String?>(
              future: _futureImagen,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D))),
                  );
                }
                if (snapshot.hasData && snapshot.data != null) {
                  try {
                    return GestureDetector(
                      onTap: () => _mostrarImagenCompleta(context, snapshot.data!, widget.titulo),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
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
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment:   MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Color(0xFF5F6368), size: 32),
            SizedBox(height: 8),
            Text('Evidencia gráfica no disponible', style: TextStyle(color: Color(0xFF5F6368), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}