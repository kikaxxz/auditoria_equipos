import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'equipos_area_page.dart';
import 'constantes.dart';
import 'admin_usuarios_page.dart';
import 'equipos_list_provider.dart';
import 'detalle_equipo_page.dart';
import 'comparador_excel_page.dart';
import 'manual_page.dart';

class DashboardPage extends StatefulWidget {
  final String rol;

  const DashboardPage({super.key, required this.rol});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  String _terminoBusquedaDirectorio = '';
  
  bool _cargandoStats = true;
  int _totalEquipos = 0;
  Map<String, int> _statsOperativos = {};
  Map<String, int> _statsCriticos = {};

  bool _isLoadingTable = true;
  final List<Map<String, dynamic>> _filteredDashboardData = [];
  String _searchTable = '';
  String _filtroEstado = '';
  String _filtroMacroArea = '';
  String _sortOrder = 'desc';

  Map<String, dynamic> _conteosAreasGlobales = {};
  bool _cargandoConteos = true;
  late List<String> _macroAreasDisponibles;

  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _ultimoDocumento;
  bool _hayMasDatos = true;
  bool _cargandoMas = false;
  
  StreamSubscription<DocumentSnapshot>? _conteosSubscription;

  @override
  void initState() {
    super.initState();
    _macroAreasDisponibles = areasProceso
        .map((area) => area.split(' / ').first.trim())
        .toSet()
        .toList();
    _macroAreasDisponibles.sort();

    _cargarConteosAreas();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _cargarDatosPaginados();
      }
    });

    if (widget.rol == 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarEstadisticasGlobales();
        _cargarDatosPaginados(recargar: true);
      });
    }
  }

  @override
  void dispose() {
    _conteosSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _cargarConteosAreas() {
    _conteosSubscription = FirebaseFirestore.instance
        .collection('metricas')
        .doc('conteos_areas')
        .snapshots()
        .listen((doc) {
      if (mounted && doc.exists) {
        setState(() {
          _conteosAreasGlobales = doc.data() as Map<String, dynamic>? ?? {};
          _cargandoConteos = false;
        });
      } else if (mounted) {
         setState(() => _cargandoConteos = false);
      }
    }, onError: (error) {
      if (mounted) {
        setState(() => _cargandoConteos = false);
      }
    });
  }

  Future<void> _cargarEstadisticasGlobales() async {
    setState(() => _cargandoStats = true);
    final provider = Provider.of<EquiposListProvider>(context, listen: false);

    try {
      final futureTotal = FirebaseFirestore.instance.collection('equipos').count().get();
      final futureOperativos = provider.obtenerEstadisticasOperativas();
      final futureCriticos = provider.obtenerEstadosCriticos();

      final resultados = await Future.wait([futureTotal, futureOperativos, futureCriticos]);

      if (mounted) {
        setState(() {
          _totalEquipos = (resultados[0] as AggregateQuerySnapshot).count ?? 0;
          _statsOperativos = resultados[1] as Map<String, int>;
          _statsCriticos = resultados[2] as Map<String, int>;
          _cargandoStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoStats = false);
    }
  }

  Future<void> _cargarDatosPaginados({bool recargar = false}) async {
    if (recargar) {
      setState(() {
        _filteredDashboardData.clear();
        _ultimoDocumento = null;
        _hayMasDatos = true;
        _isLoadingTable = true;
      });
    }

    if (!_hayMasDatos || _cargandoMas) return;

    setState(() {
      if (!recargar) _cargandoMas = true;
    });

    try {
      Query query = FirebaseFirestore.instance.collection('equipos');

      if (_filtroEstado.isNotEmpty) {
        query = query.where('estadoOperativoObservado', isEqualTo: _filtroEstado);
      }

      if (_searchTable.isNotEmpty) {
        final queryText = _searchTable.toLowerCase();
        query = query.where('codigo_minuscula', isGreaterThanOrEqualTo: queryText)
                     .where('codigo_minuscula', isLessThan: '$queryText\uf8ff')
                     .orderBy('codigo_minuscula');
      } else if (_filtroMacroArea.isNotEmpty) {
        query = query.where('areaProceso', isGreaterThanOrEqualTo: _filtroMacroArea)
                     .where('areaProceso', isLessThan: '$_filtroMacroArea\uf8ff')
                     .orderBy('areaProceso')
                     .orderBy('sincronizadoEn', descending: _sortOrder == 'desc');
      } else {
        query = query.orderBy('sincronizadoEn', descending: _sortOrder == 'desc');
      }

      query = query.limit(50);

      if (_ultimoDocumento != null) {
        query = query.startAfterDocument(_ultimoDocumento!);
      }

      final snap = await query.get();

      if (snap.docs.length < 50) {
        _hayMasDatos = false;
      }

      if (snap.docs.isNotEmpty) {
        _ultimoDocumento = snap.docs.last;
        
        final nuevosDatos = snap.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id_documento'] = doc.id;
          return data;
        }).toList();

        setState(() {
          _filteredDashboardData.addAll(nuevosDatos);
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTable = false;
          _cargandoMas = false;
        });
      }
    }
  }

  Widget _buildConteoWidget(String areaCompleta) {
    if (_cargandoConteos) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F5C3D)),
        ),
      );
    }

    String safeKey = areaCompleta.replaceAll('/', '-').replaceAll('.', '-');
    final count = _conteosAreasGlobales[safeKey] ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: count > 0 ? const Color(0xFF1F5C3D).withValues(alpha: 0.1) : const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 13,
          color: count > 0 ? const Color(0xFF1F5C3D) : const Color(0xFF5F6368),
        ),
      ),
    );
  }

  Widget _buildTreeNodeWidget(TreeNode node) {
    if (node.isLeaf) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD9D9D9), width: 0.8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1F5C3D).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.device_hub, color: Color(0xFF1F5C3D), size: 24),
          ),
          title: Text(
            node.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1C1E)),
          ),
          trailing: _buildConteoWidget(node.fullPath),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EquiposAreaPage(area: node.fullPath, rol: widget.rol),
              ),
            );
          },
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFD9D9D9), width: 0.8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: const Icon(Icons.folder_open, color: Color(0xFF1F5C3D)),
          title: Text(
            node.name,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1C1E), fontSize: 15),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConteoWidget(node.fullPath),
              const SizedBox(width: 8),
              const Icon(Icons.expand_more, color: Color(0xFFD9D9D9)),
            ],
          ),
          children: node.children.values.map((child) {
            return Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _buildTreeNodeWidget(child),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchList() {
    final areasFiltradas = areasProceso.where((area) {
      return area.toLowerCase().contains(_terminoBusquedaDirectorio.toLowerCase());
    }).toList();

    if (areasFiltradas.isEmpty) {
      return const Center(
        child: Text('No se encontraron áreas.', style: TextStyle(color: Color(0xFF5F6368), fontSize: 16)),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: widget.rol == 'admin' ? 16.0 : 80.0),
      itemCount: areasFiltradas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final areaCompleta = areasFiltradas[index];
        final partes = areaCompleta.split(' / ');
        final String mainTitle = partes.last;
        final String subTitle = partes.length > 1 ? partes.sublist(0, partes.length - 1).join(' / ') : '';

        return Card(
          elevation: 1,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFD9D9D9), width: 0.8),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EquiposAreaPage(area: areaCompleta, rol: widget.rol),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F5C3D).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search, color: Color(0xFF1F5C3D), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subTitle,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5F6368),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mainTitle,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1C1E)),
                        ),
                      ],
                    ),
                  ),
                  _buildConteoWidget(areaCompleta),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Color(0xFFD9D9D9)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDirectorioView() {
    final bool isSearching = _terminoBusquedaDirectorio.isNotEmpty;

    return Column(
      children: [
        Container(
          color: const Color(0xFFF5F6F7),
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Buscar en la estructura jerárquica...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1F5C3D)),
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onChanged: (valor) {
              setState(() {
                _terminoBusquedaDirectorio = valor;
              });
            },
          ),
        ),
        Expanded(
          child: isSearching
              ? _buildSearchList()
              : ListView(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: widget.rol == 'admin' ? 16.0 : 80.0),
                  children: arbolJerarquico.children.values.map((child) => _buildTreeNodeWidget(child)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildDashboardInteractivaView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCardsRow(),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD9D9D9)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lista Detallada de Equipos',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Utilice los filtros para realizar búsquedas específicas en la base de datos.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
                      ),
                      const SizedBox(height: 16),
                      _buildFiltersGrid(),
                    ],
                  ),
                ),
                
                const Divider(height: 1, color: Color(0xFFD9D9D9)),
                
                _isLoadingTable
                    ? const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D))),
                      )
                    : _buildDataTable(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardsRow() {
    if (_cargandoStats) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D))),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: isSmallScreen ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
              child: _buildSingleStatCard('Total General', _totalEquipos.toString(), true),
            ),
            SizedBox(
              width: isSmallScreen ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
              child: _buildSingleStatCard('Operativos', _statsOperativos['Operativa']?.toString() ?? '0', false),
            ),
            SizedBox(
              width: isSmallScreen ? (constraints.maxWidth - 16) / 2 : (constraints.maxWidth - 48) / 4,
              child: _buildSingleStatCard('En Falla', _statsCriticos['Malo']?.toString() ?? '0', false),
            ),
            SizedBox(
              width: isSmallScreen ? (constraints.maxWidth - 16) / 2 : (constraints.maxWidth - 48) / 4,
              child: _buildSingleStatCard('Reemplazos', _statsCriticos['Requiere reemplazo']?.toString() ?? '0', false),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSingleStatCard(String title, String value, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9D9D9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5F6368)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isPrimary ? 36 : 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F5C3D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final double elementWidth = isSmallScreen ? constraints.maxWidth : (constraints.maxWidth - 48) / 4;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: isSmallScreen ? constraints.maxWidth : elementWidth,
              child: TextField(
                decoration: InputDecoration(
                  hintText: '🔍 Buscar Tag / Código',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D9D9))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D9D9))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F5C3D))),
                ),
                onSubmitted: (val) {
                  _searchTable = val;
                  _cargarDatosPaginados(recargar: true);
                },
              ),
            ),
            SizedBox(
              width: isSmallScreen ? constraints.maxWidth : elementWidth,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D9D9))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D9D9))),
                ),
                initialValue: _filtroMacroArea.isEmpty ? null : _filtroMacroArea,
                hint: const Text('Todas las Áreas', overflow: TextOverflow.ellipsis),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todas las Áreas')),
                  ..._macroAreasDisponibles.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                ],
                onChanged: (val) {
                  _filtroMacroArea = val ?? '';
                  _cargarDatosPaginados(recargar: true);
                },
              ),
            ),
            SizedBox(
              width: isSmallScreen ? constraints.maxWidth : elementWidth,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D9D9))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D9D9))),
                ),
                initialValue: _filtroEstado.isEmpty ? null : _filtroEstado,
                hint: const Text('Todos los Estados'),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: '', child: Text('Todos los Estados')),
                  DropdownMenuItem(value: 'Operativa', child: Text('Operativa')),
                  DropdownMenuItem(value: 'Detenida', child: Text('Detenida')),
                  DropdownMenuItem(value: 'En mantenimiento', child: Text('En mantenimiento')),
                  DropdownMenuItem(value: 'Fuera de servicio', child: Text('Fuera de servicio')),
                ],
                onChanged: (val) {
                  _filtroEstado = val ?? '';
                  _cargarDatosPaginados(recargar: true);
                },
              ),
            ),
            SizedBox(
              width: isSmallScreen ? constraints.maxWidth : elementWidth,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D9D9))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD9D9D9))),
                ),
                initialValue: _sortOrder,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'desc', child: Text('Más recientes primero')),
                  DropdownMenuItem(value: 'asc', child: Text('Más antiguos primero')),
                ],
                onChanged: (val) {
                  _sortOrder = val ?? 'desc';
                  _cargarDatosPaginados(recargar: true);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataTable() {
    if (_filteredDashboardData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(
          child: Text(
            'No se encontraron equipos. Comience a buscar o ajuste los filtros.',
            style: TextStyle(color: Color(0xFF5F6368), fontSize: 15),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F6F7)),
              dataRowMaxHeight: 65,
              columnSpacing: 24,
              horizontalMargin: 20,
              columns: const [
                DataColumn(label: Text('Tag (Código)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
                DataColumn(label: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
                DataColumn(label: Text('Macro Área', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
                DataColumn(label: Text('Estado Operativo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
                DataColumn(label: Text('Condición', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
                DataColumn(label: Text('Acción', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
              ],
              rows: [
                ..._filteredDashboardData.map((data) {
                  final macroArea = (data['areaProceso'] as String?)?.split(' / ').first ?? 'N/A';
                  final estadoOp = data['estadoOperativoObservado']?.toString() ?? 'N/A';
                  final condicionFisica = data['estadoFisicoObservado']?.toString() ?? 'N/A';

                  return DataRow(
                    cells: [
                      DataCell(Text(data['codigo'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(data['descripcion'] ?? 'N/A', maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(Text(macroArea)),
                      DataCell(_buildChipPequeno(estadoOp, true)),
                      DataCell(_buildChipPequeno(condicionFisica, false)),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye, color: Color(0xFF1F5C3D), size: 20),
                          tooltip: 'Ver Detalles',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetalleEquipoPage(
                                  documentId: data['id_documento'],
                                  datos: data,
                                  rolUsuario: widget.rol,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }),
                if (_cargandoMas)
                  const DataRow(cells: [
                    DataCell(SizedBox.shrink()),
                    DataCell(SizedBox.shrink()),
                    DataCell(CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F5C3D))),
                    DataCell(SizedBox.shrink()),
                    DataCell(SizedBox.shrink()),
                    DataCell(SizedBox.shrink()),
                  ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChipPequeno(String estado, bool esOperativo) {
    Color colorFondo = const Color(0xFFF5F6F7);
    Color colorTexto = const Color(0xFF5F6368);
    String texto = estado.toUpperCase().trim();

    if (texto.contains('OPERATIVA') || texto.contains('BUENO')) {
      colorFondo = const Color(0xFFE6F4EA);
      colorTexto = const Color(0xFF1F5C3D);
    } else if (texto.contains('MANTENIMIENTO') || texto.contains('REGULAR')) {
      colorFondo = const Color(0xFFFFF8E1);
      colorTexto = const Color(0xFFF57F17);
    } else if (texto.contains('DETENIDA') || texto.contains('MALO') || texto.contains('REEMPLAZO')) {
      colorFondo = const Color(0xFFFCE8E6);
      colorTexto = const Color(0xFFDC362E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: colorFondo, borderRadius: BorderRadius.circular(6)),
      child: Text(
        texto,
        style: TextStyle(color: colorTexto, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.rol == 'admin';

    String getAppBarTitle() {
      if (!isAdmin) return 'Directorio de Planta';
      if (_currentIndex == 0) return 'Directorio de Planta';
      if (_currentIndex == 1) return 'Panel Interactivo';
      return 'Registros';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: Text(
          getAppBarTitle(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1F5C3D),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        actions: [
          ValueListenableBuilder(
            valueListenable: Hive.box('equipos_pendientes').listenable(),
            builder: (context, Box box, _) {
              if (box.isEmpty) return const SizedBox.shrink();
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF57F17), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sync_problem, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('${box.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            onSelected: (String result) async {
              switch (result) {
                case 'manual':
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ManualPage()));
                  break;
                case 'admin':
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUsuariosPage()));
                  break;
                case 'logout':
                  await FirebaseAuth.instance.signOut();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'manual',
                child: Row(children: [Icon(Icons.picture_as_pdf, color: Color(0xFF1F5C3D)), SizedBox(width: 12), Text('Manual de Mantenimiento', style: TextStyle(color: Color(0xFF1A1C1E)))]),
              ),
              if (isAdmin)
                const PopupMenuItem<String>(
                  value: 'admin',
                  child: Row(children: [Icon(Icons.admin_panel_settings, color: Color(0xFF1F5C3D)), SizedBox(width: 12), Text('Control de Accesos', style: TextStyle(color: Color(0xFF1A1C1E)))]),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(children: [Icon(Icons.logout, color: Color(0xFFDC362E)), SizedBox(width: 12), Text('Cerrar Sesión', style: TextStyle(color: Color(0xFFDC362E)))]),
              ),
            ],
          ),
        ],
      ),
      body: isAdmin
          ? IndexedStack(
              index: _currentIndex,
              children: [
                _buildDirectorioView(),
                _buildDashboardInteractivaView(),
                ComparadorExcelPage(), 
              ],
            )
          : _buildDirectorioView(),
      bottomNavigationBar: isAdmin
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF1F5C3D),
              unselectedItemColor: const Color(0xFF5F6368),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.account_tree), label: 'Directorio'),
                BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.compare_arrows), label: 'Registros'),
              ],
            )
          : null,
    );
  }
}