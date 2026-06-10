import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
import 'package:cloud_firestore/cloud_firestore.dart';

class GeneradorExcel {
  static Future<void> exportarEquipos(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando archivo Excel, por favor espere...')),
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('equipos')
          .orderBy('sincronizadoEn', descending: true)
          .get();

      final List<Map<String, dynamic>> datosPlanos = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'codigo': data['codigo']?.toString() ?? '',
          'descripcion': data['descripcion']?.toString() ?? '',
          'equipoPadre': data['equipoPadre']?.toString() ?? '',
          'familia': data['familia']?.toString() ?? '',
          'areaProceso': data['areaProceso']?.toString() ?? '',
          'ubicacionTecnica': data['ubicacionTecnica']?.toString() ?? '',
          'modelo': data['modelo']?.toString() ?? '',
          'numeroSerie': data['numeroSerie']?.toString() ?? '',
          'variableMedida': data['variableMedida']?.toString() ?? '',
          'senalEntradaSalida': data['senalEntradaSalida']?.toString() ?? '',
          'rangoLrv': data['rangoLrv']?.toString() ?? '',
          'rangoUrv': data['rangoUrv']?.toString() ?? '',
          'unidadIngenieria': data['unidadIngenieria']?.toString() ?? '',
          'estadoOperativoObservado': data['estadoOperativoObservado']?.toString() ?? '',
          'estadoFisicoObservado': data['estadoFisicoObservado']?.toString() ?? '',
          'observacion': data['observacion']?.toString() ?? '',
          'email_creador': data['email_creador']?.toString() ?? '',
          'sincronizadoEn': data['sincronizadoEn'] != null ? (data['sincronizadoEn'] as Timestamp).toDate().toIso8601String() : null,
          'ultimaModificacion': data['ultimaModificacion'] != null ? (data['ultimaModificacion'] as Timestamp).toDate().toIso8601String() : null,
        };
      }).toList();

      final List<int> bytes = await compute(_procesarExcelAislado, datosPlanos);
      final Uint8List uint8List = Uint8List.fromList(bytes);

      final blob = web.Blob(
        [uint8List.toJS].toJS,
        web.BlobPropertyBag(type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      );
      final url = web.URL.createObjectURL(blob);

      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = 'Base_Datos_Auditoria.xlsx';

      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();

      web.URL.revokeObjectURL(url);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descarga completada.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }
}

List<int> _procesarExcelAislado(List<Map<String, dynamic>> datos) {
  final workbook = excel.Workbook();
  final sheet = workbook.worksheets[0];
  sheet.name = 'Equipos Auditados';

  final headers = [
    'Código (Tag)', 'Nombre del Equipo', 'Equipo Padre', 'Familia', 'Área de Proceso', 'Ubicación Técnica',
    'Marca', 'No. Serie', 'Variable Medida', 'Señal E/S',
    'Rango LRV', 'Rango URV', 'Unidad Ing.', 'Estado Operativo',
    'Estado Físico', 'Observaciones', 'Auditor', 'Fecha de Registro',
    'Última Modificación'
  ];

  for (int i = 0; i < headers.length; i++) {
    final cell = sheet.getRangeByIndex(1, i + 1);
    cell.setText(headers[i]);
    cell.cellStyle.bold = true;
    cell.cellStyle.backColor = '#005492';
    cell.cellStyle.fontColor = '#FFFFFF';
    sheet.autoFitColumn(i + 1);
  }

  for (int r = 0; r < datos.length; r++) {
    final data = datos[r];
    final row = r + 2;

    sheet.getRangeByIndex(row, 1).setText(data['codigo']);
    sheet.getRangeByIndex(row, 2).setText(data['descripcion']);
    sheet.getRangeByIndex(row, 3).setText(data['equipoPadre']);
    sheet.getRangeByIndex(row, 4).setText(data['familia']);
    sheet.getRangeByIndex(row, 5).setText(data['areaProceso']);
    sheet.getRangeByIndex(row, 6).setText(data['ubicacionTecnica']);
    sheet.getRangeByIndex(row, 7).setText(data['modelo']);
    sheet.getRangeByIndex(row, 8).setText(data['numeroSerie']);
    sheet.getRangeByIndex(row, 9).setText(data['variableMedida']);
    sheet.getRangeByIndex(row, 10).setText(data['senalEntradaSalida']);
    sheet.getRangeByIndex(row, 11).setText(data['rangoLrv']);
    sheet.getRangeByIndex(row, 12).setText(data['rangoUrv']);
    sheet.getRangeByIndex(row, 13).setText(data['unidadIngenieria']);
    sheet.getRangeByIndex(row, 14).setText(data['estadoOperativoObservado']);
    sheet.getRangeByIndex(row, 15).setText(data['estadoFisicoObservado']);
    sheet.getRangeByIndex(row, 16).setText(data['observacion']);
    sheet.getRangeByIndex(row, 17).setText(data['email_creador']);

    if (data['sincronizadoEn'] != null) {
      final date = DateTime.parse(data['sincronizadoEn']);
      sheet.getRangeByIndex(row, 18).setText('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}');
    } else {
      sheet.getRangeByIndex(row, 18).setText('N/D');
    }

    if (data['ultimaModificacion'] != null) {
      final dateMod = DateTime.parse(data['ultimaModificacion']);
      sheet.getRangeByIndex(row, 19).setText('${dateMod.day.toString().padLeft(2, '0')}/${dateMod.month.toString().padLeft(2, '0')}/${dateMod.year} ${dateMod.hour.toString().padLeft(2, '0')}:${dateMod.minute.toString().padLeft(2, '0')}');
    } else {
      sheet.getRangeByIndex(row, 19).setText('Sin modificaciones');
    }
  }

  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();
  return bytes;
}