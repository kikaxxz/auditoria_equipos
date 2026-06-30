import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class Manual {
  final String id;
  final String titulo;
  final String ruta;

  Manual({required this.id, required this.titulo, required this.ruta});
}

class ManualRepositoryPage extends StatefulWidget {
  const ManualRepositoryPage({super.key});

  @override
  State<ManualRepositoryPage> createState() => _ManualRepositoryPageState();
}

class _ManualRepositoryPageState extends State<ManualRepositoryPage> {
  final List<Manual> _manuales = [
  Manual(
    id: 'IM-AYC-ANA-001_Mantenimiento_Preventivo_Manometro_Analogico_Version_1.0',
    titulo: 'Manual IM-AYC-ANA-001_Mantenimiento_Preventivo_Manometro_Analogico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANA-001_Mantenimiento_Preventivo_Manometro_Analogico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANA-002_Mantenimiento_Preventivo_Termometro_Analogico_Version_1.0',
    titulo: 'Manual IM-AYC-ANA-002_Mantenimiento_Preventivo_Termometro_Analogico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANA-002_Mantenimiento_Preventivo_Termometro_Analogico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANA-003_Mantenimiento_Preventivo_Vacuometro_Analogico_Version_1.0',
    titulo: 'Manual IM-AYC-ANA-003_Mantenimiento_Preventivo_Vacuometro_Analogico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANA-003_Mantenimiento_Preventivo_Vacuometro_Analogico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANA-004_Mantenimiento_Preventivo_Rotametro_Analogico_Version_1.0',
    titulo: 'Manual IM-AYC-ANA-004_Mantenimiento_Preventivo_Rotametro_Analogico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANA-004_Mantenimiento_Preventivo_Rotametro_Analogico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANA-005_Mantenimiento_Preventivo_Placa_Orificio_Version_1.0',
    titulo: 'Manual IM-AYC-ANA-005_Mantenimiento_Preventivo_Placa_Orificio_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANA-005_Mantenimiento_Preventivo_Placa_Orificio_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANAQ-001_Mantenimiento_Preventivo_Transmisor_PH_Version_1.0',
    titulo: 'Manual IM-AYC-ANAQ-001_Mantenimiento_Preventivo_Transmisor_PH_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANAQ-001_Mantenimiento_Preventivo_Transmisor_PH_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANAQ-002_Mantenimiento_Preventiva_Transmisor_Conductividad_Version_1.0',
    titulo: 'Manual IM-AYC-ANAQ-002_Mantenimiento_Preventiva_Transmisor_Conductividad_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANAQ-002_Mantenimiento_Preventiva_Transmisor_Conductividad_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANAQ-003_Mantenimiento_Preventivo_Transmisor_Brix_Version_1.0',
    titulo: 'Manual IM-AYC-ANAQ-003_Mantenimiento_Preventivo_Transmisor_Brix_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANAQ-003_Mantenimiento_Preventivo_Transmisor_Brix_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANAQ-004_Mantenimiento_Preventivo_Celda_Oxigeno_Version_1.0',
    titulo: 'Manual IM-AYC-ANAQ-004_Mantenimiento_Preventivo_Celda_Oxigeno_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANAQ-004_Mantenimiento_Preventivo_Celda_Oxigeno_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANAQ-005_Mantenimiento_Preventivo_Controlador_Oxigeno_Version_1.0',
    titulo: 'Manual IM-AYC-ANAQ-005_Mantenimiento_Preventivo_Controlador_Oxigeno_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANAQ-005_Mantenimiento_Preventivo_Controlador_Oxigeno_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANAQ-006_Mantenimiento_Preventivo_Refractometro_Version_1.0',
    titulo: 'Manual IM-AYC-ANAQ-006_Mantenimiento_Preventivo_Refractometro_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANAQ-006_Mantenimiento_Preventivo_Refractometro_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANAQ-007_Mantenimiento_Preventivo_Transmisor_NIR_Version_1.0',
    titulo: 'Manual IM-AYC-ANAQ-007_Mantenimiento_Preventivo_Transmisor_NIR_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANAQ-007_Mantenimiento_Preventivo_Transmisor_NIR_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ANAQ-008_Mantenimiento_Preventivo_Transmisor_Densidad_Version_1.0',
    titulo: 'Manual IM-AYC-ANAQ-008_Mantenimiento_Preventivo_Transmisor_Densidad_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ANAQ-008_Mantenimiento_Preventivo_Transmisor_Densidad_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-COM-001_Mantenimiento_Preventivo_Radiocontrol_Version_1.0',
    titulo: 'Manual IM-AYC-COM-001_Mantenimiento_Preventivo_Radiocontrol_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-COM-001_Mantenimiento_Preventivo_Radiocontrol_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-COM-002_Mantenimiento_Preventivo_Fibra_Optica_Version_1.0',
    titulo: 'Manual IM-AYC-COM-002_Mantenimiento_Preventivo_Fibra_Optica_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-COM-002_Mantenimiento_Preventivo_Fibra_Optica_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-CTL-001_Mantenimiento_Preventivo_Controlador_Version_1.0',
    titulo: 'Manual IM-AYC-CTL-001_Mantenimiento_Preventivo_Controlador_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-CTL-001_Mantenimiento_Preventivo_Controlador_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ESP-001_Mantenimiento_Preventivo_Estacion_AM_Version_1.0',
    titulo: 'Manual IM-AYC-ESP-001_Mantenimiento_Preventivo_Estacion_AM_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ESP-001_Mantenimiento_Preventivo_Estacion_AM_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ESP-002_Mantenimiento_Preventivo_Recinto_Caja_Instrumentacion_Version_1.0',
    titulo: 'Manual IM-AYC-ESP-002_Mantenimiento_Preventivo_Recinto_Caja_Instrumentacion_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ESP-002_Mantenimiento_Preventivo_Recinto_Caja_Instrumentacion_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-ESP-005_Mantenimiento_Preventivo_Atemperador_Mecanico_Version_1.0',
    titulo: 'Manual IM-AYC-ESP-005_Mantenimiento_Preventivo_Atemperador_Mecanico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-ESP-005_Mantenimiento_Preventivo_Atemperador_Mecanico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-FIL-001_Mantenimiento_Preventivo_Filtro_Malla_Version_1.0',
    titulo: 'Manual IM-AYC-FIL-001_Mantenimiento_Preventivo_Filtro_Malla_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-FIL-001_Mantenimiento_Preventivo_Filtro_Malla_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-FLU-001_Mantenimiento_Preventivo_Tubo_Pitot_Version_1.0',
    titulo: 'Manual IM-AYC-FLU-001_Mantenimiento_Preventivo_Tubo_Pitot_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-FLU-001_Mantenimiento_Preventivo_Tubo_Pitot_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-FLU-002_Mantenimiento_Preventivo_Tubo_Venturi_Version_1.0',
    titulo: 'Manual IM-AYC-FLU-002_Mantenimiento_Preventivo_Tubo_Venturi_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-FLU-002_Mantenimiento_Preventivo_Tubo_Venturi_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-GAB-001_Mantenimiento_Preventivo_Gabinete_Control_Version_1.0',
    titulo: 'Manual IM-AYC-GAB-001_Mantenimiento_Preventivo_Gabinete_Control_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-GAB-001_Mantenimiento_Preventivo_Gabinete_Control_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-GAB-002_Mantenimiento_Preventivo_Gabinete_Comunicaciones_Version_1.0',
    titulo: 'Manual IM-AYC-GAB-002_Mantenimiento_Preventivo_Gabinete_Comunicaciones_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-GAB-002_Mantenimiento_Preventivo_Gabinete_Comunicaciones_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-GAB-003_Mantenimiento_Preventivo_Gabinete_Electrovalvulas_Version_1.0',
    titulo: 'Manual IM-AYC-GAB-003_Mantenimiento_Preventivo_Gabinete_Electrovalvulas_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-GAB-003_Mantenimiento_Preventivo_Gabinete_Electrovalvulas_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-GAB-004_Mantenimiento_Preventivo_Gabinete_Respaldo_Energetico_Version_1.0',
    titulo: 'Manual IM-AYC-GAB-004_Mantenimiento_Preventivo_Gabinete_Respaldo_Energetico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-GAB-004_Mantenimiento_Preventivo_Gabinete_Respaldo_Energetico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-MEC-001_Mantenimiento_Preventivo_Chute_Version_1.0',
    titulo: 'Manual IM-AYC-MEC-001_Mantenimiento_Preventivo_Chute_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-MEC-001_Mantenimiento_Preventivo_Chute_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-MEC-002_Mantenimiento_Preventivo_Mordaza_Version_1.0',
    titulo: 'Manual IM-AYC-MEC-002_Mantenimiento_Preventivo_Mordaza_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-MEC-002_Mantenimiento_Preventivo_Mordaza_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-MEC-003_Mantenimiento_Preventivo_Ducto_Version_1.0',
    titulo: 'Manual IM-AYC-MEC-003_Mantenimiento_Preventivo_Ducto_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-MEC-003_Mantenimiento_Preventivo_Ducto_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-MOT-001_Mantenimiento_Preventivo_Servomotor_Version_1.0',
    titulo: 'Manual IM-AYC-MOT-001_Mantenimiento_Preventivo_Servomotor_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-MOT-001_Mantenimiento_Preventivo_Servomotor_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-NEU-001_Mantenimiento_Preventivo_Cilindro_Neumatico_Version_1.0',
    titulo: 'Manual IM-AYC-NEU-001_Mantenimiento_Preventivo_Cilindro_Neumatico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-NEU-001_Mantenimiento_Preventivo_Cilindro_Neumatico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-NEU-002_Mantenimiento_Preventivo_Inflador_Neumatico_Version_1.0',
    titulo: 'Manual IM-AYC-NEU-002_Mantenimiento_Preventivo_Inflador_Neumatico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-NEU-002_Mantenimiento_Preventivo_Inflador_Neumatico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-NIV-001_Mantenimiento_Preventivo_Transmisor_Radar_Radar_Guiado_Version_1.0',
    titulo: 'Manual IM-AYC-NIV-001_Mantenimiento_Preventivo_Transmisor_Radar_Radar_Guiado_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-NIV-001_Mantenimiento_Preventivo_Transmisor_Radar_Radar_Guiado_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-NIV-002_Mantenimiento_Preventivo_Interruptor_Nivel_Version_1.0',
    titulo: 'Manual IM-AYC-NIV-002_Mantenimiento_Preventivo_Interruptor_Nivel_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-NIV-002_Mantenimiento_Preventivo_Interruptor_Nivel_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-NIV-003_Mantenimiento_Preventivo_Nivel_Electronico_Version_1.0',
    titulo: 'Manual IM-AYC-NIV-003_Mantenimiento_Preventivo_Nivel_Electronico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-NIV-003_Mantenimiento_Preventivo_Nivel_Electronico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-NIV-004_Mantenimiento_Preventivo_Nivel_Mecanico_Version_1.0',
    titulo: 'Manual IM-AYC-NIV-004_Mantenimiento_Preventivo_Nivel_Mecanico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-NIV-004_Mantenimiento_Preventivo_Nivel_Mecanico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-NIV-005_Mantenimiento_Preventivo_Transmisor_Nivel_Version_1.0',
    titulo: 'Manual IM-AYC-NIV-005_Mantenimiento_Preventivo_Transmisor_Nivel_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-NIV-005_Mantenimiento_Preventivo_Transmisor_Nivel_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-NIV-006_Mantenimiento_Preventivo_Sensor_Nivel_Version_1.0',
    titulo: 'Manual IM-AYC-NIV-006_Mantenimiento_Preventivo_Sensor_Nivel_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-NIV-006_Mantenimiento_Preventivo_Sensor_Nivel_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-PES-001_Mantenimiento_Preventivo_Caja_Sumadora_Version_1.0',
    titulo: 'Manual IM-AYC-PES-001_Mantenimiento_Preventivo_Caja_Sumadora_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-PES-001_Mantenimiento_Preventivo_Caja_Sumadora_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-PES-002_Mantenimiento_Preventivo_Celda_Carga_Version_1.0',
    titulo: 'Manual IM-AYC-PES-002_Mantenimiento_Preventivo_Celda_Carga_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-PES-002_Mantenimiento_Preventivo_Celda_Carga_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SEN-001_Mantenimiento_Preventivo_Sensor_Inductivo_Version_1.0',
    titulo: 'Manual IM-AYC-SEN-001_Mantenimiento_Preventivo_Sensor_Inductivo_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SEN-001_Mantenimiento_Preventivo_Sensor_Inductivo_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SEN-002_Mantenimiento_Preventivo_Sensor_Capacitivo_Version_1.0',
    titulo: 'Manual IM-AYC-SEN-002_Mantenimiento_Preventivo_Sensor_Capacitivo_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SEN-002_Mantenimiento_Preventivo_Sensor_Capacitivo_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SEN-003_Mantenimiento_Preventivo_Sensor_Fotoelectrico_Version_1.0',
    titulo: 'Manual IM-AYC-SEN-003_Mantenimiento_Preventivo_Sensor_Fotoelectrico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SEN-003_Mantenimiento_Preventivo_Sensor_Fotoelectrico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SEN-004_Mantenimiento_Preventivo_Encoder_Rotativo_Version_1.0',
    titulo: 'Manual IM-AYC-SEN-004_Mantenimiento_Preventivo_Encoder_Rotativo_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SEN-004_Mantenimiento_Preventivo_Encoder_Rotativo_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SEN-005_MantenimientoPreventivo_Acelerometro_Medicion_Vibracion_Version_1.0',
    titulo: 'Manual IM-AYC-SEN-005_MantenimientoPreventivo_Acelerometro_Medicion_Vibracion_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SEN-005_MantenimientoPreventivo_Acelerometro_Medicion_Vibracion_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SEN-006_Mantenimiento_Preventivo_Sensor_Neumatico_Version_1.0',
    titulo: 'Manual IM-AYC-SEN-006_Mantenimiento_Preventivo_Sensor_Neumatico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SEN-006_Mantenimiento_Preventivo_Sensor_Neumatico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SEN-007_Mantenimiento_Preventivo_Sensor_RTD_Version_1.0',
    titulo: 'Manual IM-AYC-SEN-007_Mantenimiento_Preventivo_Sensor_RTD_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SEN-007_Mantenimiento_Preventivo_Sensor_RTD_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SEN-008_Mantenimiento_Preventivo_Sensor_Desplazamiento_Axial_Version_1.0',
    titulo: 'Manual IM-AYC-SEN-008_Mantenimiento_Preventivo_Sensor_Desplazamiento_Axial_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SEN-008_Mantenimiento_Preventivo_Sensor_Desplazamiento_Axial_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SEN-009_Mantenimiento_Preventivo_Sensor_Expansion_Diferencial_Version_1.0',
    titulo: 'Manual IM-AYC-SEN-009_Mantenimiento_Preventivo_Sensor_Expansion_Diferencial_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SEN-009_Mantenimiento_Preventivo_Sensor_Expansion_Diferencial_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SEN-010_Mantenimiento_Preventivo_Pedal_Sensor_Accionamiento_Version_1.0',
    titulo: 'Manual IM-AYC-SEN-010_Mantenimiento_Preventivo_Pedal_Sensor_Accionamiento_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SEN-010_Mantenimiento_Preventivo_Pedal_Sensor_Accionamiento_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SIG-001_Mantenimiento_Preventivo_Convertidor_Senal_Version_1.0',
    titulo: 'Manual IM-AYC-SIG-001_Mantenimiento_Preventivo_Convertidor_Senal_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SIG-001_Mantenimiento_Preventivo_Convertidor_Senal_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SIG-002_Mantenimiento_Preventivo_Amplificador_Senal_Version_1.0',
    titulo: 'Manual IM-AYC-SIG-002_Mantenimiento_Preventivo_Amplificador_Senal_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SIG-002_Mantenimiento_Preventivo_Amplificador_Senal_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SIS-001_Mantenimiento_Preventivo_Estacion_Trabajo_Servidor_Version_1.0',
    titulo: 'Manual IM-AYC-SIS-001_Mantenimiento_Preventivo_Estacion_Trabajo_Servidor_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SIS-001_Mantenimiento_Preventivo_Estacion_Trabajo_Servidor_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SIS-002_Mantenimiento_Preventivo_Sistema_Monitoreo_Camaras_Version_1.0',
    titulo: 'Manual IM-AYC-SIS-002_Mantenimiento_Preventivo_Sistema_Monitoreo_Camaras_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SIS-002_Mantenimiento_Preventivo_Sistema_Monitoreo_Camaras_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SIS-003_Mantenimiento_Preventivo_Sistema_Respaldo_Energetico_Version_1.0',
    titulo: 'Manual IM-AYC-SIS-003_Mantenimiento_Preventivo_Sistema_Respaldo_Energetico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SIS-003_Mantenimiento_Preventivo_Sistema_Respaldo_Energetico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-SIS-004_Mantenimiento_Preventivo_Registrador_Version_1.0',
    titulo: 'Manual IM-AYC-SIS-004_Mantenimiento_Preventivo_Registrador_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-SIS-004_Mantenimiento_Preventivo_Registrador_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-TRA-001_Mantenimiento_Preventivo_Transmisor_Presion_Manometrica_Version_1.0',
    titulo: 'Manual IM-AYC-TRA-001_Mantenimiento_Preventivo_Transmisor_Presion_Manometrica_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-TRA-001_Mantenimiento_Preventivo_Transmisor_Presion_Manometrica_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-TRA-002_Mantenimiento_Preventivo_Transmisor_Temperatura_Version_1.0',
    titulo: 'Manual IM-AYC-TRA-002_Mantenimiento_Preventivo_Transmisor_Temperatura_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-TRA-002_Mantenimiento_Preventivo_Transmisor_Temperatura_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-TRA-003_Mantenimiento_Preventivo_Transmisor_Flujo_Magnetico_Version_1.0',
    titulo: 'Manual IM-AYC-TRA-003_Mantenimiento_Preventivo_Transmisor_Flujo_Magnetico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-TRA-003_Mantenimiento_Preventivo_Transmisor_Flujo_Magnetico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-TRA-004_Mantenimiento_Preventivo_Transmisor_Flujo_Masico_Version_1.0',
    titulo: 'Manual IM-AYC-TRA-004_Mantenimiento_Preventivo_Transmisor_Flujo_Masico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-TRA-004_Mantenimiento_Preventivo_Transmisor_Flujo_Masico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-TRA-005_Mantenimiento_Preventivo_Transmisor_Flujo_Volumetrico_Version_1.0',
    titulo: 'Manual IM-AYC-TRA-005_Mantenimiento_Preventivo_Transmisor_Flujo_Volumetrico_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-TRA-005_Mantenimiento_Preventivo_Transmisor_Flujo_Volumetrico_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-TRA-006_Mantenimiento_Preventivo_Transmisor_Presion_Diferencial_Version_1.0',
    titulo: 'Manual IM-AYC-TRA-006_Mantenimiento_Preventivo_Transmisor_Presion_Diferencial_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-TRA-006_Mantenimiento_Preventivo_Transmisor_Presion_Diferencial_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-TRA-007_Mantenimiento_Preventivo_transmisor_presión_absoluta_Version_1.0',
    titulo: 'Manual IM-AYC-TRA-007_Mantenimiento_Preventivo_transmisor_presión_absoluta_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-TRA-007_Mantenimiento_Preventivo_transmisor_presi%C3%B3n_absoluta_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-VAL-001_Mantenimiento_Preventivo_Valvula_Control_Version_1.0',
    titulo: 'Manual IM-AYC-VAL-001_Mantenimiento_Preventivo_Valvula_Control_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-VAL-001_Mantenimiento_Preventivo_Valvula_Control_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-VAL-003_Mantenimiento_Preventivo_Valvula_Globo_Version_1.0',
    titulo: 'Manual IM-AYC-VAL-003_Mantenimiento_Preventivo_Valvula_Globo_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-VAL-003_Mantenimiento_Preventivo_Valvula_Globo_Version_1.0.pdf'
  ),
  Manual(
    id: 'IM-AYC-VAL-004_Mantenimiento_Preventivo_Valvula_Electrica_Version_1.0',
    titulo: 'Manual IM-AYC-VAL-004_Mantenimiento_Preventivo_Valvula_Electrica_Version_1.0',
    ruta: 'https://auditoria-equipos-pwa.web.app/manuales/IM-AYC-VAL-004_Mantenimiento_Preventivo_Valvula_Electrica_Version_1.0.pdf'
  ),
];

  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final manualesFiltrados = _manuales.where((m) =>
        m.titulo.toLowerCase().contains(_busqueda.toLowerCase()) ||
        m.id.toLowerCase().contains(_busqueda.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F5C3D),
        title: const Text('Repositorio de Manuales', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por código o equipo...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (valor) {
                setState(() {
                  _busqueda = valor;
                });
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: manualesFiltrados.length,
              itemBuilder: (context, index) {
                final manual = manualesFiltrados[index];

                List<String> partes = manual.id.split('_');
                String codigo = partes.isNotEmpty ? partes[0] : manual.id;
                
                String equipo = manual.id
                    .replaceAll(codigo, '')
                    .replaceAll(RegExp(r'_Mantenimiento_Preventiv[oa]_'), '')
                    .replaceAll(RegExp(r'_Version_\d\.\d'), '')
                    .replaceAll('_', ' ')
                    .trim();
                
                if (equipo.isEmpty) equipo = 'Equipo General';

                RegExp regexVersion = RegExp(r'Version_\d\.\d');
                var match = regexVersion.firstMatch(manual.id);
                String version = match != null ? match.group(0)!.replaceAll('_', ' ') : 'Version 1.0';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManualViewerPage(
                          titulo: equipo,
                          rutaPdf: manual.ruta,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2C2C2C)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F5C3D).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            codigo,
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Center(
                          child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF1F5C3D), size: 36),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          equipo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.2,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          version,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

class ManualViewerPage extends StatefulWidget {
  final String titulo;
  final String rutaPdf;
  final int? paginaInicial;

  const ManualViewerPage({
    super.key,
    required this.titulo,
    required this.rutaPdf,
    this.paginaInicial,
  });

  @override
  State<ManualViewerPage> createState() => _ManualViewerPageState();
}

class _ManualViewerPageState extends State<ManualViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  
  bool _isSearching = false;
  bool _isLoadingSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
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
                  enabled: !_isLoadingSearch,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: _isLoadingSearch ? 'Buscando...' : 'Buscar en documento...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                    await Future.delayed(const Duration(milliseconds: 50));

                    _searchResult = _pdfViewerController.searchText(text);

                    if (!context.mounted) return;

                    setState(() {
                      _isLoadingSearch = false;
                    });

                    if (_searchResult.totalInstanceCount == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No se encontraron coincidencias.')),
                      );
                    }
                  },
                ),
              )
            : Text(widget.titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: const Color(0xFF1F5C3D),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: !_isSearching,
        actions: [
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
      body: SfPdfViewer.network(
        widget.rutaPdf,
        controller: _pdfViewerController,
        canShowScrollHead: false,
        canShowScrollStatus: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          if (widget.paginaInicial != null) {
            int totalPaginas = details.document.pages.count;
            if (widget.paginaInicial! > 0 && widget.paginaInicial! <= totalPaginas) {
              _pdfViewerController.jumpToPage(widget.paginaInicial!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('La página ${widget.paginaInicial} citada no coincide con la longitud del documento actual.'),
                  backgroundColor: const Color(0xFFDC362E),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),