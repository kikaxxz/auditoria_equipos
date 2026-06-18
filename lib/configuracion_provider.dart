import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'constantes.dart' as constantes;

const List<String> opcionesFamilia = [
  'N/A', 'Acelerómetro (ACEL)', 'Amplificador (AMPL)', 'Atemperador Mecánico (ATEM)', 'Caja Sumadora (CAAD)',
  'Celda de Carga (CELC)', 'Celda de Oxígeno (CLOX)', 'Chute (DUCT)', 'Cilindro Neumat (CILI)',
  'Controlador (CNTR)', 'Controlador de Oxígeno (COXG)', 'Convertidor (CONV)', 'Ducto (DUCT)',
  'Encoder Rotativo (ENRO)', 'Estación A/M (ESTN)', 'Estación de Trabajo (ESTA)', 'Fibra Óptica (FIBR)',
  'Filtro Malla (FILT)', 'Gabinete de Comunicaciones (GABI)', 'Gabinete de Control (GABI)',
  'Gabinete de Electrovalvulas (GABI)', 'Gabinete de Respaldo Energético (GABI)', 'Inflador Neumat (CILI)',
  'Interruptor de Nivel (INTP)', 'Manómetro Analógico (MANO)', 'Mordaza (MORD)', 'Nivel Electrónico (NIVE)',
  'Nivel Mecánico (NIVE)', 'Pedal (PEDA)', 'Placa Orificio (PLAC)', 'Radiocontrol (RADI)',
  'Recinto (RECI)', 'Refractómetro (REFR)', 'Registrador (REGI)', 'Rotámetro Analógico (ROTA)',
  'Sens Capacitivo (SENS)', 'Sens de Expansión Diferencial (SENS)', 'Sens de Nivel (SENS)',
  'Sens Desplazamiento Axial (SENS)', 'Sens Fotoeléctrico (SENS)', 'Sens Inductivo (SENS)',
  'Sens Neumat (SENS)', 'Sens RTD (SENS)', 'Servomotor (SERV)', 'Sistema de Monitoreo de Cámaras (CAM)',
  'Sistema de Respaldo Energético (RESP)', 'Servidor de Control (SERC)', 'Termómetro Analógico (TERM)',
  'Transmisor de Brix (TRNX)', 'Transmisor de Conductividad (TRNX)', 'Transmisor de Densidad (TRNX)',
  'Transmisor de Flujo Magnético (TRNX)', 'Transmisor de Flujo Másico (TRNX)', 'Transmisor de Flujo Volumétrico (TRNX)',
  'Transmisor de Nivel (TRNX)', 'Transmisor de PH (TRNX)', 'Transmisor de Presión Absoluta (TRNX)',
  'Transmisor de Presión Diferencial (TRNX)', 'Transmisor de Presión Manométrica (TRNX)',
  'Transmisor de Radar Guiado (TRNX)', 'Transmisor de Temp (TRNX)', 'Transmisor NIR (TRNX)',
  'Transmisor Radar (TRNX)', 'Transmisor Vibraciones (TRNX)', 'Tubo Pitot (PILO / TUBO)',
  'Tubo Venturi (TUBO)', 'Vacuómetro Analógico (VACU)', 'Válvula de Control (VALV)',
  'Válvula Eléctrica (VALV)', 'Válvula Globo (VALV)', 'Válvula ON/OFF (VALV)', 'Otro...'
];

