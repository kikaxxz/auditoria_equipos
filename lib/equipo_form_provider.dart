import 'dart:convert';
import 'dart:async';
import 'dart:typed_data'; // Añadido para Uint8List
import 'package:flutter/foundation.dart'; // Añadido para compute
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sincronizacion_service.dart';
import 'image_cache_manager.dart';

String codificarBase64EnIsolate(Uint8List bytes) {
  return base64Encode(bytes);
}

class EquipoFormProvider extends ChangeNotifier {
  String codigo = '';
  String descripcion = '';
  String nombre = '';
  String areaProceso = '';
  String ubicacionTecnica = '';
  String centroCosto = '';
  String equipoPadre = '';

  String familia = '';
  String familiaPersonalizada = '';

  String marca = '';
  String marcaPersonalizada = '';

  String modelo = '';
  String numeroSerie = '';
  String variableMedida = '';
  String rangoLrv = '';
  String rangoUrv = '';
  
  String unidadIngenieria = '';
  String unidadPersonalizada = '';
  
  String senalEntradaSalida = '';
  
  String supervisor = '';
  String planTareas = '';

  DateTime fechaVerificacion = DateTime.now();
  String observacion = '';

  XFile? fotoPlaca;
  XFile? fotoPlacaAdicional;
  XFile? fotoGeneral;

  String? fotoPlacaBase64;
  String? fotoPlacaAdicionalBase64;
  String? fotoGeneralBase64;

  String? idLevantamientoTemporal;
  String? idTransaccionExistente;
  String? fotoPlacaUrlExistente;
  String? fotoPlacaAdicionalUrlExistente;
  String? fotoGeneralUrlExistente;
  String? uidCreadorExistente;
  String? emailCreadorExistente;

  String _nombreAuditor = '';
  bool guardandoEnRed = false;

  Timer? _debounceBorrador; // Variable añadida para controlar el lag de escritura

  final ImagePicker _picker = ImagePicker();
  final Box _borrador = Hive.box('borrador');
  final Box _pendientes = Hive.box('equipos_pendientes');

