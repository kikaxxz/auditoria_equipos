import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'configuracion_provider.dart';

class PanelConfiguracionPage extends StatelessWidget {
  const PanelConfiguracionPage({super.key});

  void _abrirGestorDiccionario(BuildContext context, String titulo, String tipoArreglo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GestorDiccionarioSheet(
        titulo: titulo,
        tipoArreglo: tipoArreglo,
      ),
    );
  }

  Widget _buildConfigCard(BuildContext context, String titulo, String subtitulo, IconData icono, String tipoArreglo) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFD9D9D9), width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirGestorDiccionario(context, titulo, tipoArreglo),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F5C3D).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: const Color(0xFF1F5C3D), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5F6368),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFD9D9D9)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F7),
      appBar: AppBar(
        title: const Text('Configuración del Sistema', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1F5C3D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0, left: 4.0),
            child: Text(
              'Diccionarios de Datos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5F6368),
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildConfigCard(context, 'Familias de Equipos', 'Gestión de categorías tecnológicas', Icons.category, 'familias'),
          const SizedBox(height: 12),
          _buildConfigCard(context, 'Marcas Registradas', 'Fabricantes autorizados en planta', Icons.branding_watermark, 'marcas'),
          const SizedBox(height: 12),
          _buildConfigCard(context, 'Unidades de Ingeniería', 'Magnitudes físicas y de control', Icons.square_foot, 'unidades'),
          const SizedBox(height: 12),
          _buildConfigCard(context, 'Áreas y Subáreas', 'Estructura jerárquica de procesos', Icons.account_tree, 'areas_proceso'),
        ],
      ),
    );
  }
}

class _GestorDiccionarioSheet extends StatefulWidget {
  final String titulo;
  final String tipoArreglo;

  const _GestorDiccionarioSheet({required this.titulo, required this.tipoArreglo});

  @override
  State<_GestorDiccionarioSheet> createState() => _GestorDiccionarioSheetState();
}

class _GestorDiccionarioSheetState extends State<_GestorDiccionarioSheet> {
  final TextEditingController _textController = TextEditingController();
  bool _procesando = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _agregarRegistro() async {
    final nuevoValor = _textController.text.trim();
    if (nuevoValor.isEmpty) return;

    setState(() => _procesando = true);
    final config = context.read<ConfiguracionProvider>();
    final exito = await config.agregarElemento(widget.tipoArreglo, nuevoValor);

    if (mounted) {
      setState(() => _procesando = false);
      if (exito) {
        _textController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro añadido correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al añadir el registro')),
        );
      }
    }
  }

  Future<void> _eliminarRegistro(String valor) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: Text('¿Está seguro que desea eliminar "$valor"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF5F6368))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Color(0xFFDC362E))),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      setState(() => _procesando = true);
      final config = context.read<ConfiguracionProvider>();
      final exito = await config.eliminarElemento(widget.tipoArreglo, valor);

      if (mounted) {
        setState(() => _procesando = false);
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro eliminado correctamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar el registro')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfiguracionProvider>();
    List<String> elementos = [];

    switch (widget.tipoArreglo) {
      case 'familias':
        elementos = config.familias;
        break;
      case 'marcas':
        elementos = config.marcas;
        break;
      case 'unidades':
        elementos = config.unidades;
        break;
      case 'areas_proceso':
        elementos = config.areasProceso;
        break;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F6F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0xFFD9D9D9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gestionar ${widget.titulo}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F5C3D),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF5F6368)),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !_procesando,
                    decoration: InputDecoration(
                      hintText: 'Añadir nuevo registro...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                    ),
                    onSubmitted: (_) => _agregarRegistro(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5C3D),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _procesando ? null : _agregarRegistro,
                  child: _procesando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: elementos.isEmpty
                ? const Center(
                    child: Text(
                      'No hay registros disponibles.',
                      style: TextStyle(color: Color(0xFF5F6368)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: elementos.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final valor = elementos[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFD9D9D9)),
                        ),
                        child: ListTile(
                          title: Text(valor),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC362E)),
                            onPressed: _procesando ? null : () => _eliminarRegistro(valor),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}