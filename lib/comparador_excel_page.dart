import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'excel_parser_service.dart';

class ComparadorExcelPage extends StatefulWidget {
  const ComparadorExcelPage({super.key});

  @override
  State<ComparadorExcelPage> createState() => _ComparadorExcelPageState();
}

class _ComparadorExcelPageState extends State<ComparadorExcelPage> {
  bool _procesando = false;
  bool _archivoCargado = false;

  int _totalExcel = 0;

  List<Map<String, dynamic>> _datosExcel = [];
  List<Map<String, dynamic>> _datosVisibles = [];

  String _filtroGeneral = '';
  String _filtroUbicacion = '';
  String _filtroFabricante = '';

  List<String> _opcionesUbicacion = [];
  List<String> _opcionesFabricante = [];

  Future<void> _cargarArchivo() async {
    setState(() => _procesando = true);
    
    final parser = ExcelParserService();
    
    try {
      final mapaExcel = await parser.cargarYProcesarExcel();

      if (mapaExcel != null) {
        _procesarDatosExcel(mapaExcel);
      } else {
        setState(() {
          _procesando = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selección de archivo cancelada')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _procesando = false;
      });
      
      if (mounted) {
        if (e.toString().contains('LIMITE_5MB')) {
          _mostrarAlertaTamanio();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al procesar el archivo Excel')),
          );
        }
      }
    }
  }

