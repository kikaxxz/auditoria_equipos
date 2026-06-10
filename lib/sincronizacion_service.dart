import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'image_cache_manager.dart';

class SincronizacionService {
  static final SincronizacionService _instancia = SincronizacionService._interno();
  factory SincronizacionService() => _instancia;
  SincronizacionService._interno();

  final Box _pendientes = Hive.box('equipos_pendientes');
  bool _sincronizando = false;
  String? _gasToken;

  void iniciarEscucha() async {
    await Hive.box('equipos_pendientes').clear();

    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        sincronizarDatos();
      }
    });
    _inicializarConfiguracion();
    sincronizarDatos();
  }

  Future<void> _inicializarConfiguracion() async {
    try {
      if (!kIsWeb) {
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ));
        await remoteConfig.fetchAndActivate();
        _gasToken = remoteConfig.getString('gas_security_token');
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (_gasToken == null || _gasToken!.isEmpty) {
      _gasToken = 'Token_ISA_2026_ABC';
    }
  }

  Future<void> _modificarContadoresArea(String areaProceso, int incremento) async {
    final docRef = FirebaseFirestore.instance.collection('metricas').doc('conteos_areas');
    final partes = areaProceso.split(' / ');
    final Map<String, dynamic> actualizaciones = {};
    
    String rutaAcumulada = '';
    for (int i = 0; i < partes.length; i++) {
      if (i == 0) {
        rutaAcumulada = partes[i].trim();
      } else {
        rutaAcumulada += ' / ${partes[i].trim()}';
      }
      actualizaciones[rutaAcumulada] = FieldValue.increment(incremento);
    }
    
    if (actualizaciones.isNotEmpty) {
      await docRef.set(actualizaciones, SetOptions(merge: true));
    }
  }

  Future<bool> sincronizarRegistroInmediato(Map<String, dynamic> datos) async {
    try {
      final usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) return false;

      var conectividad = await (Connectivity().checkConnectivity());
      if (conectividad.contains(ConnectivityResult.none)) return false;

      if (_gasToken == null || _gasToken!.isEmpty) {
        await _inicializarConfiguracion();
      }

      if (datos['fotoPlacaBase64'] != null) {
        final String? urlAntiguaPlaca = datos['fotoPlacaUrl'];
        final urlPlaca = await _subirADrive(datos['fotoPlacaBase64'], 'PLACA_${datos['codigo']}');
        
        if (urlPlaca != null) {
          datos.remove('fotoPlacaBase64');
          datos['fotoPlacaUrl'] = urlPlaca;
          
          if (urlAntiguaPlaca != null && urlAntiguaPlaca.isNotEmpty) {
            await eliminarImagenDrive(urlAntiguaPlaca);
            await ImageCacheManager.eliminarImagen(urlAntiguaPlaca);
          }
        } else {
          return false;
        }
      }

      if (datos['fotoGeneralBase64'] != null) {
        final String? urlAntiguaGeneral = datos['fotoGeneralUrl'];
        final urlGeneral = await _subirADrive(datos['fotoGeneralBase64'], 'GENERAL_${datos['codigo']}');
        
        if (urlGeneral != null) {
          datos.remove('fotoGeneralBase64');
          datos['fotoGeneralUrl'] = urlGeneral;
          
          if (urlAntiguaGeneral != null && urlAntiguaGeneral.isNotEmpty) {
            await eliminarImagenDrive(urlAntiguaGeneral);
            await ImageCacheManager.eliminarImagen(urlAntiguaGeneral);
          }
        } else {
          return false;
        }
      }

      final copiaParaFirestore = Map<String, dynamic>.from(datos);
      copiaParaFirestore.removeWhere((k, v) => v == null);

      if (copiaParaFirestore['fechaVerificacion'] != null) {
        copiaParaFirestore['fechaVerificacion'] = Timestamp.fromDate(DateTime.parse(copiaParaFirestore['fechaVerificacion'].toString()));
      }

      copiaParaFirestore['uid_creador'] = usuario.uid;
      copiaParaFirestore['email_creador'] = usuario.email;
      copiaParaFirestore['nombre_creador'] = usuario.displayName;

      final bool esEdicion = copiaParaFirestore['es_edicion'] ?? false;
      copiaParaFirestore.remove('es_edicion');

      copiaParaFirestore['ultimaModificacion'] = FieldValue.serverTimestamp();

      if (!esEdicion) {
        copiaParaFirestore['sincronizadoEn'] = FieldValue.serverTimestamp();
      }

      copiaParaFirestore['codigo_minuscula'] = copiaParaFirestore['codigo'].toString().toLowerCase();

      final String? idLevantamiento = copiaParaFirestore['id_levantamiento'];

      String? areaAntigua;
      if (esEdicion && idLevantamiento != null) {
        final docSnap = await FirebaseFirestore.instance.collection('equipos').doc(idLevantamiento).get();
        if (docSnap.exists) {
          areaAntigua = docSnap.data()?['areaProceso']?.toString();
        }
      }

      if (esEdicion && areaAntigua != null && areaAntigua != copiaParaFirestore['areaProceso']) {
        await _modificarContadoresArea(areaAntigua, -1);
        await _modificarContadoresArea(copiaParaFirestore['areaProceso'].toString(), 1);
      } else if (!esEdicion) {
        await _modificarContadoresArea(copiaParaFirestore['areaProceso'].toString(), 1);
      }

      if (idLevantamiento != null) {
        await FirebaseFirestore.instance.collection('equipos').doc(idLevantamiento).set(copiaParaFirestore, SetOptions(merge: true));
      } else {
        await FirebaseFirestore.instance.collection('equipos').add(copiaParaFirestore);
      }

      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<void> sincronizarDatos() async {
    if (_sincronizando || _pendientes.isEmpty) return;

    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    var conectividad = await (Connectivity().checkConnectivity());
    if (conectividad.contains(ConnectivityResult.none)) return;

    if (_gasToken == null || _gasToken!.isEmpty) {
      await _inicializarConfiguracion();
    }

    _sincronizando = true;
    final keys = _pendientes.keys.toList();

    try {
      for (var key in keys) {
        final datos = Map<String, dynamic>.from(_pendientes.get(key));
        bool actualizarHive = false;

        String? urlPlaca = datos['fotoPlacaUrl'];
        String? urlGeneral = datos['fotoGeneralUrl'];

        if (datos['fotoPlacaBase64'] != null) {
          final String? urlAntiguaPlaca = urlPlaca;
          urlPlaca = await _subirADrive(datos['fotoPlacaBase64'], 'PLACA_${datos['codigo']}');
          datos.remove('fotoPlacaBase64');
          
          if (urlPlaca != null) {
            datos['fotoPlacaUrl'] = urlPlaca;
            if (urlAntiguaPlaca != null && urlAntiguaPlaca.isNotEmpty) {
              await eliminarImagenDrive(urlAntiguaPlaca);
              await ImageCacheManager.eliminarImagen(urlAntiguaPlaca);
            }
          }
          actualizarHive = true;
        }

        if (datos['fotoGeneralBase64'] != null) {
          final String? urlAntiguaGeneral = urlGeneral;
          urlGeneral = await _subirADrive(datos['fotoGeneralBase64'], 'GENERAL_${datos['codigo']}');
          datos.remove('fotoGeneralBase64');
          
          if (urlGeneral != null) {
            datos['fotoGeneralUrl'] = urlGeneral;
            if (urlAntiguaGeneral != null && urlAntiguaGeneral.isNotEmpty) {
              await eliminarImagenDrive(urlAntiguaGeneral);
              await ImageCacheManager.eliminarImagen(urlAntiguaGeneral);
            }
          }
          actualizarHive = true;
        }

        if (actualizarHive) {
          await _pendientes.put(key, datos);
        }

        datos.removeWhere((k, v) => v == null);

        if (datos['fechaVerificacion'] != null) {
          datos['fechaVerificacion'] = Timestamp.fromDate(DateTime.parse(datos['fechaVerificacion'].toString()));
        }

        datos['uid_creador'] = usuario.uid;
        datos['email_creador'] = usuario.email;
        datos['nombre_creador'] = usuario.displayName;

        final bool esEdicion = datos['es_edicion'] ?? false;
        datos.remove('es_edicion');

        datos['ultimaModificacion'] = FieldValue.serverTimestamp();

        if (!esEdicion) {
          datos['sincronizadoEn'] = FieldValue.serverTimestamp();
        }

        datos['codigo_minuscula'] = datos['codigo'].toString().toLowerCase();

        final String? idLevantamiento = datos['id_levantamiento'];

        String? areaAntigua;
        if (esEdicion && idLevantamiento != null) {
          final docSnap = await FirebaseFirestore.instance.collection('equipos').doc(idLevantamiento).get();
          if (docSnap.exists) {
            areaAntigua = docSnap.data()?['areaProceso']?.toString();
          }
        }

        if (esEdicion && areaAntigua != null && areaAntigua != datos['areaProceso']) {
          await _modificarContadoresArea(areaAntigua, -1);
          await _modificarContadoresArea(datos['areaProceso'].toString(), 1);
        } else if (!esEdicion) {
          await _modificarContadoresArea(datos['areaProceso'].toString(), 1);
        }

        if (idLevantamiento != null) {
          await FirebaseFirestore.instance.collection('equipos').doc(idLevantamiento).set(datos, SetOptions(merge: true));
        } else {
          await FirebaseFirestore.instance.collection('equipos').add(datos);
        }

        await _pendientes.delete(key);

        await Future.delayed(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint(e.toString());
      if (keys.isNotEmpty) {
        await _pendientes.delete(keys.first);
      }
    } finally {
      _sincronizando = false;
    }
  }

  Future<String?> _subirADrive(String base64Str, String prefijo, {int intentos = 0}) async {
    final url = Uri.parse('https://script.google.com/macros/s/AKfycbyTWspMja3IrBHwSvwAePgX1TkFynYNJayyjqXTnUEM-rWOkH-rtUluMVyFx7wbAm5E/exec');
    final nombreArchivo = '${prefijo}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      debugPrint('Subida Rastreo 1: Iniciando intento $intentos para $nombreArchivo');
      debugPrint('Subida Rastreo 2: Longitud base64 a enviar: ${base64Str.length}');

      final bodyData = jsonEncode({
        'security_token': _gasToken, 
        'filename': nombreArchivo,
        'image': base64Str,
      });

      debugPrint('Subida Rastreo 3: jsonEncode completado, ejecutando http.post');

      final respuesta = await http.post(
        url,
        headers: {'Content-Type': 'text/plain'},
        body: bodyData,
      );

      debugPrint('Subida Rastreo 4: http.post finalizado con status ${respuesta.statusCode}');
      
      final bodyText = respuesta.body.trim();
      debugPrint('Subida Rastreo 5: Respuesta body length: ${bodyText.length}');

      if (bodyText.toLowerCase().startsWith('<') || bodyText.toLowerCase().contains('<!doctype html>')) {
         debugPrint('Subida Rastreo 6: ERROR FATAL - Google devolvió HTML');
         return null;
      }

      if (respuesta.statusCode == 200) {
        debugPrint('Subida Rastreo 7: Parseando JSON de respuesta');
        final rDatos = jsonDecode(bodyText);
        
        if (rDatos['success'] == true) {
          debugPrint('Subida Rastreo 8: Subida exitosa, fileId: ${rDatos['fileId']}');
          return rDatos['fileId'];
        } else if (rDatos.containsKey('error')) {
          debugPrint('Subida Rastreo 9: Error devuelto por el script: ${rDatos['error']}');
          if (intentos < 3) {
            await Future.delayed(Duration(seconds: 2 * (intentos + 1)));
            return await _subirADrive(base64Str, prefijo, intentos: intentos + 1);
          }
        }
      } else if ((respuesta.statusCode == 429 || respuesta.statusCode == 500) && intentos < 3) {
        debugPrint('Subida Rastreo 10: Status ${respuesta.statusCode}, reintentando...');
        await Future.delayed(Duration(seconds: 2 * (intentos + 1)));
        return await _subirADrive(base64Str, prefijo, intentos: intentos + 1);
      }
    } catch (e) {
      debugPrint('Subida Rastreo 11: Excepcion atrapada - ${e.toString()}');
      if (intentos < 3) {
        await Future.delayed(Duration(seconds: 2 * (intentos + 1)));
        return await _subirADrive(base64Str, prefijo, intentos: intentos + 1);
      }
    }
    return null;
  }

  Future<bool> eliminarImagenDrive(String fileId) async {
    final url = Uri.parse('https://script.google.com/macros/s/AKfycbyTWspMja3IrBHwSvwAePgX1TkFynYNJayyjqXTnUEM-rWOkH-rtUluMVyFx7wbAm5E/exec');
                           
    if (_gasToken == null || _gasToken!.isEmpty) {
      await _inicializarConfiguracion();
    }

    try {
      final respuesta = await http.post(
        url,
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode({
          'action': 'delete',
          'security_token': _gasToken,
          'fileId': fileId,
        }),
      );

      if (respuesta.statusCode == 200) {
        final rDatos = jsonDecode(respuesta.body);
        return rDatos['success'] == true;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
  }

  static Future<String?> descargarImagenDriveBase64(String fileId) async {
    final url = Uri.parse('https://script.google.com/macros/s/AKfycbyTWspMja3IrBHwSvwAePgX1TkFynYNJayyjqXTnUEM-rWOkH-rtUluMVyFx7wbAm5E/exec'
        '?action=get&security_token=Token_ISA_2026_ABC&fileId=${fileId.trim()}');
    
    try {
      final respuesta = await http.get(url);

      if (respuesta.statusCode == 200 || respuesta.statusCode == 302) {
        final bodyJson = jsonDecode(respuesta.body);

        if (bodyJson['success'] == true && bodyJson.containsKey('image')) {
            String base64Data = bodyJson['image'];
            base64Data = base64Data.replaceAll(RegExp(r'\s+'), '');
            
            int padding = base64Data.length % 4;
            if (padding != 0) {
              base64Data += '=' * (4 - padding);
            }
            return base64Data; 
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }
}