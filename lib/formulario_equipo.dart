import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
const Color _isaDivider = Color(0xFFD9D9D9);

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
      prefixIcon: Icon(icon, color: readOnly ? _isaTextSecondary : _isaPrimary),
      filled: true,
      fillColor: readOnly ? const Color(0xFFEBEBEB) : _isaSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: readOnly ? Colors.transparent : _isaDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: readOnly ? Colors.transparent : _isaDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: readOnly ? Colors.transparent : _isaPrimary, width: 2),
      ),
      labelStyle: const TextStyle(color: _isaTextSecondary, fontSize: 14),
      floatingLabelStyle: TextStyle(color: readOnly ? _isaTextSecondary : _isaPrimary, fontWeight: FontWeight.w600),
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
          onTap: onCapture,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: hasImage ? _isaSurface : _isaBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasImage ? _isaPrimary : _isaDivider,
                width: hasImage ? 2 : 1.5,
              ),
            ),
            child: base64Image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(base64Image),
                      fit: BoxFit.contain,
                    ),
                  )
                : (imageUrl != null && imageUrl.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ImagenDriveWidget(fileId: imageUrl),
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
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add_a_photo, size: 40, color: _isaPrimary),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tocar para capturar evidencia',
                            style: TextStyle(
                              color: _isaTextSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildTreeSelectionNode(TreeNode node, EquipoFormProvider provider, ConfiguracionProvider config) {
    if (node.isLeaf) {
      return ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 24, top: 4, bottom: 4),
        title: Text(node.name, style: const TextStyle(fontSize: 14)),
        leading: const Icon(Icons.device_hub, color: _isaPrimary, size: 20),
        trailing: const Icon(Icons.check_circle_outline, color: _isaPrimary),
        onTap: () {
          provider.updateField('areaProceso', node.fullPath);
          Navigator.pop(context);
        },
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.only(left: 16, right: 24),
        title: Text(node.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.folder_open, color: _isaPrimary),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              children: node.children.values.map((c) => _buildTreeSelectionNode(c, provider, config)).toList(),
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
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: _isaSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
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
                      icon: const Icon(Icons.close, color: _isaTextSecondary),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: config.arbolJerarquico.children.values.map((child) => _buildTreeSelectionNode(child, provider, config)).toList(),
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
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EquipoFormProvider>();
    final config = context.watch<ConfiguracionProvider>();

    return Scaffold(
      backgroundColor: _isaBackground,
      appBar: AppBar(
        title: const Text(
          'Registro de Instrumento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
            if (!_hayConexion)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: const Color(0xFFF57F17),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
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
              ),
            Expanded(
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
                            tarea: provider.guardarLevantamientoFinal(rolUsuario: widget.rolUsuario),
                          );
                        },
                      );

                      if (mounted && exito != null) {
                        Navigator.of(context).pop(true);
                      }
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep -= 1);
                    }
                  },
                  controlsBuilder: (BuildContext context, ControlsDetails details) {
                    final isLastStep = _currentStep == 4;
                    return Padding(
                      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                      child: _buildResponsiveRow([
                        ElevatedButton.icon(
                          onPressed: provider.guardandoEnRed ? null : details.onStepContinue,
                          icon: provider.guardandoEnRed
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Icon(isLastStep 
                                  ? (_hayConexion 
                                      ? (!tienePrivilegios ? Icons.send : Icons.cloud_upload) 
                                      : Icons.save_alt) 
                                  : Icons.arrow_forward),
                          label: Text(
                            isLastStep 
                                ? (provider.guardandoEnRed 
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (_currentStep > 0)
                          OutlinedButton.icon(
                            onPressed: provider.guardandoEnRed ? null : details.onStepCancel,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text(
                              'ATRÁS',
                              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isaPrimary,
                              side: BorderSide(color: provider.guardandoEnRed ? Colors.grey : _isaPrimary, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ]),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Identificación Principal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      subtitle: const Text('Código, nombre y jerarquía', style: TextStyle(color: _isaTextSecondary)),
                      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                      isActive: _currentStep >= 0,
                      content: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _stepContentDecoration(),
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: provider.codigo,
                              textCapitalization: TextCapitalization.characters,
                              decoration: _buildInputDeco('Código del Equipo (Tag)', Icons.tag, 'Ej. PT-100'),
                              onChanged: (val) => provider.updateField('codigo', val),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: provider.descripcion,
                              maxLines: 2,
                              decoration: _buildInputDeco('Descripción del Equipo', Icons.description, 'Detalle la función principal'),
                              onChanged: (val) => provider.updateField('descripcion', val),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: provider.nombre,
                              maxLines: 2,
                              decoration: _buildInputDeco('Nombre del equipo', Icons.badge, 'Nombre de identificación común'),
                              onChanged: (val) => provider.updateField('nombre', val),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: provider.equipoPadre,
                              decoration: _buildInputDeco('Equipo Padre', Icons.account_tree, 'Ej. Sistema de Enfriamiento'),
                              onChanged: (val) => provider.updateField('equipoPadre', val),
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
                        padding: const EdgeInsets.all(16),
                        decoration: _stepContentDecoration(),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () => _mostrarSelectorArea(provider, config),
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: _buildInputDeco('Área de Proceso', Icons.domain),
                                child: Text(
                                  provider.areaProceso.isNotEmpty ? provider.areaProceso.split(' / ').last : 'Toque para seleccionar...',
                                  style: TextStyle(
                                    color: provider.areaProceso.isNotEmpty ? _isaTextPrimary : _isaTextSecondary,
                                    fontSize: 14,
                                    fontWeight: provider.areaProceso.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            if (provider.areaProceso.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                                child: Text(
                                  provider.areaProceso,
                                  style: const TextStyle(fontSize: 11, color: _isaTextSecondary, fontStyle: FontStyle.italic),
                                ),
                              ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: config.familias.contains(provider.familia) ? provider.familia : null,
                              decoration: _buildInputDeco('Familia del Equipo', Icons.category),
                              dropdownColor: _isaSurface,
                              items: config.familias.map((String familiaItem) {
                                return DropdownMenuItem<String>(
                                  value: familiaItem,
                                  child: Text(familiaItem, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) provider.updateField('familia', val);
                              },
                            ),
                            if (provider.familia == 'Otro...') ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: provider.familiaPersonalizada,
                                decoration: _buildInputDeco('Especificar Familia', Icons.edit, 'Ingrese la familia del equipo'),
                                onChanged: (val) => provider.updateField('familiaPersonalizada', val),
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: provider.ubicacionTecnica,
                              decoration: _buildInputDeco('Ubicación Específica', Icons.location_on, 'Ej. Columna 3, Nivel 2'),
                              onChanged: (val) => provider.updateField('ubicacionTecnica', val),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: provider.centroCosto,
                              readOnly: !tienePrivilegios,
                              decoration: _buildInputDeco('Centro de Costo', Icons.monetization_on, 'Ej. 1411 - COGENERACION', !tienePrivilegios),
                              onChanged: tienePrivilegios ? (val) => provider.updateField('centro_costo', val) : null,
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
                        padding: const EdgeInsets.all(16),
                        decoration: _stepContentDecoration(),
                        child: Column(
                          children: [
                            _buildResponsiveRow([
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: config.marcas.contains(provider.marca) ? provider.marca : null,
                                decoration: _buildInputDeco('Marca / Fabricante', Icons.branding_watermark),
                                dropdownColor: _isaSurface,
                                items: config.marcas.map((String marcaItem) {
                                  return DropdownMenuItem<String>(
                                    value: marcaItem,
                                    child: Text(marcaItem, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) provider.updateField('marca', val);
                                },
                              ),
                              TextFormField(
                                initialValue: provider.modelo,
                                decoration: _buildInputDeco('Modelo', Icons.inventory, 'Modelo del equipo'),
                                onChanged: (val) => provider.updateField('modelo', val),
                              ),
                            ]),
                            if (provider.marca == 'Otro...') ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: provider.marcaPersonalizada,
                                decoration: _buildInputDeco('Especificar Marca', Icons.edit, 'Ingrese la marca del equipo'),
                                onChanged: (val) => provider.updateField('marcaPersonalizada', val),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _buildResponsiveRow([
                              TextFormField(
                                initialValue: provider.numeroSerie,
                                decoration: _buildInputDeco('No. Serie', Icons.qr_code, 'S/N de placa'),
                                onChanged: (val) => provider.updateField('numeroSerie', val),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _buildResponsiveRow([
                              TextFormField(
                                initialValue: provider.variableMedida,
                                decoration: _buildInputDeco('Variable', Icons.speed, 'Ej. Presión, Flujo'),
                                onChanged: (val) => provider.updateField('variableMedida', val),
                              ),
                              TextFormField(
                                initialValue: provider.senalEntradaSalida,
                                decoration: _buildInputDeco('Señal', Icons.settings_input_component, 'Ej. 4-20mA, Profibus'),
                                onChanged: (val) => provider.updateField('senalEntradaSalida', val),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _buildResponsiveRow([
                              TextFormField(
                                initialValue: provider.rangoLrv,
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDeco('LRV', Icons.vertical_align_bottom, 'Límite Inferior'),
                                onChanged: (val) => provider.updateField('rangoLrv', val),
                              ),
                              TextFormField(
                                initialValue: provider.rangoUrv,
                                keyboardType: TextInputType.number,
                                decoration: _buildInputDeco('URV', Icons.vertical_align_top, 'Límite Superior'),
                                onChanged: (val) => provider.updateField('rangoUrv', val),
                              ),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: config.unidades.contains(provider.unidadIngenieria) ? provider.unidadIngenieria : null,
                                decoration: _buildInputDeco('Unidad', Icons.square_foot),
                                dropdownColor: _isaSurface,
                                items: config.unidades.map((String unidadItem) {
                                  return DropdownMenuItem<String>(
                                    value: unidadItem,
                                    child: Text(unidadItem, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) provider.updateField('unidadIngenieria', val);
                                },
                              ),
                            ]),
                            if (provider.unidadIngenieria == 'Otro...') ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: provider.unidadPersonalizada,
                                decoration: _buildInputDeco('Especificar Unidad', Icons.edit, 'Ingrese la unidad de ingeniería'),
                                onChanged: (val) => provider.updateField('unidadPersonalizada', val),
                              ),
                            ],
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
                        padding: const EdgeInsets.all(16),
                        decoration: _stepContentDecoration(),
                        child: Column(
                          children: [
                            _buildResponsiveRow([
                              TextFormField(
                                initialValue: provider.supervisor,
                                readOnly: !tienePrivilegios,
                                decoration: _buildInputDeco('Supervisor / Clasificación', Icons.person, 'Encargado del equipo', !tienePrivilegios),
                                onChanged: tienePrivilegios ? (val) => provider.updateField('supervisor', val) : null,
                              ),
                            ]),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: provider.planTareas,
                              readOnly: !tienePrivilegios,
                              decoration: _buildInputDeco('Plan de Tareas', Icons.assignment, 'Ej. PLAN DE MTTO', !tienePrivilegios),
                              onChanged: tienePrivilegios ? (val) => provider.updateField('plan_tareas', val) : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: provider.observacion,
                              maxLines: 3,
                              decoration: _buildInputDeco('Observaciones de Auditoría', Icons.notes, 'Hallazgos actuales'),
                              onChanged: (val) => provider.updateField('observacion', val),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: "${provider.fechaVerificacion.day.toString().padLeft(2, '0')}/${provider.fechaVerificacion.month.toString().padLeft(2, '0')}/${provider.fechaVerificacion.year}",
                              readOnly: true,
                              decoration: _buildInputDeco('Fecha de Verificación', Icons.calendar_today, null, true),
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
                        padding: const EdgeInsets.all(16),
                        decoration: _stepContentDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildImageCapture(
                              'Foto de la Placa Técnica',
                              provider.fotoPlacaBase64,
                              provider.fotoPlacaUrlExistente, // <-- Renombrado aquí
                              () => provider.capturarFoto('placa'),
                              Icons.branding_watermark,
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: _isaDivider, height: 1),
                            const SizedBox(height: 24),
                            _buildImageCapture(
                              'Foto de la Placa Técnica 2 (Opcional)',
                              provider.fotoPlacaAdicionalBase64,
                              provider.fotoPlacaAdicionalUrlExistente, // <-- Renombrado aquí
                              () => provider.capturarFoto('placa_adicional'),
                              Icons.add_photo_alternate,
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: _isaDivider, height: 1),
                            const SizedBox(height: 24),
                            _buildImageCapture(
                              'Foto General del Equipo',
                              provider.fotoGeneralBase64,
                              provider.fotoGeneralUrlExistente, // <-- Renombrado aquí
                              () => provider.capturarFoto('general'),
                              Icons.device_hub,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              const SizedBox(height: 24),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: _progreso,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFFD9D9D9),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _estado == EstadoSubida.exito
                            ? const Color(0xFF1F5C3D)
                            : (_estado == EstadoSubida.local ? const Color(0xFFF57F17) : const Color(0xFF1F5C3D)),
                      ),
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
              const SizedBox(height: 24),
              Text(
                _estado == EstadoSubida.cargando
                    ? 'Por favor, no cierre la aplicación ni bloquee la pantalla.'
                    : (_estado == EstadoSubida.exito
                        ? 'El registro ha sido enviado exitosamente al servidor.'
                        : 'El registro se guardó en el dispositivo y se enviará cuando haya conexión.'),
                style: const TextStyle(color: Color(0xFF5F6368), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}