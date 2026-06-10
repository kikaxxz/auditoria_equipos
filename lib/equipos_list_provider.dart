import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class EquiposListProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _equipos = [];
  bool _cargando = false;
  bool _hayMas = true;
  DocumentSnapshot? _ultimoDocumento;
  final int _limite = 20;
  final Box _cache = Hive.box('equipos_cache');
  String _areaActual = '';

  List<Map<String, dynamic>> get equipos => _equipos;
  bool get cargando => _cargando;
  bool get hayMas => _hayMas;

  Future<void> cargarEquiposPorArea(String area, {bool reiniciar = false}) async {
    _areaActual = area;
    if (_cargando || (!_hayMas && !reiniciar)) return;

    _cargando = true;

    if (reiniciar) {
      _ultimoDocumento = null;
      _hayMas = true;
      _cargarDeCache();
      notifyListeners();
    } else {
      notifyListeners();
    }

    try {
      var conectividad = await (Connectivity().checkConnectivity());
      if (conectividad.contains(ConnectivityResult.none)) {
        _cargando = false;
        notifyListeners();
        return;
      }

      Query query = FirebaseFirestore.instance
          .collection('equipos')
          .where('areaProceso', isGreaterThanOrEqualTo: _areaActual)
          .where('areaProceso', isLessThan: '$_areaActual\uf8ff')
          .orderBy('areaProceso') 
          .orderBy('sincronizadoEn', descending: true)
          .limit(_limite);

      if (!reiniciar && _ultimoDocumento != null) {
        query = query.startAfterDocument(_ultimoDocumento!);
      }

      final QuerySnapshot snapshot = await query.get();

      if (reiniciar) {
        _equipos.clear();
      }

      if (snapshot.docs.isNotEmpty) {
        final nuevos = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id_documento'] = doc.id;
          
          if (doc.metadata.hasPendingWrites && data['sincronizadoEn'] == null) {
            data['sincronizadoEn'] = Timestamp.now();
          }
          
          return data;
        }).toList();

        _equipos.addAll(nuevos);
        _ultimoDocumento = snapshot.docs.last;

        if (reiniciar) {
          _guardarEnCache();
        }
      }

      _hayMas = snapshot.docs.length == _limite;
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> sanitizarParaHive(Map<String, dynamic> datos) {
    final mapSaneado = Map<String, dynamic>.from(datos);
    mapSaneado.forEach((key, value) {
      if (value is Timestamp) {
        mapSaneado[key] = value.toDate().toIso8601String();
      }
    });
    return mapSaneado;
  }

  void _guardarEnCache() {
    if (_areaActual.isEmpty) return;
    
    final paraCache = _equipos.map((e) {
      return sanitizarParaHive(e);
    }).toList();
    
    _cache.put('pagina_${_areaActual.hashCode}', paraCache);
  }

  void _cargarDeCache() {
    if (_areaActual.isEmpty) return;
    
    final datosCacheados = _cache.get('pagina_${_areaActual.hashCode}');
    if (datosCacheados != null) {
      _equipos = (datosCacheados as List).map((e) {
        final map = Map<String, dynamic>.from(e);
        if (map['sincronizadoEn'] != null) {
          map['sincronizadoEn'] = Timestamp.fromDate(DateTime.parse(map['sincronizadoEn']));
        }
        if (map['ultimaModificacion'] != null) {
          map['ultimaModificacion'] = Timestamp.fromDate(DateTime.parse(map['ultimaModificacion']));
        }
        return map;
      }).toList();
    } else {
      _equipos = [];
    }
  }

  void removerEquipoLocal(String idDocumento) {
    _equipos.removeWhere((e) => e['id_documento'] == idDocumento);
    notifyListeners();
  }

  Future<void> buscarEquipos(String termino) async {
    if (termino.isEmpty) {
      await cargarEquiposPorArea(_areaActual, reiniciar: true);
      return;
    }

    _cargando = true;
    notifyListeners();

    try {
      final String busqueda = termino.toLowerCase();
      final String finalBusqueda = '$busqueda\uf8ff';

      var conectividad = await (Connectivity().checkConnectivity());
      if (conectividad.contains(ConnectivityResult.none)) {
        _equipos = _equipos.where((eq) {
          final codigo = eq['codigo_minuscula'].toString();
          final area = eq['areaProceso'].toString();
          return codigo.startsWith(busqueda) && area.startsWith(_areaActual);
        }).toList();
        _hayMas = false;
        _cargando = false;
        notifyListeners();
        return;
      }

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('equipos')
          .where('codigo_minuscula', isGreaterThanOrEqualTo: busqueda)
          .where('codigo_minuscula', isLessThan: finalBusqueda)
          .get();

      final docsFiltrados = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final area = data['areaProceso'] as String? ?? '';
        return area.startsWith(_areaActual);
      }).take(_limite).toList();

      _equipos = docsFiltrados.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id_documento'] = doc.id;
        
        if (doc.metadata.hasPendingWrites && data['sincronizadoEn'] == null) {
          data['sincronizadoEn'] = Timestamp.now();
        }
        
        return data;
      }).toList();
      
      _hayMas = false;
      _ultimoDocumento = null;
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<Map<String, int>> obtenerEstadisticasOperativas() async {
    final estados = ['Operativa', 'Detenida', 'En mantenimiento', 'Fuera de servicio', 'Desconocido'];
    Map<String, int> resultados = {};
    try {
      for (var estado in estados) {
        final snapshot = await FirebaseFirestore.instance
            .collection('equipos')
            .where('estadoOperativoObservado', isEqualTo: estado)
            .count()
            .get();
        resultados[estado] = snapshot.count ?? 0;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return resultados;
  }

  Future<Map<String, int>> obtenerEstadosCriticos() async {
    Map<String, int> resultados = {'Malo': 0, 'Requiere reemplazo': 0};
    try {
      final snapshotMalo = await FirebaseFirestore.instance
          .collection('equipos')
          .where('estadoFisicoObservado', isEqualTo: 'Malo')
          .count()
          .get();
      final snapshotReemplazo = await FirebaseFirestore.instance
          .collection('equipos')
          .where('estadoFisicoObservado', isEqualTo: 'Requiere reemplazo')
          .count()
          .get();
      resultados['Malo'] = snapshotMalo.count ?? 0;
      resultados['Requiere reemplazo'] = snapshotReemplazo.count ?? 0;
    } catch (e) {
      debugPrint(e.toString());
    }
    return resultados;
  }

  Future<Map<String, int>> obtenerConteosPorMacroArea(List<String> areasPlanta) async {
    Map<String, int> conteosMacro = {};
    try {
      for (var areaCompleta in areasPlanta) {
        final partes = areaCompleta.split(' / ');
        final macroArea = partes[0].trim();

        final snapshot = await FirebaseFirestore.instance
            .collection('equipos')
            .where('areaProceso', isGreaterThanOrEqualTo: areaCompleta)
            .where('areaProceso', isLessThan: '$areaCompleta\uf8ff')
            .count()
            .get();

        final count = snapshot.count ?? 0;
        if (count > 0) {
          conteosMacro[macroArea] = (conteosMacro[macroArea] ?? 0) + count;
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return conteosMacro;
  }
}