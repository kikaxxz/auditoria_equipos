import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sincronizacion_service.dart';
import 'image_cache_manager.dart';

class EquipoFormProvider extends ChangeNotifier {
  String codigo = '';
  String descripcion = '';
  String familia = '';
  String areaProceso = '';
  String ubicacionTecnica = '';
  String equipoPadre = '';

  String modelo = '';
  String numeroSerie = '';
  String variableMedida = '';
  String rangoLrv = '';
  String rangoUrv = '';
  String unidadIngenieria = '';
  String senalEntradaSalida = '';

  String estadoFisicoObservado = 'Bueno';
  String estadoOperativoObservado = 'Operativa';
  DateTime fechaVerificacion = DateTime.now();
  String observacion = '';

  XFile? fotoPlaca;
  XFile? fotoGeneral;

  String? fotoPlacaBase64;
  String? fotoGeneralBase64;

  String? idLevantamientoTemporal;
  String? fotoPlacaUrlExistente;
  String? fotoGeneralUrlExistente;
  String? uidCreadorExistente;
  String? emailCreadorExistente;

  String _nombreAuditor = '';
  bool guardandoEnRed = false;

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
      case 'familia': familia = value; break;
      case 'areaProceso': areaProceso = value; break;
      case 'ubicacionTecnica': ubicacionTecnica = value; break;
      case 'equipoPadre': equipoPadre = value; break;
      case 'modelo': modelo = value; break;
      case 'numeroSerie': numeroSerie = value; break;
      case 'variableMedida': variableMedida = value; break;
      case 'rangoLrv': rangoLrv = value; break;
      case 'rangoUrv': rangoUrv = value; break;
      case 'unidadIngenieria': unidadIngenieria = value; break;
      case 'senalEntradaSalida': senalEntradaSalida = value; break;
      case 'estadoFisicoObservado': estadoFisicoObservado = value; break;
      case 'estadoOperativoObservado': estadoOperativoObservado = value; break;
      case 'observacion': observacion = value; break;
    }
    _guardarBorrador();
    notifyListeners();
  }

  Future<void> capturarFoto(String tipo) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1280,
      maxHeight: 1280,
    );

    if (photo != null) {
      final bytes = await photo.readAsBytes();
      final base64String = base64Encode(bytes);

      if (tipo == 'placa') {
        fotoPlaca = photo;
        fotoPlacaBase64 = base64String;
      } else {
        fotoGeneral = photo;
        fotoGeneralBase64 = base64String;
      }
      _guardarBorrador();
      notifyListeners();
    }
  }

  Future<void> guardarLevantamientoFinal() async {
    guardandoEnRed = true;
    notifyListeners();

    final bool esEdicion = idLevantamientoTemporal != null;
    final String idFinal = idLevantamientoTemporal ?? const Uuid().v4();
    final String emailActual = FirebaseAuth.instance.currentUser?.email ?? 'Desconocido';
    final String creadorFinal = _nombreAuditor.isNotEmpty ? _nombreAuditor : emailActual;

    final datos = {
      'id_levantamiento': idFinal,
      'es_edicion': esEdicion,
      'codigo': codigo,
      'codigo_minuscula': codigo.toLowerCase(), // <-- CAMBIO CLAVE: Permite que funcione el buscador.
      'descripcion': descripcion,
      'familia': familia,
      'areaProceso': areaProceso,
      'ubicacionTecnica': ubicacionTecnica,
      'equipoPadre': equipoPadre,
      'modelo': modelo,
      'numeroSerie': numeroSerie,
      'variableMedida': variableMedida,
      'rangoLrv': rangoLrv,
      'rangoUrv': rangoUrv,
      'unidadIngenieria': unidadIngenieria,
      'senalEntradaSalida': senalEntradaSalida,
      'estadoFisicoObservado': estadoFisicoObservado,
      'estadoOperativoObservado': estadoOperativoObservado,
      'fechaVerificacion': fechaVerificacion.toIso8601String(),
      'observacion': observacion,
      'fotoPlacaUrl': fotoPlacaUrlExistente,
      'fotoGeneralUrl': fotoGeneralUrlExistente,
      
      'fotoPlacaBase64': fotoPlaca != null ? fotoPlacaBase64 : null,
      'fotoGeneralBase64': fotoGeneral != null ? fotoGeneralBase64 : null,
      
      'uid_creador': uidCreadorExistente,
      'email_creador': esEdicion ? emailCreadorExistente : creadorFinal,
      'email_original': emailActual,
    };
    
    try {
      final exito = await SincronizacionService().sincronizarRegistroInmediato(datos).timeout(const Duration(seconds: 10));
      if (!exito) {
        _pendientes.add(datos);
      }
    } catch (e) {
      _pendientes.add(datos);
    }

    guardandoEnRed = false;
    resetForm();
  }

  void cargarLevantamientoExistente(String docId, Map<String, dynamic> datos) async {
    idLevantamientoTemporal = docId;
    codigo = datos['codigo'] ?? '';
    descripcion = datos['descripcion'] ?? '';
    familia = datos['familia'] ?? '';
    areaProceso = datos['areaProceso'] ?? '';
    ubicacionTecnica = datos['ubicacionTecnica'] ?? '';
    equipoPadre = datos['equipoPadre'] ?? '';
    modelo = datos['modelo'] ?? '';
    numeroSerie = datos['numeroSerie'] ?? '';
    variableMedida = datos['variableMedida'] ?? '';
    rangoLrv = datos['rangoLrv']?.toString() ?? '';
    rangoUrv = datos['rangoUrv']?.toString() ?? '';
    unidadIngenieria = datos['unidadIngenieria'] ?? '';
    senalEntradaSalida = datos['senalEntradaSalida'] ?? '';
    estadoFisicoObservado = datos['estadoFisicoObservado'] ?? 'Bueno';
    estadoOperativoObservado = datos['estadoOperativoObservado'] ?? 'Operativa';
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
    fotoGeneralUrlExistente = datos['fotoGeneralUrl'];
    
    fotoPlacaBase64 = null;
    fotoGeneralBase64 = null;
    fotoPlaca = null;
    fotoGeneral = null;

    notifyListeners();

    if (fotoPlacaUrlExistente != null) {
      final bytesPlaca = await ImageCacheManager.obtenerImagen(fotoPlacaUrlExistente!);
      if (bytesPlaca != null) {
        fotoPlacaBase64 = base64Encode(bytesPlaca);
        notifyListeners();
      }
    }

    if (fotoGeneralUrlExistente != null) {
      final bytesGeneral = await ImageCacheManager.obtenerImagen(fotoGeneralUrlExistente!);
      if (bytesGeneral != null) {
        fotoGeneralBase64 = base64Encode(bytesGeneral);
        notifyListeners();
      }
    }
  }

  void resetForm() {
    codigo = '';
    descripcion = '';
    familia = '';
    areaProceso = '';
    ubicacionTecnica = '';
    equipoPadre = '';
    modelo = '';
    numeroSerie = '';
    variableMedida = '';
    rangoLrv = '';
    rangoUrv = '';
    unidadIngenieria = '';
    senalEntradaSalida = '';
    estadoFisicoObservado = 'Bueno';
    estadoOperativoObservado = 'Operativa';
    fechaVerificacion = DateTime.now();
    observacion = '';
    fotoPlaca = null;
    fotoGeneral = null;
    fotoPlacaBase64 = null;
    fotoGeneralBase64 = null;
    
    idLevantamientoTemporal = null;
    fotoPlacaUrlExistente = null;
    fotoGeneralUrlExistente = null;
    uidCreadorExistente = null;
    emailCreadorExistente = null;

    _borrador.clear();
    notifyListeners();
  }

  void _guardarBorrador() {
    _borrador.putAll({
      'idLevantamientoTemporal': idLevantamientoTemporal,
      'codigo': codigo,
      'descripcion': descripcion,
      'familia': familia,
      'areaProceso': areaProceso,
      'ubicacionTecnica': ubicacionTecnica,
      'equipoPadre': equipoPadre,
      'modelo': modelo,
      'numeroSerie': numeroSerie,
      'variableMedida': variableMedida,
      'rangoLrv': rangoLrv,
      'rangoUrv': rangoUrv,
      'unidadIngenieria': unidadIngenieria,
      'senalEntradaSalida': senalEntradaSalida,
      'estadoFisicoObservado': estadoFisicoObservado,
      'estadoOperativoObservado': estadoOperativoObservado,
      'fechaVerificacion': fechaVerificacion.toIso8601String(),
      'observacion': observacion,
      'fotoPlacaUrlExistente': fotoPlacaUrlExistente,
      'fotoGeneralUrlExistente': fotoGeneralUrlExistente,
      'fotoPlacaBase64': fotoPlacaBase64,
      'fotoGeneralBase64': fotoGeneralBase64,
      'uidCreadorExistente': uidCreadorExistente,
      'emailCreadorExistente': emailCreadorExistente,
    });
  }

  void _cargarBorrador() {
    if (_borrador.isNotEmpty) {
      idLevantamientoTemporal = _borrador.get('idLevantamientoTemporal');
      codigo = _borrador.get('codigo', defaultValue: '');
      descripcion = _borrador.get('descripcion', defaultValue: '');
      familia = _borrador.get('familia', defaultValue: '');
      areaProceso = _borrador.get('areaProceso', defaultValue: '');
      ubicacionTecnica = _borrador.get('ubicacionTecnica', defaultValue: '');
      equipoPadre = _borrador.get('equipoPadre', defaultValue: '');
      modelo = _borrador.get('modelo', defaultValue: '');
      numeroSerie = _borrador.get('numeroSerie', defaultValue: '');
      variableMedida = _borrador.get('variableMedida', defaultValue: '');
      rangoLrv = _borrador.get('rangoLrv', defaultValue: '');
      rangoUrv = _borrador.get('rangoUrv', defaultValue: '');
      unidadIngenieria = _borrador.get('unidadIngenieria', defaultValue: '');
      senalEntradaSalida = _borrador.get('senalEntradaSalida', defaultValue: '');
      estadoFisicoObservado = _borrador.get('estadoFisicoObservado', defaultValue: 'Bueno');
      estadoOperativoObservado = _borrador.get('estadoOperativoObservado', defaultValue: 'Operativa');
      uidCreadorExistente = _borrador.get('uidCreadorExistente');
      emailCreadorExistente = _borrador.get('emailCreadorExistente');

      final fechaStr = _borrador.get('fechaVerificacion');
      if (fechaStr != null) {
        fechaVerificacion = DateTime.parse(fechaStr);
      }

      observacion = _borrador.get('observacion', defaultValue: '');
      fotoPlacaUrlExistente = _borrador.get('fotoPlacaUrlExistente');
      fotoGeneralUrlExistente = _borrador.get('fotoGeneralUrlExistente');
      fotoPlacaBase64 = _borrador.get('fotoPlacaBase64');
      fotoGeneralBase64 = _borrador.get('fotoGeneralBase64');
    }
  }
}