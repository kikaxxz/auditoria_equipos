import 'package:flutter/material.dart';
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
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD9D9D9), width: 0.8),
      ),
      margin: EdgeInsets.zero,
      color: const Color(0xFFFFFFFF),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F5C3D).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/images/icono_tarjeta.png',
                      width: 24,
                      height: 24,
                      color: const Color(0xFF1F5C3D),
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.device_hub, color: Color(0xFF1F5C3D), size: 24);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
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
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F5C3D),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.business, size: 14, color: Color(0xFF5F6368)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                fabricanteModelo,
                                style: const TextStyle(
                                  fontSize: 13,
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
              const Divider(color: Color(0xFFD9D9D9), height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tag', style: TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                        Text(
                          data['codigo']?.toString().isNotEmpty == true ? data['codigo'] : 'Sin código',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1C1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Ubicación', style: TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                        Text(
                          ubicacionEspecifica,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F5C3D),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
        title: Text(nombreVista, style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1F5C3D),
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por código (Tag)',
                hintText: 'Ej. MT-01...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1F5C3D)),
                filled: true,
                fillColor: const Color(0xFFF5F6F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
                    child: CircularProgressIndicator(color: Color(0xFF1F5C3D)),
                  );
                }

                if (provider.equipos.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFD9D9D9)),
                        SizedBox(height: 16),
                        Text(
                          'No hay equipos en esta área.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
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
                        backgroundColor: const Color(0xFFFFFFFF),
                        onRefresh: () async {
                          await provider.cargarEquiposPorArea(widget.area, reiniciar: true);
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          itemCount: provider.equipos.length + (provider.hayMas ? 1 : 0),
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == provider.equipos.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(color: Color(0xFF1F5C3D)),
                                ),
                              );
                            }
                            final data = provider.equipos[index];
                            return SizedBox(
                              height: 200,
                              child: _buildEquipoCard(data, data['id_documento']),
                            );
                          },
                        ),
                      );
                    } else {
                      return RefreshIndicator(
                        color: const Color(0xFF1F5C3D),
                        backgroundColor: const Color(0xFFFFFFFF),
                        onRefresh: () async {
                          await provider.cargarEquiposPorArea(widget.area, reiniciar: true);
                        },
                        child: GridView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24.0),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 220,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: provider.equipos.length + (provider.hayMas ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.equipos.length) {
                              return const Center(
                                child: CircularProgressIndicator(color: Color(0xFF1F5C3D)),
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
        icon: const Icon(Icons.add, color: Color(0xFFFFFFFF)),
        label: const Text(
          'Nuevo Registro',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
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