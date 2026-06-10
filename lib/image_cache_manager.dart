import 'dart:convert';
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'sincronizacion_service.dart';

class ImageCacheManager {
  static final Box _cacheBox = Hive.box('cache_imagenes');
  static const int _maxImagenesEnCache = 1600;

  static Future<Uint8List?> obtenerImagen(String fileId) async {
    if (_cacheBox.containsKey(fileId)) {
      final dynamic data = _cacheBox.get(fileId);
      if (data is String) {
          try {
             return base64Decode(data);
          } catch(e) {
             await _cacheBox.delete(fileId); 
          }
      }
    }

    final String? base64String = await SincronizacionService.descargarImagenDriveBase64(fileId);
    
    if (base64String != null && base64String.isNotEmpty) {
      await _guardarImagenEnCache(fileId, base64String);
      return base64Decode(base64String);
    }
    
    return null;
  }

  static Future<void> _guardarImagenEnCache(String fileId, String base64String) async {
    await _cacheBox.put(fileId, base64String);
    
    if (_cacheBox.length > _maxImagenesEnCache) {
      final int excedente = _cacheBox.length - _maxImagenesEnCache;
      final keysAEliminar = _cacheBox.keys.take(excedente).toList();
      await _cacheBox.deleteAll(keysAEliminar);
    }
  }
  
  static Future<void> eliminarImagen(String fileId) async {
    if (_cacheBox.containsKey(fileId)) {
      await _cacheBox.delete(fileId);
    }
  }
  
  static Future<void> limpiarCache() async {
    await _cacheBox.clear();
  }
}