import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web/web.dart' as web;
import 'image_cache_manager.dart';

class GeneradorPdf {
  static Future<void> generarReporteEquipo(BuildContext context, Map<String, dynamic> datos) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generando reporte PDF, por favor espere...')),
      );

      final ByteData logoData = await rootBundle.load('assets/images/isa_logo.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();

      Uint8List? bytesPlaca;
      Uint8List? bytesPlacaAdicional;
      Uint8List? bytesGeneral;

      if (datos['fotoPlacaUrl'] != null) {
        bytesPlaca = await ImageCacheManager.obtenerImagen(datos['fotoPlacaUrl']);
      }
      
      if (datos['fotoPlacaAdicionalUrl'] != null) {
        bytesPlacaAdicional = await ImageCacheManager.obtenerImagen(datos['fotoPlacaAdicionalUrl']);
      }

      if (datos['fotoGeneralUrl'] != null) {
        bytesGeneral = await ImageCacheManager.obtenerImagen(datos['fotoGeneralUrl']);
      }

      final Map<String, dynamic> payload = {
        'codigo': datos['codigo']?.toString() ?? '',
        'descripcion': datos['descripcion']?.toString() ?? '',
        'equipoPadre': datos['equipoPadre']?.toString() ?? '',
        'familia': datos['familia']?.toString() ?? '',
        'areaProceso': datos['areaProceso']?.toString() ?? '',
        'ubicacionTecnica': datos['ubicacionTecnica']?.toString() ?? '',
        'marca': datos['marca']?.toString() ?? '',
        'modelo': datos['modelo']?.toString() ?? '',
        'numeroSerie': datos['numeroSerie']?.toString() ?? '',
        'variableMedida': datos['variableMedida']?.toString() ?? '',
        'senalEntradaSalida': datos['senalEntradaSalida']?.toString() ?? '',
        'rangoLrv': datos['rangoLrv']?.toString() ?? '',
        'rangoUrv': datos['rangoUrv']?.toString() ?? '',
        'unidadIngenieria': datos['unidadIngenieria']?.toString() ?? '',
        'observacion': datos['observacion']?.toString() ?? '',
        'email_creador': datos['email_creador']?.toString() ?? '',
        'email_original': datos['email_original']?.toString() ?? '',
        'sincronizadoEn': datos['sincronizadoEn'] != null ? (datos['sincronizadoEn'] as Timestamp).toDate().toIso8601String() : null,
        'ultimaModificacion': datos['ultimaModificacion'] != null ? (datos['ultimaModificacion'] as Timestamp).toDate().toIso8601String() : null,
        'logoBytes': logoBytes,
        'bytesPlaca': bytesPlaca,
        'bytesPlacaAdicional': bytesPlacaAdicional,
        'bytesGeneral': bytesGeneral,
      };

      final Uint8List pdfBytes = await compute(_procesarPdfAislado, payload);

      final blob = web.Blob([pdfBytes.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf'));
      final url = web.URL.createObjectURL(blob);
      
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = 'Reporte_${payload['codigo']}.pdf';
        
      web.document.body?.append(anchor);
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

Future<Uint8List> _procesarPdfAislado(Map<String, dynamic> datos) async {
  final pdf = pw.Document();
  final colorPrimario = PdfColor.fromHex('#1F5C3D');
  final colorFondo = PdfColor.fromHex('#F5F6F7');
  final colorTexto = PdfColor.fromHex('#1A1C1E');
  final colorGris = PdfColor.fromHex('#5F6368');
  final colorBorde = PdfColor.fromHex('#D9D9D9');

  final logoImage = pw.MemoryImage(datos['logoBytes'] as Uint8List);
  datos['logoBytes'] = null;

  pw.MemoryImage? imgPlaca;
  pw.MemoryImage? imgPlacaAdicional;
  pw.MemoryImage? imgGeneral;

  if (datos['bytesPlaca'] != null) {
    imgPlaca = pw.MemoryImage(datos['bytesPlaca'] as Uint8List);
    datos['bytesPlaca'] = null;
  }
  
  if (datos['bytesPlacaAdicional'] != null) {
    imgPlacaAdicional = pw.MemoryImage(datos['bytesPlacaAdicional'] as Uint8List);
    datos['bytesPlacaAdicional'] = null;
  }

  if (datos['bytesGeneral'] != null) {
    imgGeneral = pw.MemoryImage(datos['bytesGeneral'] as Uint8List);
    datos['bytesGeneral'] = null;
  }

  pw.Widget construirFila(String etiqueta, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              etiqueta,
              style: pw.TextStyle(color: colorGris, fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              valor,
              style: pw.TextStyle(color: colorTexto, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget construirSeccion(String titulo, List<pw.Widget> filas) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: colorBorde, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: colorFondo,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(7),
                topRight: pw.Radius.circular(7),
              ),
              border: pw.Border(bottom: pw.BorderSide(color: colorBorde, width: 1)),
            ),
            child: pw.Text(
              titulo,
              style: pw.TextStyle(color: colorPrimario, fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              children: filas,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget construirBloqueEvidencia(String subtitulo, pw.MemoryImage imagen, bool incluirTituloPrincipal) {
    return pw.Wrap(
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (incluirTituloPrincipal)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8, bottom: 12),
                  child: pw.Text(
                    'Evidencia Visual',
                    style: pw.TextStyle(color: colorPrimario, fontSize: 14, fontWeight: pw.FontWeight.bold)
                  ),
                ),
              pw.Text(
                subtitulo,
                style: pw.TextStyle(color: colorGris, fontSize: 10, fontWeight: pw.FontWeight.bold)
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 250,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: colorBorde, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 7,
                  verticalRadius: 7,
                  child: pw.FittedBox(
                    fit: pw.BoxFit.contain,
                    child: pw.Image(imagen),
                  ),
                ),
              ),
            ]
          )
        )
      ]
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (pw.Context context) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 24),
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: colorPrimario, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(logoImage, height: 40),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Reporte de Auditoría',
                    style: pw.TextStyle(color: colorPrimario, fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Tag: ${datos['codigo']}',
                    style: pw.TextStyle(color: colorGris, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      footer: (pw.Context context) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: colorBorde, width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generado el ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                style: pw.TextStyle(color: colorGris, fontSize: 8),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(color: colorGris, fontSize: 8),
              ),
            ],
          ),
        );
      },
      build: (pw.Context context) {
        String fechaReg = 'N/D';
        if (datos['sincronizadoEn'] != null) {
          final date = DateTime.parse(datos['sincronizadoEn']);
          fechaReg = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        }

        String auditorName = datos['email_creador'] ?? 'N/D';
        String auditorEmail = datos['email_original'] ?? '';
        String auditorDisplay = auditorName;
        
        if (auditorEmail.isNotEmpty && auditorEmail != auditorName) {
          auditorDisplay = '$auditorName ($auditorEmail)';
        }

        List<pw.Widget> filasAuditoria = [];
        
        filasAuditoria.addAll([
          construirFila('Observaciones', datos['observacion']),
          construirFila('Auditor', auditorDisplay),
          construirFila('Fecha de Registro', fechaReg),
        ]);

        return [
          construirSeccion('Información Principal', [
            construirFila('Código (Tag)', datos['codigo']),
            construirFila('Nombre del Equipo', datos['descripcion']),
            construirFila('Equipo Padre', datos['equipoPadre']),
            construirFila('Familia', datos['familia']),
            construirFila('Área de Proceso', datos['areaProceso']),
            construirFila('Ubicación Específica', datos['ubicacionTecnica']),
          ]),
          construirSeccion('Datos Técnicos', [
            construirFila('Marca', datos['marca']),
            construirFila('Modelo', datos['modelo']),
            construirFila('Número de Serie', datos['numeroSerie']),
            construirFila('Variable de Medida', datos['variableMedida']),
            construirFila('Señal E/S', datos['senalEntradaSalida']),
            construirFila('Rango', '${datos['rangoLrv']} ${datos['rangoUrv']} ${datos['unidadIngenieria']}'),
          ]),
          construirSeccion('Auditoría', filasAuditoria),
          
          if (imgPlaca != null)
            construirBloqueEvidencia('Placa de Características', imgPlaca, true),
          
          if (imgPlacaAdicional != null)
            construirBloqueEvidencia('Placa de Características (Adicional)', imgPlacaAdicional, imgPlaca == null),
            
          if (imgGeneral != null)
            construirBloqueEvidencia('Estado General del Equipo', imgGeneral, imgPlaca == null && imgPlacaAdicional == null),
        ];
      },
    ),
  );

  return await pdf.save();
}