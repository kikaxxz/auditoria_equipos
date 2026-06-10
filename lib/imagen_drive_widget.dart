import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'image_cache_manager.dart';

class ImagenDriveWidget extends StatefulWidget {
  final String fileId;
  final double width;
  final double? height; 
  final double maxHeight; 
  final BoxFit fit;

  const ImagenDriveWidget({
    super.key,
    required this.fileId,
    this.width = double.infinity,
    this.height,
    this.maxHeight = 450, 
    this.fit = BoxFit.contain,
  });

  @override
  State<ImagenDriveWidget> createState() => _ImagenDriveWidgetState();
}

class _ImagenDriveWidgetState extends State<ImagenDriveWidget> {
  Future<Uint8List?>? _futureImage;

  @override
  void initState() {
    super.initState();
    _futureImage = ImageCacheManager.obtenerImagen(widget.fileId);
  }

  void _abrirVisorPantallaCompleta(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _futureImage,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || snapshot.connectionState == ConnectionState.none) {
          return SizedBox(
            width: widget.width,
            height: widget.height ?? 200, // Altura provisional mientras carga
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1F5C3D),
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return SizedBox(
            width: widget.width,
            height: widget.height ?? 200,
            child: Container(
              color: const Color(0xFFE0E0E0),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, color: Color(0xFF9E9E9E), size: 40),
                  SizedBox(height: 8),
                  Text(
                    'Archivo no disponible',
                    style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _abrirVisorPantallaCompleta(context, snapshot.data!),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: widget.maxHeight, // Límite de altura
            ),
            child: Image.memory(
              snapshot.data!,
              width: widget.width,
              height: widget.height, // Al ser nulo, empuja los bordes adaptándose perfectamente
              fit: widget.fit,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) {
                  return child;
                }
                if (frame == null) {
                  return SizedBox(
                    width: widget.width,
                    height: widget.height ?? 200,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1F5C3D),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                return child;
              },
              errorBuilder: (context, error, stackTrace) {
                return SizedBox(
                  width: widget.width,
                  height: widget.height ?? 200,
                  child: Container(
                    color: const Color(0xFFE0E0E0),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Color(0xFFDC362E), size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Error de renderizado',
                          style: TextStyle(color: Color(0xFFDC362E), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}