  void _mostrarAlertaTamanio() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC362E), size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Archivo demasiado grande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ]
        ),
        content: const Text(
          'El archivo seleccionado supera el límite de 5 MB permitido para mantener la estabilidad del dispositivo.\n\n'
          'Por favor, reduce el tamaño del documento eliminando hojas, imágenes o macros, e inténtalo de nuevo.',
          style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: Color(0xFF1F5C3D), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _procesarDatosExcel(Map<String, Map<String, dynamic>> mapaExcel) {
    List<Map<String, dynamic>> nuevosDatos = [];
    Set<String> ubicacionesTemp = {};
    Set<String> fabricantesTemp = {};

    _totalExcel = mapaExcel.length;

    mapaExcel.forEach((tag, datos) {
      String ubi = datos['ubicacion'].toString().trim();
      String fab = datos['marca'].toString().trim();

      if (ubi.isNotEmpty) ubicacionesTemp.add(ubi);
      if (fab.isNotEmpty) fabricantesTemp.add(fab);

      nuevosDatos.add({
        'tag': tag,
        'descripcion': datos['descripcion'].toString().trim(),
        'ubicacion': ubi,
        'fabricante': fab,
        'modelo': datos['modelo'].toString().trim(),
        'numeroSerie': datos['numeroSerie'].toString().trim(),
      });
    });

    _opcionesUbicacion = ubicacionesTemp.toList()..sort();
    _opcionesFabricante = fabricantesTemp.toList()..sort();

    setState(() {
      _datosExcel = nuevosDatos;
      _aplicarFiltros();
      _procesando = false;
      _archivoCargado = true;
    });
  }

  void _aplicarFiltros() {
    bool cumpleFiltro(Map<String, dynamic> item) {
      bool matchUbi = _filtroUbicacion.isEmpty || item['ubicacion'] == _filtroUbicacion;
      bool matchFab = _filtroFabricante.isEmpty || item['fabricante'] == _filtroFabricante;
      bool matchGen = _filtroGeneral.isEmpty || 
                      item['tag'].toString().toLowerCase().contains(_filtroGeneral.toLowerCase()) ||
                      item['descripcion'].toString().toLowerCase().contains(_filtroGeneral.toLowerCase());
      return matchUbi && matchFab && matchGen;
    }

    setState(() {
      _datosVisibles = _datosExcel.where(cumpleFiltro).toList();
    });
  }

  String _formatearUbicacionCorta(String rutaCompleta) {
    if (rutaCompleta.isEmpty) return 'Todas las ubicaciones';
    final partes = rutaCompleta.split('/').where((p) => p.trim().isNotEmpty).toList();
    if (partes.length <= 2) return rutaCompleta;
    return '... / ${partes[partes.length - 2].trim()} / ${partes.last.trim()}';
  }

  void _abrirSelectorUbicacion() {
    String busquedaTemp = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final opcionesFiltradas = _opcionesUbicacion
                .where((u) => u.toLowerCase().contains(busquedaTemp.toLowerCase()))
                .toList();

            return AlertDialog(
              title: const Text('Seleccionar Ubicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar en la jerarquía...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (val) {
                        setStateDialog(() {
                          busquedaTemp = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: opcionesFiltradas.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return ListTile(
                              title: const Text('Todas las ubicaciones', style: TextStyle(fontWeight: FontWeight.bold)),
                              onTap: () {
                                setState(() => _filtroUbicacion = '');
                                _aplicarFiltros();
                                Navigator.pop(context);
                              },
                            );
                          }
                          final ubi = opcionesFiltradas[index - 1];
                          return ListTile(
                            title: Text(_formatearUbicacionCorta(ubi), style: const TextStyle(fontSize: 13)),
                            subtitle: Text(ubi, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              setState(() => _filtroUbicacion = ubi);
                              _aplicarFiltros();
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar', style: TextStyle(color: Color(0xFF1F5C3D)))),
              ],
            );
          }
        );
      }
    );
  }

  void _mostrarDetallesEquipo(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Icon(Icons.inventory_2, color: Color(0xFF1F5C3D), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Detalles del Equipo Maestro',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildFilaDetalle('Tag / Código', item['tag']?.toString() ?? ''),
                  const Divider(),
                  _buildFilaDetalle('Descripción', item['descripcion']?.toString() ?? ''),
                  const Divider(),
                  _buildFilaDetalle('Fabricante', item['fabricante']?.toString() ?? ''),
                  const Divider(),
                  _buildFilaDetalle('Modelo', item['modelo']?.toString() ?? ''),
                  const Divider(),
                  _buildFilaDetalle('Número de Serie', item['numeroSerie']?.toString() ?? ''),
                  const Divider(),
                  _buildFilaDetalle('Ubicación Técnica', item['ubicacion']?.toString() ?? ''),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F5C3D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cerrar Detalles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilaDetalle(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              etiqueta,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5F6368), fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              valor.isEmpty ? 'N/D' : valor,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E), fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generarResumenPDF() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final fecha = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final int limiteExportacion = 500;
    final bool excedeLimite = _datosVisibles.length > limiteExportacion;
    final datosAExportar = excedeLimite ? _datosVisibles.sublist(0, limiteExportacion) : _datosVisibles;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Listado Maestro de Equipos', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text('Fecha de generación: $fecha', style: const pw.TextStyle(fontSize: 12)),
            if (_filtroUbicacion.isNotEmpty || _filtroFabricante.isNotEmpty || _filtroGeneral.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text('Filtros aplicados:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if (_filtroGeneral.isNotEmpty) pw.Text('- Búsqueda: $_filtroGeneral'),
              if (_filtroUbicacion.isNotEmpty) pw.Text('- Ubicación: ${_formatearUbicacionCorta(_filtroUbicacion)}'),
              if (_filtroFabricante.isNotEmpty) pw.Text('- Fabricante: $_filtroFabricante'),
            ],
            pw.SizedBox(height: 20),
            pw.Text('Resumen', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: 'Total de Equipos en Documento: $_totalExcel'),
            pw.Bullet(text: 'Equipos Filtrados: ${_datosVisibles.length}'),
            if (excedeLimite) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                'Nota: Por rendimiento y legibilidad, este documento muestra un máximo de $limiteExportacion registros. Utilice los filtros en la aplicación para generar reportes más reducidos.',
                style: const pw.TextStyle(color: PdfColors.red600, fontSize: 10),
              ),
            ],
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Tag', 'Descripción', 'Fabricante', 'Ubicación'],
              data: datosAExportar.map((e) => [
                e['tag']?.toString() ?? '',
                e['descripcion']?.toString() ?? '',
                e['fabricante']?.toString() ?? '',
                _formatearUbicacionCorta(e['ubicacion']?.toString() ?? '')
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              cellHeight: 25,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
              },
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(3.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(3.5),
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Listado_Maestro_$now.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      floatingActionButton: _archivoCargado
          ? FloatingActionButton.extended(
              heroTag: 'btn_pdf',
              onPressed: _procesando ? null : _generarResumenPDF,
              backgroundColor: const Color(0xFFDC362E),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text('Exportar Resumen (PDF)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _procesando ? null : _cargarArchivo,
              icon: const Icon(Icons.upload_file),
              label: Text(_procesando ? 'Procesando Documento...' : 'Cargar Listado Maestro (Excel)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F5C3D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            if (_archivoCargado) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 600;
                  final double elementWidth = isSmallScreen ? constraints.maxWidth : (constraints.maxWidth - 32) / 3;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: isSmallScreen ? constraints.maxWidth : elementWidth,
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: '🔍 Buscar Tag o Descripción',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D9D9))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (val) {
                            _filtroGeneral = val;
                            _aplicarFiltros();
                          },
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? constraints.maxWidth : elementWidth,
                        child: InkWell(
                          onTap: _abrirSelectorUbicacion,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Ubicación Técnica',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D9D9))),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatearUbicacionCorta(_filtroUbicacion),
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: isSmallScreen ? constraints.maxWidth : elementWidth,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Fabricante',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D9D9))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          initialValue: _filtroFabricante.isEmpty ? null : _filtroFabricante,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: '', child: Text('Todos')),
                            ..._opcionesFabricante.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _filtroFabricante = val ?? '';
                              _aplicarFiltros();
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text('Total en Documento', style: TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text('$_totalExcel', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F5C3D))),
                      ],
                    ),
                    Container(width: 1, height: 40, color: const Color(0xFFD9D9D9)),
                    Column(
                      children: [
                        const Text('Resultados Filtrados', style: TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text('${_datosVisibles.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F5C3D))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD9D9D9)),
                  ),
                  child: _datosVisibles.isEmpty
                      ? const Center(child: Text('No hay registros que coincidan con los filtros.', style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: _datosVisibles.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _datosVisibles[index];
                            return ListTile(
                              onTap: () => _mostrarDetallesEquipo(item),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF1F5C3D).withValues(alpha: 0.1),
                                child: const Icon(Icons.inventory_2, color: Color(0xFF1F5C3D), size: 20),
                              ),
                              title: Text('Tag: ${item['tag']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${item['descripcion']}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                  const SizedBox(height: 6),
                                  Text('${_formatearUbicacionCorta(item['ubicacion'])} | ${item['fabricante']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            );
                          },
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}