  EquipoFormProvider() {
    _cargarBorrador();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.email).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('nombre_completo')) {
            _nombreAuditor = data['nombre_completo'];
          }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  void updateField(String field, dynamic value) {
    switch (field) {
      case 'codigo': codigo = value; break;
      case 'descripcion': descripcion = value; break;
      case 'nombre': nombre = value; break;
      case 'familia': familia = value; break;
      case 'familiaPersonalizada': familiaPersonalizada = value; break;
      case 'areaProceso': areaProceso = value; break;
      case 'ubicacionTecnica': ubicacionTecnica = value; break;
      case 'centro_costo': centroCosto = value; break;
      case 'equipoPadre': equipoPadre = value; break;
      case 'marca': marca = value; break;
      case 'marcaPersonalizada': marcaPersonalizada = value; break;
      case 'modelo': modelo = value; break;
      case 'numeroSerie': numeroSerie = value; break;
      case 'variableMedida': variableMedida = value; break;
      case 'rangoLrv': rangoLrv = value; break;
      case 'rangoUrv': rangoUrv = value; break;
      case 'unidadIngenieria': unidadIngenieria = value; break;
      case 'unidadPersonalizada': unidadPersonalizada = value; break;
      case 'senalEntradaSalida': senalEntradaSalida = value; break;
      case 'supervisor': supervisor = value; break;
      case 'plan_tareas': planTareas = value; break;
      case 'observacion': observacion = value; break;
    }
    
    notifyListeners();

    if (_debounceBorrador?.isActive ?? false) _debounceBorrador!.cancel();
    _debounceBorrador = Timer(const Duration(milliseconds: 500), () {
      _guardarBorrador();
    });
  }

  Future<void> capturarFoto(String tipo) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (photo != null) {
        final Uint8List bytes = await photo.readAsBytes();
        
        final String base64String = await compute(codificarBase64EnIsolate, bytes);

        if (tipo == 'placa') {
          fotoPlaca = photo;
          fotoPlacaBase64 = base64String;
        } else if (tipo == 'placa_adicional') {
          fotoPlacaAdicional = photo;
          fotoPlacaAdicionalBase64 = base64String;
        } else {
          fotoGeneral = photo;
          fotoGeneralBase64 = base64String;
        }
        
        _guardarBorrador();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al capturar foto: $e');
    }
  }

  Future<bool> guardarLevantamientoFinal({required String rolUsuario}) async {
    guardandoEnRed = true;
    notifyListeners();

    final bool esEdicion = idLevantamientoTemporal != null;
    final String idFinal = idLevantamientoTemporal ?? const Uuid().v4();
    final String emailActual = FirebaseAuth.instance.currentUser?.email ?? 'Desconocido';
    final String creadorFinal = _nombreAuditor.isNotEmpty ? _nombreAuditor : emailActual;
    final String idTransaccion = idTransaccionExistente ?? const Uuid().v4();

    final datos = {
      'id_transaccion': idTransaccion,
      'id_levantamiento': idFinal,
      'es_edicion': esEdicion,
      'codigo': codigo,
      'codigo_minuscula': codigo.toLowerCase(),
      'descripcion': descripcion,
      'nombre': nombre,
      'familia': familia == 'Otro...' ? familiaPersonalizada : familia,
      'areaProceso': areaProceso,
      'ubicacionTecnica': ubicacionTecnica,
      'centro_costo': centroCosto,
      'equipoPadre': equipoPadre,
      'marca': marca == 'Otro...' ? marcaPersonalizada : marca,
      'modelo': modelo,
      'numeroSerie': numeroSerie,
      'variableMedida': variableMedida,
      'rangoLrv': rangoLrv,
      'rangoUrv': rangoUrv,
      'unidadIngenieria': unidadIngenieria == 'Otro...' ? unidadPersonalizada : unidadIngenieria,
      'senalEntradaSalida': senalEntradaSalida,
      'supervisor': supervisor,
      'plan_tareas': planTareas,
      'fechaVerificacion': fechaVerificacion.toIso8601String(),
      'observacion': observacion,
      'fotoPlacaUrl': fotoPlacaUrlExistente,
      'fotoPlacaAdicionalUrl': fotoPlacaAdicionalUrlExistente,
      'fotoGeneralUrl': fotoGeneralUrlExistente,
      'fotoPlacaBase64': fotoPlaca != null ? fotoPlacaBase64 : null,
      'fotoPlacaAdicionalBase64': fotoPlacaAdicional != null ? fotoPlacaAdicionalBase64 : null,
      'fotoGeneralBase64': fotoGeneral != null ? fotoGeneralBase64 : null,
      'uid_creador': uidCreadorExistente,
      'email_creador': esEdicion ? emailCreadorExistente : creadorFinal,
      'email_original': emailActual,
      'rol_usuario': rolUsuario,
      'tipo_operacion': esEdicion ? 'modificacion' : 'creacion',
    };

    try {
      final exito = await SincronizacionService().sincronizarRegistroInmediato(datos);
      if (!exito) {
        _pendientes.add(datos);
      }
      guardandoEnRed = false;
      resetForm();
      return exito;
    } catch (e) {
      _pendientes.add(datos);
      guardandoEnRed = false;
      resetForm();
      return false;
    }
  }

  void cargarLevantamientoExistente(String docId, Map<String, dynamic> datos) async {
    idLevantamientoTemporal = docId;
    idTransaccionExistente = datos['id_transaccion'];
    codigo = datos['codigo'] ?? '';
    descripcion = datos['descripcion'] ?? '';
    nombre = datos['nombre'] ?? '';
    areaProceso = datos['areaProceso'] ?? '';
    ubicacionTecnica = datos['ubicacionTecnica'] ?? '';
    centroCosto = datos['centro_costo'] ?? '';
    equipoPadre = datos['equipoPadre'] ?? '';
    modelo = datos['modelo'] ?? '';
    numeroSerie = datos['numeroSerie'] ?? '';
    variableMedida = datos['variableMedida'] ?? '';
    rangoLrv = datos['rangoLrv']?.toString() ?? '';
    rangoUrv = datos['rangoUrv']?.toString() ?? '';
    senalEntradaSalida = datos['senalEntradaSalida'] ?? '';
    supervisor = datos['supervisor'] ?? '';
    planTareas = datos['plan_tareas'] ?? '';
    
    final boxConfig = Hive.box('configuracion_cache');
    final listaFamilias = List<String>.from(boxConfig.get('familias', defaultValue: []));
    final listaMarcas = List<String>.from(boxConfig.get('marcas', defaultValue: []));
    final listaUnidades = List<String>.from(boxConfig.get('unidades', defaultValue: []));

    String familiaCargada = datos['familia'] ?? '';
    if (familiaCargada.isNotEmpty && !listaFamilias.contains(familiaCargada)) {
      familia = 'Otro...';
      familiaPersonalizada = familiaCargada;
    } else {
      familia = familiaCargada;
      familiaPersonalizada = '';
    }

    String marcaCargada = datos['marca'] ?? '';
    if (marcaCargada.isNotEmpty && !listaMarcas.contains(marcaCargada)) {
      marca = 'Otro...';
      marcaPersonalizada = marcaCargada;
    } else {
      marca = marcaCargada;
      marcaPersonalizada = '';
    }

    String unidadCargada = datos['unidadIngenieria'] ?? '';
    if (unidadCargada.isNotEmpty && !listaUnidades.contains(unidadCargada)) {
      unidadIngenieria = 'Otro...';
      unidadPersonalizada = unidadCargada;
    } else {
      unidadIngenieria = unidadCargada;
      unidadPersonalizada = '';
    }
    
    uidCreadorExistente = datos['uid_creador'];
    emailCreadorExistente = datos['email_creador'];

    final fechaStr = datos['fechaVerificacion'];
    if (fechaStr != null) {
      if (fechaStr is Timestamp) {
        fechaVerificacion = fechaStr.toDate();
      } else {
        fechaVerificacion = DateTime.parse(fechaStr.toString());
      }
    }

    observacion = datos['observacion'] ?? '';
    fotoPlacaUrlExistente = datos['fotoPlacaUrl'];
    fotoPlacaAdicionalUrlExistente = datos['fotoPlacaAdicionalUrl'];
    fotoGeneralUrlExistente = datos['fotoGeneralUrl'];
    
    fotoPlacaBase64 = null;
    fotoPlacaAdicionalBase64 = null;
    fotoGeneralBase64 = null;
    fotoPlaca = null;
    fotoPlacaAdicional = null;
    fotoGeneral = null;

    // Procesamos las imágenes de caché en hilos secundarios
    if (fotoPlacaUrlExistente != null) {
      final bytesPlaca = await ImageCacheManager.obtenerImagen(fotoPlacaUrlExistente!);
      if (bytesPlaca != null) {
        fotoPlacaBase64 = await compute(codificarBase64EnIsolate, bytesPlaca);
      }
    }

    if (fotoPlacaAdicionalUrlExistente != null) {
      final bytesPlacaAdic = await ImageCacheManager.obtenerImagen(fotoPlacaAdicionalUrlExistente!);
      if (bytesPlacaAdic != null) {
        fotoPlacaAdicionalBase64 = await compute(codificarBase64EnIsolate, bytesPlacaAdic);
      }
    }

    if (fotoGeneralUrlExistente != null) {
      final bytesGeneral = await ImageCacheManager.obtenerImagen(fotoGeneralUrlExistente!);
      if (bytesGeneral != null) {
        fotoGeneralBase64 = await compute(codificarBase64EnIsolate, bytesGeneral);
      }
    }

    notifyListeners();
  }

  void resetForm() {
    codigo = '';
    descripcion = '';
    nombre = '';
    areaProceso = '';
    ubicacionTecnica = '';
    centroCosto = '';
    equipoPadre = '';
    
    familia = '';
    familiaPersonalizada = '';
    
    marca = '';
    marcaPersonalizada = '';
    
    modelo = '';
    numeroSerie = '';
    variableMedida = '';
    rangoLrv = '';
    rangoUrv = '';
    
    unidadIngenieria = '';
    unidadPersonalizada = '';
    
    senalEntradaSalida = '';
    supervisor = '';
    planTareas = '';
    fechaVerificacion = DateTime.now();
    observacion = '';
    
    fotoPlaca = null;
    fotoPlacaAdicional = null;
    fotoGeneral = null;
    fotoPlacaBase64 = null;
    fotoPlacaAdicionalBase64 = null;
    fotoGeneralBase64 = null;
    
    idLevantamientoTemporal = null;
    idTransaccionExistente = null;
    fotoPlacaUrlExistente = null;
    fotoPlacaAdicionalUrlExistente = null;
    fotoGeneralUrlExistente = null;
    uidCreadorExistente = null;
    emailCreadorExistente = null;

    _borrador.clear();
    notifyListeners();
  }

  void _guardarBorrador() {
    _borrador.putAll({
      'idLevantamientoTemporal': idLevantamientoTemporal,
      'idTransaccionExistente': idTransaccionExistente,
      'codigo': codigo,
      'descripcion': descripcion,
      'nombre': nombre,
      'familia': familia,
      'familiaPersonalizada': familiaPersonalizada,
      'areaProceso': areaProceso,
      'ubicacionTecnica': ubicacionTecnica,
      'centroCosto': centroCosto,
      'equipoPadre': equipoPadre,
      'marca': marca,
      'marcaPersonalizada': marcaPersonalizada,
      'modelo': modelo,
      'numeroSerie': numeroSerie,
      'variableMedida': variableMedida,
      'rangoLrv': rangoLrv,
      'rangoUrv': rangoUrv,
      'unidadIngenieria': unidadIngenieria,
      'unidadPersonalizada': unidadPersonalizada,
      'senalEntradaSalida': senalEntradaSalida,
      'supervisor': supervisor,
      'planTareas': planTareas,
      'fechaVerificacion': fechaVerificacion.toIso8601String(),
      'observacion': observacion,
      'fotoPlacaUrlExistente': fotoPlacaUrlExistente,
      'fotoPlacaAdicionalUrlExistente': fotoPlacaAdicionalUrlExistente,
      'fotoGeneralUrlExistente': fotoGeneralUrlExistente,
      'fotoPlacaBase64': fotoPlacaBase64,
      'fotoPlacaAdicionalBase64': fotoPlacaAdicionalBase64,
      'fotoGeneralBase64': fotoGeneralBase64,
      'uidCreadorExistente': uidCreadorExistente,
      'emailCreadorExistente': emailCreadorExistente,
    });
  }

  void _cargarBorrador() {
    if (_borrador.isNotEmpty) {
      idLevantamientoTemporal = _borrador.get('idLevantamientoTemporal');
      idTransaccionExistente = _borrador.get('idTransaccionExistente');
      codigo = _borrador.get('codigo', defaultValue: '');
      descripcion = _borrador.get('descripcion', defaultValue: '');
      nombre = _borrador.get('nombre', defaultValue: '');
      familia = _borrador.get('familia', defaultValue: '');
      familiaPersonalizada = _borrador.get('familiaPersonalizada', defaultValue: '');
      areaProceso = _borrador.get('areaProceso', defaultValue: '');
      ubicacionTecnica = _borrador.get('ubicacionTecnica', defaultValue: '');
      centroCosto = _borrador.get('centroCosto', defaultValue: '');
      equipoPadre = _borrador.get('equipoPadre', defaultValue: '');
      marca = _borrador.get('marca', defaultValue: '');
      marcaPersonalizada = _borrador.get('marcaPersonalizada', defaultValue: '');
      modelo = _borrador.get('modelo', defaultValue: '');
      numeroSerie = _borrador.get('numeroSerie', defaultValue: '');
      variableMedida = _borrador.get('variableMedida', defaultValue: '');
      rangoLrv = _borrador.get('rangoLrv', defaultValue: '');
      rangoUrv = _borrador.get('rangoUrv', defaultValue: '');
      unidadIngenieria = _borrador.get('unidadIngenieria', defaultValue: '');
      unidadPersonalizada = _borrador.get('unidadPersonalizada', defaultValue: '');
      senalEntradaSalida = _borrador.get('senalEntradaSalida', defaultValue: '');
      supervisor = _borrador.get('supervisor', defaultValue: '');
      planTareas = _borrador.get('planTareas', defaultValue: '');
      uidCreadorExistente = _borrador.get('uidCreadorExistente');
      emailCreadorExistente = _borrador.get('emailCreadorExistente');

      final fechaStr = _borrador.get('fechaVerificacion');
      if (fechaStr != null) {
        fechaVerificacion = DateTime.parse(fechaStr);
      }

      observacion = _borrador.get('observacion', defaultValue: '');
      fotoPlacaUrlExistente = _borrador.get('fotoPlacaUrlExistente');
      fotoPlacaAdicionalUrlExistente = _borrador.get('fotoPlacaAdicionalUrlExistente');
      fotoGeneralUrlExistente = _borrador.get('fotoGeneralUrlExistente');
      fotoPlacaBase64 = _borrador.get('fotoPlacaBase64');
      fotoPlacaAdicionalBase64 = _borrador.get('fotoPlacaAdicionalBase64');
      fotoGeneralBase64 = _borrador.get('fotoGeneralBase64');
    }
  }
}