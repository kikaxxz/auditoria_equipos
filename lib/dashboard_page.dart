import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'equipos_area_page.dart';
import 'configuracion_provider.dart';
import 'admin_usuarios_page.dart';
import 'detalle_equipo_page.dart';
import 'manual_page.dart';
import 'Configuracion.dart';
import 'equipos_aprobar_page.dart';
import 'mis_solicitudes_page.dart';
import 'rag_api_service.dart';

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
  
final RagApiService _ragApiService = RagApiService();
  final TextEditingController _preguntaController = TextEditingController();
  bool _cargandoRAG = false;
  String _respuestaRAG = '';
  int? _paginaReferenciaRAG;

  void _mostrarAsistenteIA(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        String mensajeCarga = '';
        Timer? timerCarga;

        return StatefulBuilder(
          builder: (BuildContext builderContext, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(modalContext).size.height * 0.88,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBEBEB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(Icons.smart_toy_rounded, color: Color(0xFF1F5C3D), size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Asistente Técnico IA',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C1E),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFEBEBEB)),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6F7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFEBEBEB)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TextField(
                              controller: _preguntaController,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: '¿En qué te puedo ayudar hoy?',
                                hintStyle: TextStyle(color: Color(0xFF5F6368)),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F5C3D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _cargandoRAG ? null : () async {
                              try {
                                final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
                                if (connectivityResult.contains(ConnectivityResult.none)) {
                                  setModalState(() {
                                    _respuestaRAG = 'Fallo: Sin conexión de red.';
                                    _paginaReferenciaRAG = null;
                                    _cargandoRAG = false;
                                  });
                                  return;
                                }
                              } catch (e) {
                                setModalState(() {
                                  _respuestaRAG = 'Excepción Connectivity: ${e.toString()}';
                                  _paginaReferenciaRAG = null;
                                  _cargandoRAG = false;
                                });
                                return;
                              }

                              setModalState(() {
                                _cargandoRAG = true;
                                _respuestaRAG = '';
                                _paginaReferenciaRAG = null;
                                mensajeCarga = 'Analizando la consulta...';
                              });

                              int segundos = 0;
                              timerCarga = Timer.periodic(const Duration(seconds: 1), (timer) {
                                segundos++;
                                if (!mounted) {
                                  timer.cancel();
                                  return;
                                }
                                setModalState(() {
                                  if (segundos == 3) {
                                    mensajeCarga = 'Procesando información de los equipos...';
                                  } else if (segundos == 10) {
                                    mensajeCarga = 'Estableciendo conexión segura con el servidor...';
                                  }
                                });
                              });

                              _ragApiService.consultarManual(_preguntaController.text).then((resultado) {
                                timerCarga?.cancel();
                                if (!mounted) return;
                                setModalState(() {
                                  _respuestaRAG = resultado['respuesta'];
                                  _paginaReferenciaRAG = resultado['pagina'];
                                  _cargandoRAG = false;
                                });
                              }).catchError((error, stackTrace) {
                                timerCarga?.cancel();
                                if (!mounted) return;
                                setModalState(() {
                                  _respuestaRAG = 'Error Crítico:\n\n$error\n\nStackTrace:\n$stackTrace';
                                  _cargandoRAG = false;
                                });
                              });
                            },
                            child: _cargandoRAG
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Consultar IA',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                          if (_cargandoRAG)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                mensajeCarga,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (_respuestaRAG.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F5C3D).withValues(alpha: 0.03),
                                border: Border.all(color: const Color(0xFF1F5C3D).withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: MarkdownBody(
                                data: _respuestaRAG,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF1A1C1E)),
                                  h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F5C3D)),
                                  h2: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1F5C3D)),
                                  h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  listBullet: const TextStyle(color: Color(0xFF1F5C3D), fontSize: 16),
                                  codeblockPadding: const EdgeInsets.all(12),
                                  codeblockDecoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFEBEBEB)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_paginaReferenciaRAG != null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1F5C3D),
                                side: const BorderSide(color: Color(0xFF1F5C3D)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              label: Text(
                                'Ver página $_paginaReferenciaRAG en el Manual',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.pop(builderContext);
                                Navigator.push(
                                  builderContext,
                                  MaterialPageRoute(
                                    builder: (context) => ManualPage(paginaInicial: _paginaReferenciaRAG),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildConteoWidget(String areaCompleta) {
    if (_cargandoConteos) {
      return const SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F5C3D)),
      );
    }

    String safeKey = areaCompleta.replaceAll('/', '-').replaceAll('.', '-');
    final count = _conteosAreasGlobales[safeKey] ?? 0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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

  void _mostrarDetalleRuta(BuildContext context, String fullPath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final partes = fullPath.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBEBEB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ruta Técnica Completa',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: partes.asMap().entries.map((entry) {
                      final isLast = entry.key == partes.length - 1;
                      return Chip(
                        label: Text(
                          entry.value,
                          style: TextStyle(
                            color: isLast ? Colors.white : const Color(0xFF1F5C3D),
                            fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: isLast ? const Color(0xFF1F5C3D) : const Color(0xFF1F5C3D).withValues(alpha: 0.08),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTreeNodeWidget(TreeNode node) {
    if (node.isLeaf) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EquiposAreaPage(area: node.fullPath, rol: widget.rol),
              ),
            );
          },
          onLongPress: () {
            HapticFeedback.selectionClick();
            _mostrarDetalleRuta(context, node.fullPath);
          },
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A1C1E).withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F5C3D).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.device_hub_rounded, color: Color(0xFF1F5C3D), size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Tooltip(
                      message: node.name,
                      child: Text(
                        node.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1C1E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildConteoWidget(node.fullPath),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1C1E).withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const Icon(Icons.folder_rounded, color: Color(0xFF1F5C3D), size: 26),
            title: Tooltip(
              message: node.name,
              child: Text(
                node.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1E),
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildConteoWidget(node.fullPath),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more_rounded, color: Color(0xFF5F6368)),
              ],
            ),
            children: node.children.values.map((child) {
              return Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 8.0, bottom: 8.0),
                child: _buildTreeNodeWidget(child),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchList(ConfiguracionProvider config) {
    final areasFiltradas = config.areasProceso.where((area) {
      return area.toLowerCase().contains(_terminoBusquedaDirectorio.toLowerCase());
    }).toList();

    if (areasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: const Color(0xFF5F6368).withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron áreas.',
              style: TextStyle(color: Color(0xFF5F6368), fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
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

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EquiposAreaPage(area: areaCompleta, rol: widget.rol),
              ),
            );
          },
          onLongPress: () {
            HapticFeedback.selectionClick();
            _mostrarDetalleRuta(context, areaCompleta);
          },
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A1C1E).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F5C3D).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search_rounded, color: Color(0xFF1F5C3D), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subTitle.isNotEmpty)
                          Text(
                            subTitle,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5F6368),
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (subTitle.isNotEmpty) const SizedBox(height: 4),
                        Text(
                          mainTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1C1E),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildConteoWidget(areaCompleta),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFD9D9D9)),
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
            CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D)),
            SizedBox(height: 24),
            Text(
              'Sincronizando directorios...',
              style: TextStyle(
                color: Color(0xFF5F6368),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: const Color(0xFFF5F6F7),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar en la estructura jerárquica...',
              hintStyle: const TextStyle(color: Color(0xFF5F6368)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1F5C3D)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: Color(0xFFEBEBEB), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: const BorderSide(color: Color(0xFF1F5C3D), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
            onChanged: (valor) {
              setState(() {
                _terminoBusquedaDirectorio = valor;
              });
            },
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isSearching
                ? _buildSearchList(config)
                : ListView(
                    key: const ValueKey('directorio_list'),
                    padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: widget.rol == 'admin' ? 16.0 : 80.0),
                    children: config.arbolJerarquico.children.values.map((child) => _buildTreeNodeWidget(child)).toList(),
                  ),
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCardsRow(),
                  const SizedBox(height: 24),
                  const Text(
                    'Lista Detallada de Equipos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Utilice los filtros para realizar búsquedas específicas en la base de datos.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                  ),
                  const SizedBox(height: 20),
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
            const Divider(height: 1, color: Color(0xFFEBEBEB)),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _isLoadingTable
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D)))
                    : _buildOptimizedDataTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCardsRow() {
    if (_cargandoStats) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D))),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, const Color(0xFF1F5C3D).withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBEBEB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1C1E).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F5C3D).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_rounded, color: Color(0xFF1F5C3D), size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Total de Equipos en la Planta',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF5F6368)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _totalEquipos.toString(),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F5C3D),
              letterSpacing: -1,
            ),
          ),
        ],
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
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF5F6368), size: 22),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1F5C3D))),
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
                  prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF5F6368), size: 22),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                initialValue: _filtroMacroArea.isEmpty ? null : _filtroMacroArea,
                hint: const Text('Todas las Áreas', overflow: TextOverflow.ellipsis),
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todas las Áreas')),
                  ...macroAreasDisponibles.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
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
                  prefixIcon: const Icon(Icons.sort_rounded, color: Color(0xFF5F6368), size: 22),
                  filled: true,
                  fillColor: const Color(0xFFF5F6F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                initialValue: _sortOrder,
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded, size: 64, color: const Color(0xFF5F6368).withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron equipos.',
              style: TextStyle(color: Color(0xFF5F6368), fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _filteredDashboardData.length + (_cargandoMas ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _filteredDashboardData.length) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D))),
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
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFEBEBEB), width: 1),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      HapticFeedback.lightImpact();
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
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F5C3D).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data['codigo'] ?? 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F5C3D), fontSize: 13, letterSpacing: 0.5),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF5F6368), size: 18),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            nombrePrincipal,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1C1E)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.business_rounded, size: 18, color: Color(0xFF5F6368)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(macroArea, style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF5F6368)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(ubicacionEspecifica, style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.precision_manufacturing_rounded, size: 18, color: Color(0xFF5F6368)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(fabricanteModelo, style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ],
                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                const Divider(height: 1, thickness: 1, color: Color(0xFFEBEBEB)),
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
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D))),
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

                        return InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
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
                          hoverColor: const Color(0xFF1F5C3D).withValues(alpha: 0.04),
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFEBEBEB), width: 1)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                SizedBox(width: col1, child: Text(data['codigo'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1C1E)))),
                                SizedBox(width: col2, child: Padding(padding: const EdgeInsets.only(right: 12.0), child: Tooltip(message: nombrePrincipal, child: Text(nombrePrincipal, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1A1C1E)))))),
                                SizedBox(width: col3, child: Padding(padding: const EdgeInsets.only(right: 12.0), child: Tooltip(message: macroArea, child: Text(macroArea, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF5F6368)))))),
                                SizedBox(width: col4, child: Padding(padding: const EdgeInsets.only(right: 12.0), child: Tooltip(message: fabricanteModelo, child: Text(fabricanteModelo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF5F6368)))))),
                                SizedBox(width: col5, child: Padding(padding: const EdgeInsets.only(right: 12.0), child: Tooltip(message: ubicacionCompleta, child: Text(ubicacionEspecifica, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF5F6368)))))),
                                SizedBox(
                                  width: col6, 
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1F5C3D).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1F5C3D), size: 20),
                                    ),
                                  )
                                ),
                              ],
                            ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      leading: Icon(icon, color: color == const Color(0xFF1A1C1E) ? const Color(0xFF1F5C3D) : color, size: 26),
      title: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      hoverColor: const Color(0xFF1F5C3D).withValues(alpha: 0.05),
      splashColor: const Color(0xFF1F5C3D).withValues(alpha: 0.1),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 32,
              left: 24,
              right: 24,
              bottom: 32,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1F5C3D),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 32, color: Color(0xFF1F5C3D), fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 0.2),
                ),
                const SizedBox(height: 6),
                Text(
                  userEmail,
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Rol: $rolCapitalizado',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
              children: [
                if (esAprobador) ...[
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('ediciones_pendientes').snapshots(),
                    builder: (context, snapshot) {
                      int pendientesCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildDrawerItem(
                        icon: Icons.fact_check_rounded,
                        text: 'Equipos por Aprobar',
                        trailing: pendientesCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC362E),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '$pendientesCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Color(0xFFEBEBEB), indent: 16, endIndent: 16),
                  ),
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
                        icon: Icons.assignment_rounded,
                        text: 'Mis Solicitudes',
                        trailing: pendientesCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F5C3D),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '$pendientesCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Color(0xFFEBEBEB), indent: 16, endIndent: 16),
                  ),
                ],
                if (widget.rol != 'consultor') ...[
                  _buildDrawerItem(
                    icon: Icons.smart_toy_rounded,
                    text: 'Asistente Técnico IA',
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarAsistenteIA(context);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Color(0xFFEBEBEB), indent: 16, endIndent: 16),
                  ),
                ],
                _buildDrawerItem(
                  icon: Icons.picture_as_pdf_rounded,
                  text: 'Manual de Mantenimiento',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManualPage()));
                  },
                ),
                if (widget.rol == 'admin')
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings_rounded,
                    text: 'Control de Accesos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUsuariosPage()));
                    },
                  ),
                if (esAprobador)
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    text: 'Configuración del Sistema',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PanelConfiguracionPage()));
                    },
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEBEBEB), height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDrawerItem(
              icon: Icons.logout_rounded,
              text: 'Cerrar Sesión',
              color: const Color(0xFFDC362E),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ),
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