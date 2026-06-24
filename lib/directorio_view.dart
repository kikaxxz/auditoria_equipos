import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'configuracion_provider.dart';
import 'equipos_area_page.dart';

class DirectorioView extends StatelessWidget {
  final ConfiguracionProvider config;
  final String rol;
  final String terminoBusqueda;
  final Function(String) onSearchChanged;
  final Map<String, dynamic> conteosAreasGlobales;
  final bool cargandoConteos;

  const DirectorioView({
    super.key,
    required this.config,
    required this.rol,
    required this.terminoBusqueda,
    required this.onSearchChanged,
    required this.conteosAreasGlobales,
    required this.cargandoConteos,
  });

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

  Widget _buildConteoWidget(String areaCompleta) {
    if (cargandoConteos) {
      return const SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1F5C3D)),
      );
    }

    String safeKey = areaCompleta.replaceAll('/', '-').replaceAll('.', '-');
    final count = conteosAreasGlobales[safeKey] ?? 0;
    
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

  Widget _buildTreeNodeWidget(BuildContext context, TreeNode node) {
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
                builder: (context) => EquiposAreaPage(area: node.fullPath, rol: rol),
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
                child: _buildTreeNodeWidget(context, child),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchList(BuildContext context) {
    final areasFiltradas = config.areasProceso.where((area) {
      return area.toLowerCase().contains(terminoBusqueda.toLowerCase());
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
      padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: rol == 'admin' ? 16.0 : 80.0),
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
                builder: (context) => EquiposAreaPage(area: areaCompleta, rol: rol),
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

  @override
  Widget build(BuildContext context) {
    final bool isSearching = terminoBusqueda.isNotEmpty;
    
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
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isSearching
                ? _buildSearchList(context)
                : ListView(
                    key: const ValueKey('directorio_list'),
                    padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: rol == 'admin' ? 16.0 : 80.0),
                    children: config.arbolJerarquico.children.values.map((child) => _buildTreeNodeWidget(context, child)).toList(),
                  ),
          ),
        ),
      ],
    );
  }
}