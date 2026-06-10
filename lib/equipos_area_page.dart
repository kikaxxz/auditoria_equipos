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

  Widget _buildEstadoChip(String estado) {
    Color colorFondo;
    Color colorTexto;
    String texto = estado.toUpperCase().trim();

    if (texto.contains('OPERATIVA') || texto.contains('CORRECTO') || texto.contains('BIEN')) {
      colorFondo = const Color(0xFFE6F4EA);
      colorTexto = const Color(0xFF1F5C3D);
    } else if (texto.contains('ADVERTENCIA') || texto.contains('MANTENIMIENTO') || texto.contains('PRECAUCIÓN')) {
      colorFondo = const Color(0xFFFFF8E1);
      colorTexto = const Color(0xFFF57F17);
    } else if (texto.contains('FALLA') || texto.contains('CRÍTICO') || texto.contains('MALO') || texto.contains('DETENIDA')) {
      colorFondo = const Color(0xFFFCE8E6);
      colorTexto = const Color(0xFFDC362E);
    } else {
      colorFondo = const Color(0xFFF5F6F7);
      colorTexto = const Color(0xFF5F6368);
      texto = texto.isEmpty ? 'SIN ESTADO' : texto;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: colorTexto,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEquipoCard(Map<String, dynamic> data, String docId) {
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
                        Text(
                          data['descripcion'] ?? 'Sin nombre',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F5C3D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Color(0xFF5F6368)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                data['ubicacionTecnica'] ?? 'Ubicación no especificada',
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
              Text(
                'Tag: ${data['codigo'] ?? 'Sin código'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1E),
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _buildEstadoChip(data['estadoOperativoObservado'] ?? ''),
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
                    if (constraints.maxWidth < 600) {
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
                              height: 180,
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
                            mainAxisExtent: 190,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: provider.equipos.length,
                          itemBuilder: (context, index) {
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final formProvider = Provider.of<EquipoFormProvider>(context, listen: false);
          formProvider.resetForm();
          formProvider.updateField('areaProceso', widget.area);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FormularioEquipoPage(),
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