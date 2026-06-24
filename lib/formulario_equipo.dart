import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'equipo_form_provider.dart';
import 'configuracion_provider.dart';
import 'imagen_drive_widget.dart';

const Color _isaPrimary = Color(0xFF1F5C3D);
const Color _isaBackground = Color(0xFFF5F6F7);
const Color _isaSurface = Color(0xFFFFFFFF);  
const Color _isaTextPrimary = Color(0xFF1A1C1E);
const Color _isaTextSecondary = Color(0xFF5F6368);
const Color _isaDivider = Color(0xFFEBEBEB);

class FormularioEquipoPage extends StatefulWidget {
  final String rolUsuario;
  
  const FormularioEquipoPage({super.key, required this.rolUsuario});

  @override
  State<FormularioEquipoPage> createState() => _FormularioEquipoPageState();
}

class _FormularioEquipoPageState extends State<FormularioEquipoPage> {
  int _currentStep = 0;
  bool _hayConexion = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  bool get tienePrivilegios => ['admin', 'supervisor'].contains(widget.rolUsuario);

  @override
  void initState() {
    super.initState();
    _verificarConexionInicial();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (mounted) {
        setState(() {
          _hayConexion = !results.contains(ConnectivityResult.none);
        });
      }
    });
  }

  Future<void> _verificarConexionInicial() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _hayConexion = !results.contains(ConnectivityResult.none);
      });
    }
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  InputDecoration _buildInputDeco(String label, IconData icon, [String? hint, bool readOnly = false]) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: readOnly ? const Color(0xFF9AA0A6) : _isaPrimary, size: 22),
      suffixIcon: readOnly ? const Tooltip(message: 'Campo bloqueado para este rol', child: Icon(Icons.lock_outline_rounded, color: Color(0xFF9AA0A6), size: 20)) : null,
      filled: true,
      fillColor: readOnly ? const Color(0xFFF1F3F4) : _isaSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _isaDivider, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _isaDivider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _isaPrimary, width: 2),
      ),
      labelStyle: TextStyle(color: readOnly ? const Color(0xFF9AA0A6) : _isaTextSecondary, fontSize: 14),
      floatingLabelStyle: TextStyle(color: readOnly ? const Color(0xFF9AA0A6) : _isaPrimary, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildResponsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(children.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == children.length - 1 ? 0 : 16.0,
                ),
                child: children[index],
              );
            }),
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(children.length, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == children.length - 1 ? 0 : 16.0,
                  ),
                  child: children[index],
                ),
              );
            }),
          );
        }
      },
    );
  }

  Widget _buildPremiumPath(String path) {
    if (path.isEmpty) return const Text('Vacío', style: TextStyle(color: _isaTextSecondary));
    final parts = path.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: parts.map((part) {
            final isLast = part == parts.last;
            return Container(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLast ? _isaPrimary.withValues(alpha: 0.1) : _isaBackground,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isLast ? _isaPrimary.withValues(alpha: 0.3) : _isaDivider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      part,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                        color: isLast ? _isaPrimary : _isaTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isLast) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFD9D9D9))),
                ],
              ),
            );
          }).toList(),
        );
      }
    );
  }

  Widget _buildImageCapture(String title, String? base64Image, String? imageUrl, VoidCallback onCapture, IconData icon) {
    final bool hasImage = base64Image != null || (imageUrl != null && imageUrl.isNotEmpty);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _isaPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _isaTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onCapture();
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: hasImage ? _isaSurface : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasImage ? _isaPrimary.withValues(alpha: 0.5) : _isaDivider,
                width: hasImage ? 2 : 1.5,
              ),
              boxShadow: hasImage ? [
                BoxShadow(color: _isaPrimary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: base64Image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        base64Decode(base64Image),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        gaplessPlayback: true,
                        cacheWidth: 800,
                      ),
                    )
                  : (imageUrl != null && imageUrl.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: double.infinity,
                            child: ImagenDriveWidget(fileId: imageUrl),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _isaSurface,
                                shape: BoxShape.circle,
                                border: Border.all(color: _isaDivider),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.add_a_photo_rounded, size: 40, color: _isaPrimary),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tocar para capturar evidencia',
                              style: TextStyle(
                                color: _isaTextSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTreeSelectionNode(TreeNode node, EquipoFormProvider provider, ConfiguracionProvider config, BuildContext bottomSheetContext) {
    if (node.isLeaf) {
      return ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 24, top: 4, bottom: 4),
        title: Text(node.name, style: const TextStyle(fontSize: 14, color: _isaTextPrimary)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _isaPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.device_hub_rounded, color: _isaPrimary, size: 18),
        ),
        trailing: const Icon(Icons.check_circle_outline_rounded, color: _isaPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          provider.updateField('areaProceso', node.fullPath);
          Navigator.pop(bottomSheetContext);
        },
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.only(left: 16, right: 24),
        title: Text(node.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _isaTextPrimary)),
        leading: const Icon(Icons.folder_open_rounded, color: _isaPrimary),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: node.children.values.map((c) => _buildTreeSelectionNode(c, provider, config, bottomSheetContext)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarSelectorArea(EquipoFormProvider provider, ConfiguracionProvider config) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: _isaSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _isaDivider)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Navegador de Ubicación',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _isaPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _isaTextSecondary),
                      splashRadius: 24,
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24, top: 8),
                  children: config.arbolJerarquico.children.values.map((child) => _buildTreeSelectionNode(child, provider, config, bottomSheetContext)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _stepContentDecoration() {
    return BoxDecoration(
      color: _isaSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _isaDivider),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfiguracionProvider>();
    final providerCore = context.read<EquipoFormProvider>();

    return Scaffold(
      backgroundColor: _isaBackground,
      appBar: AppBar(
        title: const Text(
          'Registro de Instrumento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: _isaPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: !_hayConexion
                  ? Container(
                      key: const ValueKey('offline_banner'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF57F17),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Modo sin conexión detectado. Los datos se guardarán localmente en el dispositivo.',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('online_banner')),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: _isaPrimary,
                      ),
                    ),
                    child: Stepper(
                      type: StepperType.vertical,
                      currentStep: _currentStep,
                      physics: const ClampingScrollPhysics(),
                      onStepContinue: () async {
                        if (_currentStep < 4) {
                          setState(() => _currentStep += 1);
                        } else {
                          final exito = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext dialogContext) {
                              return DialogoProgresoSubida(
                                tarea: context.read<EquipoFormProvider>().guardarLevantamientoFinal(rolUsuario: widget.rolUsuario),
                              );
                            },
                          );

                          if (exito == null || !mounted) return;
                          Navigator.of(this.context).pop(true);
                        }
                      },
                      onStepCancel: () {
                        if (_currentStep > 0) {
                          setState(() => _currentStep -= 1);
                        }
                      },
                      controlsBuilder: (BuildContext context, ControlsDetails details) {
                        final isLastStep = _currentStep == 4;
                        return Selector<EquipoFormProvider, bool>(
                          selector: (_, p) => p.guardandoEnRed,
                          builder: (context, guardandoEnRed, child) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                              child: _buildResponsiveRow([
                                ElevatedButton.icon(
                                  onPressed: guardandoEnRed ? null : details.onStepContinue,
                                  icon: guardandoEnRed
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Icon(isLastStep 
                                          ? (_hayConexion 
                                              ? (!tienePrivilegios ? Icons.send_rounded : Icons.cloud_upload_rounded) 
                                              : Icons.save_alt_rounded) 
                                          : Icons.arrow_forward_rounded, size: 20),
                                  label: Text(
                                    isLastStep 
                                        ? (guardandoEnRed 
                                            ? 'PROCESANDO...' 
                                            : (_hayConexion 
                                                ? (!tienePrivilegios ? 'ENVIAR A REVISIÓN' : 'GUARDAR Y SINCRONIZAR')
                                                : 'GUARDAR LOCALMENTE')) 
                                        : 'SIGUIENTE',
                                    style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isaPrimary,
                                    foregroundColor: _isaSurface,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                if (_currentStep > 0)
                                  OutlinedButton.icon(
                                    onPressed: guardandoEnRed ? null : details.onStepCancel,
                                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                                    label: const Text(
                                      'ATRÁS',
                                      style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _isaTextSecondary,
                                      side: BorderSide(color: guardandoEnRed ? Colors.grey : _isaDivider, width: 1.5),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                              ]),
                            );
                          }
                        );
                      },
                      steps: [
                        Step(
                          title: const Text('Identificación Principal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: const Text('Código, nombre y jerarquía', style: TextStyle(color: _isaTextSecondary)),
                          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                          isActive: _currentStep >= 0,
                          content: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: _stepContentDecoration(),
                            child: Column(
                              children: [
                                TextFormField(
                                  initialValue: providerCore.codigo,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: _buildInputDeco('Código del Equipo (Tag)', Icons.tag_rounded, 'Ej. PT-100'),
                                  onChanged: (val) => context.read<EquipoFormProvider>().updateField('codigo', val),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: providerCore.descripcion,
                                  maxLines: 2,
                                  decoration: _buildInputDeco('Descripción del Equipo', Icons.description_rounded, 'Detalle la función principal'),
                                  onChanged: (val) => context.read<EquipoFormProvider>().updateField('descripcion', val),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: providerCore.nombre,
                                  maxLines: 2,
                                  decoration: _buildInputDeco('Nombre del equipo', Icons.badge_rounded, 'Nombre de identificación común'),
                                  onChanged: (val) => context.read<EquipoFormProvider>().updateField('nombre', val),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: providerCore.equipoPadre,
                                  decoration: _buildInputDeco('Equipo Padre', Icons.account_tree_rounded, 'Ej. Sistema de Enfriamiento'),
                                  onChanged: (val) => context.read<EquipoFormProvider>().updateField('equipoPadre', val),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Step(
                          title: const Text('Clasificación y Ubicación', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: const Text('Área, familia tecnológica y costos', style: TextStyle(color: _isaTextSecondary)),
                          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                          isActive: _currentStep >= 1,
                          content: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: _stepContentDecoration(),
                            child: Column(
                              children: [
                                Selector<EquipoFormProvider, String>(
                                  selector: (_, p) => p.areaProceso,
                                  builder: (context, areaProceso, child) {
                                    return InkWell(
                                      onTap: () => _mostrarSelectorArea(context.read<EquipoFormProvider>(), config),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: _isaSurface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _isaDivider, width: 1),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(left: 4, right: 12),
                                              child: Icon(Icons.domain_rounded, color: _isaPrimary, size: 22),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Área de Proceso',
                                                    style: TextStyle(fontSize: 12, color: _isaTextSecondary, fontWeight: FontWeight.w600),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    areaProceso.isNotEmpty ? areaProceso.split(' / ').last : 'Toque para seleccionar...',
                                                    style: TextStyle(
                                                      color: areaProceso.isNotEmpty ? _isaTextPrimary : const Color(0xFF9AA0A6),
                                                      fontSize: 14,
                                                      fontWeight: areaProceso.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                                                    ),
                                                  ),
                                                  if (areaProceso.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8.0),
                                                      child: _buildPremiumPath(areaProceso),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.arrow_drop_down_rounded, color: _isaTextSecondary),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                ),
                                const SizedBox(height: 16),
                                Selector<EquipoFormProvider, String>(
                                  selector: (_, p) => p.familia,
                                  builder: (context, familia, child) {
                                    return Column(
                                      children: [
                                        DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          initialValue: config.familias.contains(familia) ? familia : null,
                                          decoration: _buildInputDeco('Familia del Equipo', Icons.category_rounded),
                                          dropdownColor: _isaSurface,
                                          borderRadius: BorderRadius.circular(12),
                                          items: config.familias.map((String familiaItem) {
                                            return DropdownMenuItem<String>(
                                              value: familiaItem,
                                              child: Text(familiaItem, overflow: TextOverflow.ellipsis),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) context.read<EquipoFormProvider>().updateField('familia', val);
                                          },
                                        ),
                                        if (familia == 'Otro...') ...[
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            initialValue: providerCore.familiaPersonalizada,
                                            decoration: _buildInputDeco('Especificar Familia', Icons.edit_rounded, 'Ingrese la familia del equipo'),
                                            onChanged: (val) => context.read<EquipoFormProvider>().updateField('familiaPersonalizada', val),
                                          ),
                                        ],
                                      ],
                                    );
                                  }
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: providerCore.ubicacionTecnica,
                                  decoration: _buildInputDeco('Ubicación Específica', Icons.location_on_rounded, 'Ej. Columna 3, Nivel 2'),
                                  onChanged: (val) => context.read<EquipoFormProvider>().updateField('ubicacionTecnica', val),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: providerCore.centroCosto,
                                  readOnly: !tienePrivilegios,
                                  style: TextStyle(color: !tienePrivilegios ? const Color(0xFF9AA0A6) : _isaTextPrimary),
                                  decoration: _buildInputDeco('Centro de Costo', Icons.monetization_on_rounded, 'Ej. 1411 - COGENERACION', !tienePrivilegios),
                                  onChanged: tienePrivilegios ? (val) => context.read<EquipoFormProvider>().updateField('centro_costo', val) : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Step(
                          title: const Text('Datos de Placa y Proceso', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: const Text('Especificaciones técnicas', style: TextStyle(color: _isaTextSecondary)),
                          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                          isActive: _currentStep >= 2,
                          content: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: _stepContentDecoration(),
                            child: Column(
                              children: [
                                _buildResponsiveRow([
                                  Selector<EquipoFormProvider, String>(
                                    selector: (_, p) => p.marca,
                                    builder: (context, marca, child) {
                                      return DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: config.marcas.contains(marca) ? marca : null,
                                        decoration: _buildInputDeco('Marca / Fabricante', Icons.branding_watermark_rounded),
                                        dropdownColor: _isaSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        items: config.marcas.map((String marcaItem) {
                                          return DropdownMenuItem<String>(
                                            value: marcaItem,
                                            child: Text(marcaItem, overflow: TextOverflow.ellipsis),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) context.read<EquipoFormProvider>().updateField('marca', val);
                                        },
                                      );
                                    }
                                  ),
                                  TextFormField(
                                    initialValue: providerCore.modelo,
                                    decoration: _buildInputDeco('Modelo', Icons.inventory_2_rounded, 'Modelo del equipo'),
                                    onChanged: (val) => context.read<EquipoFormProvider>().updateField('modelo', val),
                                  ),
                                ]),
                                Selector<EquipoFormProvider, String>(
                                  selector: (_, p) => p.marca,
                                  builder: (context, marca, child) {
                                    if (marca == 'Otro...') {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 16.0),
                                        child: TextFormField(
                                          initialValue: providerCore.marcaPersonalizada,
                                          decoration: _buildInputDeco('Especificar Marca', Icons.edit_rounded, 'Ingrese la marca del equipo'),
                                          onChanged: (val) => context.read<EquipoFormProvider>().updateField('marcaPersonalizada', val),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }
                                ),
                                const SizedBox(height: 16),
                                _buildResponsiveRow([
                                  TextFormField(
                                    initialValue: providerCore.numeroSerie,
                                    decoration: _buildInputDeco('No. Serie', Icons.qr_code_rounded, 'S/N de placa'),
                                    onChanged: (val) => context.read<EquipoFormProvider>().updateField('numeroSerie', val),
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                _buildResponsiveRow([
                                  TextFormField(
                                    initialValue: providerCore.variableMedida,
                                    decoration: _buildInputDeco('Variable', Icons.speed_rounded, 'Ej. Presión, Flujo'),
                                    onChanged: (val) => context.read<EquipoFormProvider>().updateField('variableMedida', val),
                                  ),
                                  TextFormField(
                                    initialValue: providerCore.senalEntradaSalida,
                                    decoration: _buildInputDeco('Señal', Icons.settings_input_component_rounded, 'Ej. 4-20mA, Profibus'),
                                    onChanged: (val) => context.read<EquipoFormProvider>().updateField('senalEntradaSalida', val),
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                _buildResponsiveRow([
                                  TextFormField(
                                    initialValue: providerCore.rangoLrv,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDeco('LRV', Icons.vertical_align_bottom_rounded, 'Límite Inferior'),
                                    onChanged: (val) => context.read<EquipoFormProvider>().updateField('rangoLrv', val),
                                  ),
                                  TextFormField(
                                    initialValue: providerCore.rangoUrv,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDeco('URV', Icons.vertical_align_top_rounded, 'Límite Superior'),
                                    onChanged: (val) => context.read<EquipoFormProvider>().updateField('rangoUrv', val),
                                  ),
                                  Selector<EquipoFormProvider, String>(
                                    selector: (_, p) => p.unidadIngenieria,
                                    builder: (context, unidadIngenieria, child) {
                                      return DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        initialValue: config.unidades.contains(unidadIngenieria) ? unidadIngenieria : null,
                                        decoration: _buildInputDeco('Unidad', Icons.square_foot_rounded),
                                        dropdownColor: _isaSurface,
                                        borderRadius: BorderRadius.circular(12),
                                        items: config.unidades.map((String unidadItem) {
                                          return DropdownMenuItem<String>(
                                            value: unidadItem,
                                            child: Text(unidadItem, overflow: TextOverflow.ellipsis),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) context.read<EquipoFormProvider>().updateField('unidadIngenieria', val);
                                        },
                                      );
                                    }
                                  ),
                                ]),
                                Selector<EquipoFormProvider, String>(
                                  selector: (_, p) => p.unidadIngenieria,
                                  builder: (context, unidadIngenieria, child) {
                                    if (unidadIngenieria == 'Otro...') {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 16.0),
                                        child: TextFormField(
                                          initialValue: providerCore.unidadPersonalizada,
                                          decoration: _buildInputDeco('Especificar Unidad', Icons.edit_rounded, 'Ingrese la unidad de ingeniería'),
                                          onChanged: (val) => context.read<EquipoFormProvider>().updateField('unidadPersonalizada', val),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }
                                ),
                              ],
                            ),
                          ),
                        ),
                        Step(
                          title: const Text('Registro y Estado', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: const Text('Condiciones actuales, hallazgos y supervisión', style: TextStyle(color: _isaTextSecondary)),
                          state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                          isActive: _currentStep >= 3,
                          content: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: _stepContentDecoration(),
                            child: Column(
                              children: [
                                _buildResponsiveRow([
                                  TextFormField(
                                    initialValue: providerCore.supervisor,
                                    readOnly: !tienePrivilegios,
                                    style: TextStyle(color: !tienePrivilegios ? const Color(0xFF9AA0A6) : _isaTextPrimary),
                                    decoration: _buildInputDeco('Supervisor / Clasificación', Icons.person_rounded, 'Encargado del equipo', !tienePrivilegios),
                                    onChanged: tienePrivilegios ? (val) => context.read<EquipoFormProvider>().updateField('supervisor', val) : null,
                                  ),
                                ]),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: providerCore.planTareas,
                                  readOnly: !tienePrivilegios,
                                  style: TextStyle(color: !tienePrivilegios ? const Color(0xFF9AA0A6) : _isaTextPrimary),
                                  decoration: _buildInputDeco('Plan de Tareas', Icons.assignment_rounded, 'Ej. PLAN DE MTTO', !tienePrivilegios),
                                  onChanged: tienePrivilegios ? (val) => context.read<EquipoFormProvider>().updateField('plan_tareas', val) : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: providerCore.observacion,
                                  maxLines: 3,
                                  decoration: _buildInputDeco('Observaciones de Auditoría', Icons.notes_rounded, 'Hallazgos actuales'),
                                  onChanged: (val) => context.read<EquipoFormProvider>().updateField('observacion', val),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  initialValue: "${providerCore.fechaVerificacion.day.toString().padLeft(2, '0')}/${providerCore.fechaVerificacion.month.toString().padLeft(2, '0')}/${providerCore.fechaVerificacion.year}",
                                  readOnly: true,
                                  style: const TextStyle(color: Color(0xFF9AA0A6)),
                                  decoration: _buildInputDeco('Fecha de Verificación', Icons.calendar_today_rounded, null, true),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Step(
                          title: const Text('Evidencia Visual', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          subtitle: const Text('Fotografías de respaldo', style: TextStyle(color: _isaTextSecondary)),
                          state: _currentStep == 4 ? StepState.complete : StepState.indexed,
                          isActive: _currentStep >= 4,
                          content: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: _stepContentDecoration(),
                            child: Consumer<EquipoFormProvider>(
                              builder: (context, provider, child) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildImageCapture(
                                      'Foto de la Placa Técnica',
                                      provider.fotoPlacaBase64,
                                      provider.fotoPlacaUrlExistente,
                                      () => provider.capturarFoto('placa'),
                                      Icons.branding_watermark_rounded,
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(color: _isaDivider, height: 1),
                                    const SizedBox(height: 24),
                                    _buildImageCapture(
                                      'Foto de la Placa Técnica 2 (Opcional)',
                                      provider.fotoPlacaAdicionalBase64,
                                      provider.fotoPlacaAdicionalUrlExistente,
                                      () => provider.capturarFoto('placa_adicional'),
                                      Icons.add_photo_alternate_rounded,
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(color: _isaDivider, height: 1),
                                    const SizedBox(height: 24),
                                    _buildImageCapture(
                                      'Foto General del Equipo',
                                      provider.fotoGeneralBase64,
                                      provider.fotoGeneralUrlExistente,
                                      () => provider.capturarFoto('general'),
                                      Icons.device_hub_rounded,
                                    ),
                                  ],
                                );
                              }
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum EstadoSubida { cargando, exito, local }

class DialogoProgresoSubida extends StatefulWidget {
  final Future<bool> tarea;

  const DialogoProgresoSubida({super.key, required this.tarea});

  @override
  State<DialogoProgresoSubida> createState() => _DialogoProgresoSubidaState();
}

class _DialogoProgresoSubidaState extends State<DialogoProgresoSubida> {
  EstadoSubida _estado = EstadoSubida.cargando;
  double _progreso = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _iniciarAnimacion();
    _ejecutarTarea();
  }

  void _iniciarAnimacion() {
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted && _progreso < 0.90) {
        setState(() {
          _progreso += 0.02;
        });
      }
    });
  }

  Future<void> _ejecutarTarea() async {
    try {
      final resultado = await widget.tarea;
      _timer.cancel();
      if (mounted) {
        setState(() {
          _progreso = 1.0;
          _estado = resultado ? EstadoSubida.exito : EstadoSubida.local;
        });
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) {
          Navigator.of(context).pop(resultado);
        }
      }
    } catch (e) {
      _timer.cancel();
      if (mounted) {
        setState(() {
          _progreso = 1.0;
          _estado = EstadoSubida.local;
        });
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) {
          Navigator.of(context).pop(false);
        }
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _estado == EstadoSubida.cargando
                    ? 'Procesando Registro...'
                    : (_estado == EstadoSubida.exito ? '¡Completado!' : 'Guardado Localmente'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _estado == EstadoSubida.exito
                      ? const Color(0xFF1F5C3D)
                      : (_estado == EstadoSubida.local ? const Color(0xFFF57F17) : const Color(0xFF1A1C1E)),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: _progreso,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFFEBEBEB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _estado == EstadoSubida.exito
                            ? const Color(0xFF1F5C3D)
                            : (_estado == EstadoSubida.local ? const Color(0xFFF57F17) : const Color(0xFF1F5C3D)),
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  if (_estado == EstadoSubida.cargando)
                    Text(
                      '${(_progreso * 100).toInt()}%',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                    )
                  else
                    Icon(
                      _estado == EstadoSubida.exito ? Icons.check_rounded : Icons.cloud_off_rounded,
                      size: 48,
                      color: _estado == EstadoSubida.exito ? const Color(0xFF1F5C3D) : const Color(0xFFF57F17),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                _estado == EstadoSubida.cargando
                    ? 'Por favor, no cierre la aplicación ni bloquee la pantalla.'
                    : (_estado == EstadoSubida.exito
                        ? 'El registro ha sido enviado exitosamente al servidor.'
                        : 'El registro se guardó en el dispositivo y se enviará cuando haya conexión.'),
                style: const TextStyle(color: Color(0xFF5F6368), fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}