import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ManualPage extends StatefulWidget {
  const ManualPage({super.key});

  @override
  State<ManualPage> createState() => _ManualPageState();
}

class _ManualPageState extends State<ManualPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  
  bool _isSearching = false;
  bool _isLoadingSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  enabled: !_isLoadingSearch, // Se deshabilita mientras busca
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: _isLoadingSearch ? 'Buscando...' : 'Buscar en el manual...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    // Muestra el indicador de carga dentro de la barra de búsqueda
                    suffixIcon: _isLoadingSearch
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1F5C3D),
                              ),
                            ),
                          )
                        : null,
                  ),
                  onSubmitted: (String text) async {
                    if (text.trim().isEmpty) return;

                    setState(() {
                      _isLoadingSearch = true;
                    });

                    _searchResult = await _pdfViewerController.searchText(text);

                    setState(() {
                      _isLoadingSearch = false;
                    });

                    // Notifica al usuario si no hubo resultados
                    if (_searchResult.totalInstanceCount == 0 && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No se encontraron coincidencias en el manual.')),
                      );
                    }
                  },
                ),
              )
            : const Text('Manual de Mantenimiento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1F5C3D),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: !_isSearching,
        actions: [
          // Ocultamos las flechas de navegación mientras esté procesando la búsqueda
          if (!_isLoadingSearch) ...[
            if (_searchResult.hasResult)
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                onPressed: () {
                  _searchResult.previousInstance();
                  setState(() {});
                },
              ),
            if (_searchResult.hasResult)
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                onPressed: () {
                  _searchResult.nextInstance();
                  setState(() {});
                },
              ),
          ],
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchResult.clear();
                  _searchController.clear();
                  _isLoadingSearch = false;
                }
              });
            },
          ),
        ],
      ),
      body: SfPdfViewer.asset(
        'assets/manual_mantenimiento.pdf',
        controller: _pdfViewerController,
        canShowScrollHead: false,
        canShowScrollStatus: true,
      ),
    );
  }
}