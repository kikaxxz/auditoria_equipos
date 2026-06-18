import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'equipos_area_page.dart';
import 'configuracion_provider.dart';
import 'admin_usuarios_page.dart';
import 'detalle_equipo_page.dart';
import 'manual_page.dart';
import 'Configuracion.dart';
import 'equipos_aprobar_page.dart';
import 'mis_solicitudes_page.dart';

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

  bool _isLoadingTable = true;
  final List<Map<String, dynamic>> _filteredDashboardData = [];
  String _searchTable = '';
  String _filtroMacroArea = '';
  String _sortOrder = 'desc';

  Map<String, dynamic> _conteosAreasGlobales = {};
  bool _cargandoConteos = true;

  DocumentSnapshot? _ultimoDocumento;
  bool _hayMasDatos = true;
  bool _cargandoMas = false;
  
  StreamSubscription<DocumentSnapshot>? _conteosSubscription;

  @override
  void initState() {
    super.initState();
    _cargarConteosAreas();

    if (widget.rol == 'admin' || widget.rol == 'supervisor') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarEstadisticasGlobales();
        _cargarDatosPaginados(recargar: true);
      });
    }
  }

  @override
  void dispose() {
    _conteosSubscription?.cancel();
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
          _conteosAreasGlobales = doc.data() ?? {};
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

    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('equipos').count().get();

      if (mounted) {
        setState(() {
          _totalEquipos = querySnapshot.count ?? 0;
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

  Widget _buildSearchList(ConfiguracionProvider config) {
    final areasFiltradas = config.areasProceso.where((area) {
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

  Widget _buildDirectorioView(ConfiguracionProvider config) {
    final bool isSearching = _terminoBusquedaDirectorio.isNotEmpty;
    
    if (config.cargando && config.arbolJerarquico.children.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1F5C3D)),
            SizedBox(height: 16),
            Text('Sincronizando directorios...', style: TextStyle(color: Color(0xFF5F6368))),
          ],
        ),
      );
    }

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
              ? _buildSearchList(config)
              : ListView(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: widget.rol == 'admin' ? 16.0 : 80.0),
                  children: config.arbolJerarquico.children.values.map((child) => _buildTreeNodeWidget(child)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildDashboardInteractivaView(ConfiguracionProvider config) {
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCardsRow(),
                  const SizedBox(height: 16),
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
                  _buildFiltersGrid(config),
                ],
              ),
            ),
          ),
        ];
      },
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            const Divider(height: 1, color: Color(0xFFD9D9D9)),
            Expanded(
              child: _isLoadingTable
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D)))
                  : _buildOptimizedDataTable(),
            ),
          ],
        ),
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

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
            const Text(
              'Total de Equipos en la Planta',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5F6368)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _totalEquipos.toString(),
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F5C3D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersGrid(ConfiguracionProvider config) {
    final macroAreasDisponibles = config.areasProceso
        .map((area) => area.split(' / ').first.trim())
        .toSet()
        .toList();
    macroAreasDisponibles.sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 700;
        final double elementWidth = isSmallScreen ? constraints.maxWidth : (constraints.maxWidth - 32) / 3;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: isSmallScreen ? constraints.maxWidth : elementWidth,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar Tag / Código',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF5F6368), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1F5C3D))),
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
                  prefixIcon: const Icon(Icons.category, color: Color(0xFF5F6368), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                initialValue: _filtroMacroArea.isEmpty ? null : _filtroMacroArea,
                hint: const Text('Todas las Áreas', overflow: TextOverflow.ellipsis),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todas las Áreas')),
                  ...macroAreasDisponibles.map((m) => DropdownMenuItem(value: m, child: Text(m))),
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
                  prefixIcon: const Icon(Icons.sort, color: Color(0xFF5F6368), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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

  Widget _buildOptimizedDataTable() {
    if (_filteredDashboardData.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron equipos.',
          style: TextStyle(color: Color(0xFF5F6368), fontSize: 15),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                _cargarDatosPaginados();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredDashboardData.length + (_cargandoMas ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _filteredDashboardData.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F5C3D))),
                  );
                }

                final data = _filteredDashboardData[index];
                final macroArea = (data['areaProceso'] as String?)?.split(' / ').first ?? 'N/A';

                String ubicacionCompleta = data['ubicacionTecnica'] ?? '';
                String ubicacionEspecifica = 'N/A';
                if (ubicacionCompleta.isNotEmpty) {
                  final partes = ubicacionCompleta.split('/').where((s) => s.trim().isNotEmpty).toList();
                  if (partes.length >= 2) {
                    ubicacionEspecifica = partes[partes.length - 2].trim();
                  } else if (partes.isNotEmpty) {
                    ubicacionEspecifica = partes.last.trim();
                  }
                }

                String fabricante = data['fabricante']?.toString().trim() ?? '';
                String modelo = data['modelo']?.toString().trim() ?? '';
                String fabricanteModelo = 'N/A';
                if (fabricante.isNotEmpty && modelo.isNotEmpty) {
                  fabricanteModelo = '$fabricante - $modelo';
                } else if (fabricante.isNotEmpty) {
                  fabricanteModelo = fabricante;
                } else if (modelo.isNotEmpty) {
                  fabricanteModelo = modelo;
                }

                String nombrePrincipal = data['nombre']?.toString().trim() ?? '';
                if (nombrePrincipal.isEmpty) {
                  nombrePrincipal = data['descripcion']?.toString().trim() ?? 'Sin nombre';
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFD9D9D9), width: 0.8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F5C3D).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                data['codigo'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F5C3D), fontSize: 12),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye, color: Color(0xFF1F5C3D), size: 24),
                              splashRadius: 24,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          nombrePrincipal,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1A1C1E)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.business, size: 16, color: Color(0xFF5F6368)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(macroArea, style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368)))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Color(0xFF5F6368)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(ubicacionEspecifica, style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368)))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.precision_manufacturing, size: 16, color: Color(0xFF5F6368)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(fabricanteModelo, style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368)))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        final double minTableWidth = 1000;
        final double tableWidth = constraints.maxWidth > minTableWidth ? constraints.maxWidth : minTableWidth;
        final double availableWidth = tableWidth - 32;

        final double col1 = availableWidth * 0.12;
        final double col2 = availableWidth * 0.28;
        final double col3 = availableWidth * 0.15;
        final double col4 = availableWidth * 0.20;
        final double col5 = availableWidth * 0.17;
        final double col6 = availableWidth * 0.08;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      SizedBox(width: col1, child: const Text('Tag (Código)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
                      SizedBox(width: col2, child: const Text('Nombre en Sistema', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
                      SizedBox(width: col3, child: const Text('Macro Área', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
                      SizedBox(width: col4, child: const Text('Fabricante / Modelo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
                      SizedBox(width: col5, child: const Text('Ubicación Específica', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
                      SizedBox(width: col6, child: const Text('Acción', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368)))),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFD9D9D9)),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                        _cargarDatosPaginados();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      itemCount: _filteredDashboardData.length + (_cargandoMas ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredDashboardData.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F5C3D))),
                          );
                        }
                        
                        final data = _filteredDashboardData[index];
                        final macroArea = (data['areaProceso'] as String?)?.split(' / ').first ?? 'N/A';
                        
                        String ubicacionCompleta = data['ubicacionTecnica'] ?? '';
                        String ubicacionEspecifica = 'N/A';
                        if (ubicacionCompleta.isNotEmpty) {
                          final partes = ubicacionCompleta.split('/').where((s) => s.trim().isNotEmpty).toList();
                          if (partes.length >= 2) {
                            ubicacionEspecifica = partes[partes.length - 2].trim();
                          } else if (partes.isNotEmpty) {
                            ubicacionEspecifica = partes.last.trim();
                          }
                        }

                        String fabricante = data['fabricante']?.toString().trim() ?? '';
                        String modelo = data['modelo']?.toString().trim() ?? '';
                        String fabricanteModelo = 'N/A';
                        if (fabricante.isNotEmpty && modelo.isNotEmpty) {
                          fabricanteModelo = '$fabricante - $modelo';
                        } else if (fabricante.isNotEmpty) {
                          fabricanteModelo = fabricante;
                        } else if (modelo.isNotEmpty) {
                          fabricanteModelo = modelo;
                        }

                        String nombrePrincipal = data['nombre']?.toString().trim() ?? '';
                        if (nombrePrincipal.isEmpty) {
                          nombrePrincipal = data['descripcion']?.toString().trim() ?? 'Sin nombre';
                        }

                        return Container(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFD9D9D9), width: 0.5)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(width: col1, child: Text(data['codigo'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1C1E)))),
                              SizedBox(width: col2, child: Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(nombrePrincipal, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1A1C1E))))),
                              SizedBox(width: col3, child: Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(macroArea, style: const TextStyle(color: Color(0xFF5F6368))))),
                              SizedBox(width: col4, child: Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(fabricanteModelo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF5F6368))))),
                              SizedBox(width: col5, child: Padding(padding: const EdgeInsets.only(right: 8.0), child: Text(ubicacionEspecifica, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF5F6368))))),
                              SizedBox(
                                width: col6, 
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    icon: const Icon(Icons.remove_red_eye, color: Color(0xFF1F5C3D), size: 22),
                                    splashRadius: 24,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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
                                )
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = const Color(0xFF1A1C1E),
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
      leading: Icon(icon, color: color == const Color(0xFF1A1C1E) ? const Color(0xFF1F5C3D) : color),
      title: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  Widget _buildDrawer(bool esAprobador) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Usuario del Sistema';
    final userEmail = user?.email ?? 'correo@ejemplo.com';
    final String rolCapitalizado = widget.rol.isNotEmpty 
        ? '${widget.rol[0].toUpperCase()}${widget.rol.substring(1)}'
        : 'Desconocido';

    return Drawer(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: const Color(0xFF1F5C3D),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  child: user?.photoURL == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 28, color: Color(0xFF1F5C3D), fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Rol: $rolCapitalizado',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              children: [
                if (esAprobador) ...[
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('ediciones_pendientes').snapshots(),
                    builder: (context, snapshot) {
                      int pendientesCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildDrawerItem(
                        icon: Icons.fact_check,
                        text: 'Equipos por Aprobar',
                        trailing: pendientesCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC362E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$pendientesCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                )
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EquiposAprobarPage(rol: widget.rol)));
                        },
                      );
                    },
                  ),
                  const Divider(color: Color(0xFFD9D9D9), indent: 16, endIndent: 16),
                ],
                if (widget.rol == 'tecnico') ...[
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('ediciones_pendientes')
                        .where('solicitado_por', isEqualTo: userEmail)
                        .where('estado', isEqualTo: 'pendiente')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int pendientesCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildDrawerItem(
                        icon: Icons.assignment,
                        text: 'Mis Solicitudes',
                        trailing: pendientesCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F5C3D),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$pendientesCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                )
                              )
                            : null,
                        onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MisSolicitudesPage(rol: widget.rol)));
                      },
                      );
                    },
                  ),
                  const Divider(color: Color(0xFFD9D9D9), indent: 16, endIndent: 16),
                ],
                _buildDrawerItem(
                  icon: Icons.picture_as_pdf,
                  text: 'Manual de Mantenimiento',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManualPage()));
                  },
                ),
                if (widget.rol == 'admin')
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings,
                    text: 'Control de Accesos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUsuariosPage()));
                    },
                  ),
                if (esAprobador)
                  _buildDrawerItem(
                    icon: Icons.settings,
                    text: 'Configuración del Sistema',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PanelConfiguracionPage()));
                    },
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFD9D9D9), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: _buildDrawerItem(
              icon: Icons.logout,
              text: 'Cerrar Sesión',
              color: const Color(0xFFDC362E),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esAprobador = widget.rol == 'admin' || widget.rol == 'supervisor';
    final config = context.watch<ConfiguracionProvider>();

    String getAppBarTitle() {
      if (!esAprobador) return 'Directorio de Planta';
      if (_currentIndex == 0) return 'Directorio de Planta';
      return 'Panel Interactivo';
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
                  margin: const EdgeInsets.only(right: 16),
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
        ],
      ),
      drawer: _buildDrawer(esAprobador),
      body: esAprobador
          ? IndexedStack(
              index: _currentIndex,
              children: [
                _buildDirectorioView(config),
                _buildDashboardInteractivaView(config),
              ],
            )
          : _buildDirectorioView(config),
      bottomNavigationBar: esAprobador
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
              ],
            )
          : null,
    );
  }
}