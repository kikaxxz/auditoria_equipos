import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'configuracion_provider.dart';
import 'dashboard_drawer.dart';
import 'directorio_view.dart';
import 'dashboard_interactiva_view.dart';

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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF57F17),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sync_problem_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('${box.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: DashboardDrawer(rol: widget.rol, esAprobador: esAprobador),
      body: esAprobador
          ? IndexedStack(
              index: _currentIndex,
              children: [
                DirectorioView(
                  config: config,
                  rol: widget.rol,
                  terminoBusqueda: _terminoBusquedaDirectorio,
                  onSearchChanged: (valor) {
                    setState(() {
                      _terminoBusquedaDirectorio = valor;
                    });
                  },
                  conteosAreasGlobales: _conteosAreasGlobales,
                  cargandoConteos: _cargandoConteos,
                ),
                DashboardInteractivaView(
                  config: config,
                  rol: widget.rol,
                  isLoadingTable: _isLoadingTable,
                  filteredDashboardData: _filteredDashboardData,
                  cargandoStats: _cargandoStats,
                  totalEquipos: _totalEquipos,
                  cargandoMas: _cargandoMas,
                  searchTable: _searchTable,
                  filtroMacroArea: _filtroMacroArea,
                  sortOrder: _sortOrder,
                  onSearchChanged: (val) {
                    _searchTable = val;
                    _cargarDatosPaginados(recargar: true);
                  },
                  onFilterChanged: (val) {
                    _filtroMacroArea = val;
                    _cargarDatosPaginados(recargar: true);
                  },
                  onSortChanged: (val) {
                    _sortOrder = val;
                    _cargarDatosPaginados(recargar: true);
                  },
                  onLoadMore: () => _cargarDatosPaginados(),
                ),
              ],
            )
          : DirectorioView(
              config: config,
              rol: widget.rol,
              terminoBusqueda: _terminoBusquedaDirectorio,
              onSearchChanged: (valor) {
                setState(() {
                  _terminoBusquedaDirectorio = valor;
                });
              },
              conteosAreasGlobales: _conteosAreasGlobales,
              cargandoConteos: _cargandoConteos,
            ),
      bottomNavigationBar: esAprobador
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1C1E).withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFF1F5C3D).withValues(alpha: 0.15),
                elevation: 0,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.account_tree_outlined, color: Color(0xFF5F6368)),
                    selectedIcon: Icon(Icons.account_tree_rounded, color: Color(0xFF1F5C3D)),
                    label: 'Directorio',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.analytics_outlined, color: Color(0xFF5F6368)),
                    selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF1F5C3D)),
                    label: 'Dashboard',
                  ),
                ],
              ),
            )
          : null,
    );
  }
}