import 'package:file_picker/file_picker.dart';
import 'package:excel_community/excel_community.dart';
import 'package:flutter/foundation.dart';

class ExcelParserService {
  Future<Map<String, Map<String, dynamic>>?> cargarYProcesarExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        if (result.files.single.size > 5 * 1024 * 1024) {
          throw Exception('LIMITE_5MB');
        }

        final bytes = result.files.single.bytes!;
        return await compute(_decodificarExcel, bytes);
      }
      return null;
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  static Map<String, Map<String, dynamic>> _decodificarExcel(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);
    Map<String, Map<String, dynamic>> mapaExcel = {};

    for (var table in excel.tables.keys) {
      var hoja = excel.tables[table]!;
      
      if (hoja.maxRows == 0) continue;

      int indiceCodigo = -1;
      int indiceDescripcion = -1;
      int indiceFabricante = -1;
      int indiceModelo = -1;
      int indiceSerial = -1;
      int indiceUbicacion = -1;

      var filaEncabezados = hoja.row(0);
      for (int c = 0; c < filaEncabezados.length; c++) {
        var valorCelda = filaEncabezados[c]?.value?.toString().toLowerCase().trim() ?? '';
        
        if (valorCelda == 'código' || valorCelda == 'codigo') {
          indiceCodigo = c;
        } else if (valorCelda == 'descripción' || valorCelda == 'descripcion') {
          indiceDescripcion = c;
        } else if (valorCelda == 'fabricante') {
          indiceFabricante = c;
        } else if (valorCelda == 'modelo') {
          indiceModelo = c;
        } else if (valorCelda.contains('serial')) {
          indiceSerial = c;
        } else if (valorCelda.contains('ubicado')) {
          indiceUbicacion = c;
        }
      }

      if (indiceCodigo == -1) continue;

      for (var i = 1; i < hoja.maxRows; i++) {
        var fila = hoja.row(i);
        
        if (fila.length > indiceCodigo && fila[indiceCodigo]?.value != null) {
          String codigoExcel = fila[indiceCodigo]!.value.toString().trim();
          
          if (codigoExcel.isEmpty) continue;

          String obtenerValor(int indice) {
            if (indice != -1 && fila.length > indice && fila[indice]?.value != null) {
              return fila[indice]!.value.toString().trim();
            }
            return '';
          }

          mapaExcel[codigoExcel] = {
            'descripcion': obtenerValor(indiceDescripcion),
            'marca': obtenerValor(indiceFabricante),
            'modelo': obtenerValor(indiceModelo),
            'numeroSerie': obtenerValor(indiceSerial),
            'ubicacion': obtenerValor(indiceUbicacion),
          };
        }
      }

      if (mapaExcel.isNotEmpty) {
        break;
      }
    }
    
    return mapaExcel;
  }
}