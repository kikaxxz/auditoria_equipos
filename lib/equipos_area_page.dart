import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'equipos_list_provider.dart';
import 'detalle_equipo_page.dart';
import 'formulario_equipo.dart';
import 'equipo_form_provider.dart';

class EquiposAreaPage extends StatefulWidget {
  final String area;
  final String rol;

  const EquiposAreaPage({super.key, required this.area, required this.rol});

  @override
  State<EquiposAreaPage> createState() => _EquiposAreaPageState();
}

class _EquiposAreaPageState extends State<EquiposAreaPage> {
  final ScrollController _scrollController = ScrollController();
  late EquiposListProvider _listProvider;

  @override
  void initState() {
    super.initState();
    _listProvider = Provider.of<EquiposListProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listProvider.cargarEquiposPorArea(widget.area, reiniciar: true);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _listProvider.cargarEquiposPorArea(widget.area);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _mostrarDetalleRuta(BuildContext context, String fullPath, String tituloModal) {
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
              Text(
                tituloModal,
                style: const TextStyle(
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

  Widget _buildEquipoCard(Map<String, dynamic> data, String docId) {
    String ubicacionCompleta = data['ubicacionTecnica'] ?? '';
    String ubicacionEspecifica = 'Ubicación no especificada';

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
    String fabricanteModelo = 'Fabricante/Modelo no especificado';

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
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEBEBEB), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleEquipoPage(
                documentId: docId,
                datos: data,
                rolUsuario: widget.rol,
              ),
            ),
          );
        },
        hoverColor: const Color(0xFF1F5C3D).withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1C1E).withValues(alpha: 0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F5C3D).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.device_hub_rounded, color: Color(0xFF1F5C3D), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Tooltip(
                            message: nombrePrincipal,
                            waitDuration: const Duration(milliseconds: 400),
                            child: Text(
                              nombrePrincipal,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1C1E),
                                height: 1.2,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.business_rounded, size: 16, color: Color(0xFF5F6368)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  fabricanteModelo,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF5F6368),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Divider(color: Color(0xFFEBEBEB), height: 24, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TAG / CÓDIGO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5F6368),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F5C3D).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              data['codigo']?.toString().isNotEmpty == true ? data['codigo'] : 'N/A',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F5C3D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: () => _mostrarDetalleRuta(context, ubicacionCompleta, 'Ruta Técnica de Ubicación'),
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'UBICACIÓN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5F6368),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF5F6368)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ubicacionEspecifica,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1C1E),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partes = widget.area.split(' / ');
    final nombreVista = partes.last.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _mostrarDetalleRuta(context, widget.area, 'Jerarquía del Área'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  nombreVista,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.expand_circle_down_rounded, size: 16, color: Colors.white70),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF1F5C3D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por código (Ej. MT-01...)',
                hintStyle: const TextStyle(color: Color(0xFF5F6368)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1F5C3D)),
                filled: true,
                fillColor: const Color(0xFFF5F6F7),
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
                _listProvider.buscarEquipos(valor);
              },
            ),
          ),
          Expanded(
            child: Consumer<EquiposListProvider>(
              builder: (context, provider, child) {
                if (provider.cargando && provider.equipos.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D)),
                  );
                }

                if (provider.equipos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_rounded, size: 64, color: const Color(0xFF5F6368).withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay equipos en esta área.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return RefreshIndicator(
                        color: const Color(0xFF1F5C3D),
                        backgroundColor: Colors.white,
                        onRefresh: () async {
                          await provider.cargarEquiposPorArea(widget.area, reiniciar: true);
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          itemCount: provider.equipos.length + (provider.hayMas ? 1 : 0),
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == provider.equipos.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D)),
                                ),
                              );
                            }
                            final data = provider.equipos[index];
                            return SizedBox(
                              height: 220,
                              child: _buildEquipoCard(data, data['id_documento']),
                            );
                          },
                        ),
                      );
                    } else {
                      return RefreshIndicator(
                        color: const Color(0xFF1F5C3D),
                        backgroundColor: Colors.white,
                        onRefresh: () async {
                          await provider.cargarEquiposPorArea(widget.area, reiniciar: true);
                        },
                        child: GridView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24.0),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 450,
                            mainAxisExtent: 240,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                          ),
                          itemCount: provider.equipos.length + (provider.hayMas ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.equipos.length) {
                              return const Center(
                                child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1F5C3D)),
                              );
                            }
                            final data = provider.equipos[index];
                            return _buildEquipoCard(data, data['id_documento']);
                          },
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.rol == 'consultor' ? null : FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          final formProvider = Provider.of<EquipoFormProvider>(context, listen: false);
          formProvider.resetForm();
          formProvider.updateField('areaProceso', widget.area);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormularioEquipoPage(rolUsuario: widget.rol),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: const Text(
          'Nuevo Registro',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            fontSize: 15,
          ),
        ),
        backgroundColor: const Color(0xFF1F5C3D),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}