const List<String> opcionesMarcas = [
  'N/A','ABB', 'ACTAIR', 'AIR TORQUE', 'ALFA LAVAL', 'APC', 'ASHCROFT', 'AT-CONTROLS', 'AUMA',
  'AUTONICS', 'AVERY WEIGH-TRONIX', 'B&K VIBRO', 'BANNER', 'BERNARD CONTROLS', 'BERTHOLD TECHNOLOGIES',
  'BIFFI', 'BRAY', 'BURKERT', 'CENTEC', 'CHRONOS RICHARDSON', 'CONTROL WEIGH', 'DIGITRANS', 'DLG',
  'ELCA', 'ELITE VALVE', 'ENDRESS+HAUSER', 'FERTRON', 'FESTO', 'FISHER', 'FIVES CAIL', 'FLETCHER SMITH',
  'FOXBORO','GRINNELL', 'HAGGLUNDS', 'HAITIMA', 'HBM', 'HIMEL', 'HITER', 'HP', 'IMI NORGREN', 'JORGE E. JARAMILLO & CIA. LTDA.',
  'K-PATENTS PROCESS INSTRUMENTS', 'KEYSTONE', 'KROHNE', 'KSB', 'MOISTECH CORP', 'MORIN', 'NKS', 'NOVUS',
  'NVENT', 'OHIO VALVE', 'OPTIMUX', 'ORBINOX', 'PARKER', 'PESA PACK', 'PHOENIX CONTACT', 'PLATON', 'PROMTEC',
  'RELIANCE', 'REVERE TRANSDUCERS', 'RITTAL', 'ROSEMOUNT', 'ROTORK', 'SAMSON', 'SCHNEIDER ELECTRIC',
  'SCHUBERT & SALZER', 'SEW EURODRIVE', 'SHINKAWA', 'SICK', 'SIEMENS', 'SIERRA', 'SMAR', 'TEKPAN',
  'TELEMECANIQUE', 'TOTALCOMP', 'TRERICE', 'TRIAC', 'TUB', 'TURCK', 'TYCO', 'UWT', 'VEGA', 'VERIS',
  'WEISS INSTRUMENTS', 'WEPOWER', 'WIKA', 'YOKOGAWA', 'Otro...'
];

const List<String> opcionesUnidades = [
  'N/A (manual)', 'Seleccionar', 'psi (Presion)', 'bar (Presion)', 'mbar (Presion)', 'kPa (Presion)',
  'MPa (Presion)', 'kg/cm2 (Presion)', 'inH2O (Presion)', 'mmH2O (Presion)', 'inHg (Presion)', 'mmHg (Presion)',
  'C (Temperatura)', 'F (Temperatura)', 'K (Temperatura)', 'mA (Senal electrica/control)',
  '4-20 mA (Senal electrica/control)', 'V (Senal electrica/control)', 'mV (Senal electrica/control)',
  'Vdc (Senal electrica/control)', 'Vac (Senal electrica/control)', 'Hz (Senal electrica/control)',
  'Ohm (Senal electrica/control)', 'm3/h (Flujo)', 'L/min (Flujo)', 'L/h (Flujo)', 'GPM (Flujo)', 'kg/h (Flujo)',
  't/h (Flujo)', '% (Nivel)', 'mm (Nivel)', 'cm (Nivel)', 'm (Nivel)', 'kg (Peso/dosificacion)',
  'g (Peso/dosificacion)', 't (Peso/dosificacion)', 'rpm (Otros)', 'pH (Otros)', 'uS/cm (Otros)',
  'ppm (Otros)', 'NTU (Otros)', 'Otro...'
];

class TreeNode {
  final String name;
  final String fullPath;
  final Map<String, TreeNode> children = {};

  TreeNode({required this.name, required this.fullPath});

  bool get isLeaf => children.isEmpty;
}

class ConfiguracionProvider extends ChangeNotifier {
  List<String> _marcas = [];
  List<String> _familias = [];
  List<String> _unidades = [];
  List<String> _areasProceso = [];
  TreeNode _arbolJerarquico = TreeNode(name: 'Raíz', fullPath: '');

  bool _cargando = true;

  List<String> get marcas => _marcas;
  List<String> get familias => _familias;
  List<String> get unidades => _unidades;
  List<String> get areasProceso => _areasProceso;
  TreeNode get arbolJerarquico => _arbolJerarquico;
  bool get cargando => _cargando;

  final Box _cache = Hive.box('configuracion_cache');

  ConfiguracionProvider() {
    cargarDiccionarios();
  }

