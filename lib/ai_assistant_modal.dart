import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'rag_api_service.dart';
import 'manual_page.dart';

class AiAssistantModal {
  static void show(BuildContext context) {
    final RagApiService ragApiService = RagApiService();
    final TextEditingController preguntaController = TextEditingController();
    bool cargandoRAG = false;
    String respuestaRAG = '';
    int? paginaReferenciaRAG;

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
                              controller: preguntaController,
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
                            onPressed: cargandoRAG ? null : () async {
                              try {
                                final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
                                if (connectivityResult.contains(ConnectivityResult.none)) {
                                  setModalState(() {
                                    respuestaRAG = 'Fallo: Sin conexión de red.';
                                    paginaReferenciaRAG = null;
                                    cargandoRAG = false;
                                  });
                                  return;
                                }
                              } catch (e) {
                                setModalState(() {
                                  respuestaRAG = 'Excepción Connectivity: ${e.toString()}';
                                  paginaReferenciaRAG = null;
                                  cargandoRAG = false;
                                });
                                return;
                              }

                              setModalState(() {
                                cargandoRAG = true;
                                respuestaRAG = '';
                                paginaReferenciaRAG = null;
                                mensajeCarga = 'Analizando la consulta...';
                              });

                              int segundos = 0;
                              timerCarga = Timer.periodic(const Duration(seconds: 1), (timer) {
                                segundos++;
                                if (!builderContext.mounted) {
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

                              ragApiService.consultarManual(preguntaController.text).then((resultado) {
                                timerCarga?.cancel();
                                if (!builderContext.mounted) return;
                                setModalState(() {
                                  respuestaRAG = resultado['respuesta'];
                                  paginaReferenciaRAG = resultado['pagina'];
                                  cargandoRAG = false;
                                });
                              }).catchError((error, stackTrace) {
                                timerCarga?.cancel();
                                if (!builderContext.mounted) return;
                                setModalState(() {
                                  respuestaRAG = 'Error Crítico:\n\n$error\n\nStackTrace:\n$stackTrace';
                                  cargandoRAG = false;
                                });
                              });
                            },
                            child: cargandoRAG
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
                          if (cargandoRAG)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                mensajeCarga,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (respuestaRAG.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F5C3D).withValues(alpha: 0.03),
                                border: Border.all(color: const Color(0xFF1F5C3D).withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: MarkdownBody(
                                data: respuestaRAG,
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
                          if (paginaReferenciaRAG != null) ...[
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
                                'Ver página $paginaReferenciaRAG en el Manual',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.pop(builderContext);
                                Navigator.push(
                                  builderContext,
                                  MaterialPageRoute(
                                    builder: (context) => ManualPage(paginaInicial: paginaReferenciaRAG),
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
}