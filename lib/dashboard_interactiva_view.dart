import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'configuracion_provider.dart';
import 'detalle_equipo_page.dart';

class DashboardInteractivaView extends StatelessWidget {
  final ConfiguracionProvider config;
  final String rol;
  final bool isLoadingTable;
  final List<Map<String, dynamic>> filteredDashboardData;
  final bool cargandoStats;
  final int totalEquipos;
  final bool cargandoMas;
  final String searchTable;
  final String filtroMacroArea;
  final String sortOrder;
  final Function(String) onSearchChanged;
  final Function(String) onFilterChanged;
  final Function(String) onSortChanged;
  final VoidCallback onLoadMore;

  const DashboardInteractivaView({
    super.key,
    required this.config,
    required this.rol,
    required this.isLoadingTable,
    required this.filteredDashboardData,
    required this.cargandoStats,
    required this.totalEquipos,
    required this.cargandoMas,
    required this.searchTable,
    required this.filtroMacroArea,
    required this.sortOrder,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onLoadMore,
  });

  Widget _buildSummaryCardsRow() {
    if (cargandoStats) {
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
            totalEquipos.toString(),
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

  Widget _buildFiltersGrid() {
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
                onSubmitted: onSearchChanged,
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
                initialValue: filtroMacroArea.isEmpty ? null : filtroMacroArea,
                hint: const Text('Todas las Áreas', overflow: TextOverflow.ellipsis),
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todas las Áreas')),
                  ...macroAreasDisponibles.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (val) {
                  onFilterChanged(val ?? '');
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
                initialValue: sortOrder,
                isExpanded: true,
                icon: const Icon(Icons.expand_more_rounded),
                items: const [
                  DropdownMenuItem(value: 'desc', child: Text('Más recientes primero')),
                  DropdownMenuItem(value: 'asc', child: Text('Más antiguos primero')),
                ],
                onChanged: (val) {
                  onSortChanged(val ?? 'desc');
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptimizedDataTable() {
    if (filteredDashboardData.isEmpty) {
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
                onLoadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: filteredDashboardData.length + (cargandoMas ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredDashboardData.length) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D))),
                  );
                }

                final data = filteredDashboardData[index];
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
                            rolUsuario: rol,
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
                        onLoadMore();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      itemCount: filteredDashboardData.length + (cargandoMas ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredDashboardData.length) {
                          return const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D))),
                          );
                        }
                        
                        final data = filteredDashboardData[index];
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
                                  rolUsuario: rol,
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

  @override
  Widget build(BuildContext context) {
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
                  _buildFiltersGrid(),
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
                child: isLoadingTable
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1F5C3D)))
                    : _buildOptimizedDataTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}