  Future<void> cargarDiccionarios() async {
  _cargando = true;
  notifyListeners();

  _cargarDeCache();

  try {
    var conectividad = await Connectivity().checkConnectivity();
    if (!conectividad.contains(ConnectivityResult.none)) {
      final docRef = FirebaseFirestore.instance.collection('configuracion').doc('diccionarios');
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        _marcas = List<String>.from(data['marcas'] ?? _marcas);
        _familias = List<String>.from(data['familias'] ?? _familias);
        _unidades = List<String>.from(data['unidades'] ?? _unidades);
        _areasProceso = List<String>.from(data['areas_proceso'] ?? _areasProceso);

        if (_areasProceso.isEmpty) {
          _areasProceso = List<String>.from(constantes.areasProceso);
          await docRef.update({'areas_proceso': _areasProceso});
        }

        _procesarDatosEstructurados();
        _guardarEnCache();
      } else {
        await _inicializarDocumentoPorDefecto(docRef);
      }
    }
  } catch (e) {
    debugPrint(e.toString());
  } finally {
    _cargando = false;
    notifyListeners();
  }
}

  Future<void> _inicializarDocumentoPorDefecto(DocumentReference docRef) async {
  final datosIniciales = {
    'marcas': opcionesMarcas,
    'familias': opcionesFamilia,
    'unidades': opcionesUnidades,
    'areas_proceso': constantes.areasProceso,
  };

  await docRef.set(datosIniciales);

  _marcas = List<String>.from(opcionesMarcas);
  _familias = List<String>.from(opcionesFamilia);
  _unidades = List<String>.from(opcionesUnidades);
  _areasProceso = List<String>.from(constantes.areasProceso);

  _procesarDatosEstructurados();
  _guardarEnCache();
}

  void _procesarDatosEstructurados() {
    _marcas.sort();
    _familias.sort();
    _unidades.sort();
    _areasProceso.sort();
    _construirArbol();
  }

  void _construirArbol() {
    _arbolJerarquico = TreeNode(name: 'Raíz', fullPath: '');

    for (String ruta in _areasProceso) {
      List<String> niveles = ruta.split(' / ');
      TreeNode nodoActual = _arbolJerarquico;
      String rutaAcumulada = '';

      for (int i = 0; i < niveles.length; i++) {
        String nivel = niveles[i].trim();
        if (nivel.isEmpty) continue;

        rutaAcumulada = i == 0 ? nivel : '$rutaAcumulada / $nivel';

        if (!nodoActual.children.containsKey(nivel)) {
          nodoActual.children[nivel] = TreeNode(name: nivel, fullPath: rutaAcumulada);
        }
        nodoActual = nodoActual.children[nivel]!;
      }
    }
  }

  void _guardarEnCache() {
    _cache.put('marcas', _marcas);
    _cache.put('familias', _familias);
    _cache.put('unidades', _unidades);
    _cache.put('areas_proceso', _areasProceso);
  }

  void _cargarDeCache() {
    if (_cache.isNotEmpty) {
      _marcas = List<String>.from(_cache.get('marcas', defaultValue: <String>[]));
      _familias = List<String>.from(_cache.get('familias', defaultValue: <String>[]));
      _unidades = List<String>.from(_cache.get('unidades', defaultValue: <String>[]));
      _areasProceso = List<String>.from(_cache.get('areas_proceso', defaultValue: <String>[]));
      _procesarDatosEstructurados();
    }
  }

  Future<bool> agregarElemento(String tipoArreglo, String nuevoValor) async {
    final docRef = FirebaseFirestore.instance.collection('configuracion').doc('diccionarios');
    try {
      await docRef.update({
        tipoArreglo: FieldValue.arrayUnion([nuevoValor.trim()])
      });
      await cargarDiccionarios();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> eliminarElemento(String tipoArreglo, String valorAEliminar) async {
    final docRef = FirebaseFirestore.instance.collection('configuracion').doc('diccionarios');
    try {
      await docRef.update({
        tipoArreglo: FieldValue.arrayRemove([valorAEliminar])
      });
      await cargarDiccionarios();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }
}