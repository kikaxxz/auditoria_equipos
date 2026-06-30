import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'equipos_aprobar_page.dart';
import 'mis_solicitudes_page.dart';
import 'manual_page.dart';
import 'admin_usuarios_page.dart';
import 'configuracion.dart';
import 'ai_assistant_modal.dart';

class DashboardDrawer extends StatelessWidget {
  final String rol;
  final bool esAprobador;

  const DashboardDrawer({super.key, required this.rol, required this.esAprobador});

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = const Color(0xFF1A1C1E),
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      leading: Icon(icon, color: color == const Color(0xFF1A1C1E) ? const Color(0xFF1F5C3D) : color, size: 26),
      title: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      hoverColor: const Color(0xFF1F5C3D).withValues(alpha: 0.05),
      splashColor: const Color(0xFF1F5C3D).withValues(alpha: 0.1),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Usuario del Sistema';
    final userEmail = user?.email ?? 'correo@ejemplo.com';
    final String rolCapitalizado = rol.isNotEmpty 
        ? '${rol[0].toUpperCase()}${rol.substring(1)}'
        : 'Desconocido';

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 32,
              left: 24,
              right: 24,
              bottom: 32,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1F5C3D),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 32, color: Color(0xFF1F5C3D), fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 0.2),
                ),
                const SizedBox(height: 6),
                Text(
                  userEmail,
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Rol: $rolCapitalizado',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
              children: [
                if (esAprobador) ...[
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('ediciones_pendientes').snapshots(),
                    builder: (context, snapshot) {
                      int pendientesCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildDrawerItem(
                        icon: Icons.fact_check_rounded,
                        text: 'Equipos por Aprobar',
                        trailing: pendientesCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC362E),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '$pendientesCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                )
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EquiposAprobarPage(rol: rol)));
                        },
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Color(0xFFEBEBEB), indent: 16, endIndent: 16),
                  ),
                ],
                if (rol == 'tecnico') ...[
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('ediciones_pendientes')
                        .where('solicitado_por', isEqualTo: userEmail)
                        .where('estado', isEqualTo: 'pendiente')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int pendientesCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return _buildDrawerItem(
                        icon: Icons.assignment_rounded,
                        text: 'Mis Solicitudes',
                        trailing: pendientesCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F5C3D),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '$pendientesCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                )
                              )
                            : null,
                        onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MisSolicitudesPage(rol: rol)));
                      },
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Color(0xFFEBEBEB), indent: 16, endIndent: 16),
                  ),
                ],
                if (rol != 'consultor') ...[
                  _buildDrawerItem(
                    icon: Icons.smart_toy_rounded,
                    text: 'Asistente Técnico IA',
                    onTap: () {
                      Navigator.pop(context);
                      AiAssistantModal.show(context);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: Color(0xFFEBEBEB), indent: 16, endIndent: 16),
                  ),
                ],
                _buildDrawerItem(
                  icon: Icons.picture_as_pdf_rounded,
                  text: 'Manual de Mantenimiento',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManualRepositoryPage()));
                  },
                ),
                if (rol == 'admin')
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings_rounded,
                    text: 'Control de Accesos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUsuariosPage()));
                    },
                  ),
                if (esAprobador)
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    text: 'Configuración del Sistema',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PanelConfiguracionPage()));
                    },
                  ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEBEBEB), height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDrawerItem(
              icon: Icons.logout_rounded,
              text: 'Cerrar Sesión',
              color: const Color(0xFFDC362E),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}