import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RagApiService {
  final String baseUrl = 'https://isa-rag-api.onrender.com/api/v1';
  final String _boxName = 'rag_cache';

  Future<void> initHive() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  String _normalizarPregunta(String texto) {
    String t = texto.toLowerCase().trim();
    
    t = t.replaceAll(RegExp(r'[áäâà]'), 'a');
    t = t.replaceAll(RegExp(r'[éëêè]'), 'e');
    t = t.replaceAll(RegExp(r'[íïîì]'), 'i');
    t = t.replaceAll(RegExp(r'[óöôò]'), 'o');
    t = t.replaceAll(RegExp(r'[úüûù]'), 'u');
    
    t = t.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    
    return t;
  }

  Future<Map<String, dynamic>> consultarManual(String pregunta) async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    
    final box = Hive.box(_boxName);
    final String preguntaKey = _normalizarPregunta(pregunta);
    
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    final bool offline = connectivityResult.contains(ConnectivityResult.none);

    if (offline) {
      if (box.containsKey(preguntaKey)) {
        final cachedData = box.get(preguntaKey);
        Map<String, dynamic> response = Map<String, dynamic>.from(jsonDecode(cachedData));
        response['fromCache'] = true;
        return response;
      } else {
        throw Exception('Sin conexion de red local');
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No autenticado');

    final token = await user.getIdToken(true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/consultar-manual'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': token!,
        },
        body: jsonEncode({'pregunta': pregunta}),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        box.put(preguntaKey, response.body);
        Map<String, dynamic> data = jsonDecode(response.body);
        data['fromCache'] = false;
        return data;
      } else {
        throw Exception('HTTP_${response.statusCode}_${response.body}');
      }
    } on TimeoutException {
      throw Exception('Timeout_Servidor_Render');
    } catch (e) {
      if (box.containsKey(preguntaKey)) {
        final cachedData = box.get(preguntaKey);
        Map<String, dynamic> response = Map<String, dynamic>.from(jsonDecode(cachedData));
        response['fromCache'] = true;
        return response;
      }
      throw Exception('Excepcion_Capturada: ${e.toString()}');
    }
  }
}