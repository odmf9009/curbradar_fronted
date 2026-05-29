import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/language_service.dart';
import '../../../core/config/routes.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail(String email, {String? subject}) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: subject != null ? {'subject': subject} : null,
    );
    try {
      // Usamos el modo ExternalApplication para forzar la apertura fuera de la app
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error lanzando email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('ayuda_soporte'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Text(
                    '🆘 Ayuda y Soporte',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '¿En qué podemos ayudarte hoy?',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Action Buttons Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildQuickActionButton(Icons.help_outline, '❓ FAQ', Colors.blue, () {}),
                _buildQuickActionButton(Icons.support_agent, '📧 Contacto', Colors.green, () => _launchEmail('support@curbradar.tech', subject: 'Soporte')),
                _buildQuickActionButton(Icons.bug_report_outlined, '🐞 Reportar Error', Colors.red, () => _launchEmail('support@curbradar.tech', subject: 'Reporte de Error')),
                _buildQuickActionButton(Icons.lightbulb_outline, '💡 Sugerencia', Colors.orange, () => _launchEmail('support@curbradar.tech', subject: 'Sugerencia')),
              ],
            ),

            const SizedBox(height: 40),
            const Text(
              'Preguntas Frecuentes (FAQ)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFAQTile(
              '¿Qué es CurbRadar?',
              'CurbRadar es una plataforma comunitaria que ayuda a encontrar objetos gratuitos y reutilizables reportados por usuarios en tiempo real.',
            ),
            _buildFAQTile(
              '¿Cómo publico un objeto?',
              '1. Presiona el botón "+".\n2. Toma una foto o selecciona una imagen.\n3. Añade una descripción.\n4. Publica la ubicación.',
            ),
            _buildFAQTile(
              '¿Cómo sé si un objeto sigue disponible?',
              'Los usuarios pueden marcar:\n✅ Sigue disponible\n🚗 Voy en camino\n❌ Ya fue recogido\n\nSin embargo, la disponibilidad nunca está garantizada.',
            ),
            _buildFAQTile(
              '¿La aplicación es gratuita?',
              'Sí. CurbRadar es gratuita. Algunas funciones avanzadas pueden formar parte de una futura suscripción Premium.',
            ),
            _buildFAQTile(
              '¿Puedo eliminar una publicación?',
              'Sí. Desde tu perfil puedes editar o eliminar tus publicaciones.',
            ),
            _buildFAQTile(
              '¿Cómo reporto contenido inapropiado?',
              'Abre la publicación y selecciona "Reportar publicación". Nuestro equipo revisará el reporte.',
            ),

            const SizedBox(height: 40),
            _buildInfoCard(
              '📧 Contacto',
              '¿Necesitas ayuda?',
              'support@curbradar.tech',
              'Tiempo de respuesta estimado:\n24-48 horas hábiles',
              const Color(0xFFE8F5E9),
              Colors.green[700]!,
              onTap: () => _launchEmail('support@curbradar.tech', subject: 'Soporte'),
            ),

            const SizedBox(height: 20),
            _buildInfoCard(
              '🐞 Reportar un Error',
              'Si encuentras un problema, incluye:\n• Modelo del teléfono\n• Versión de OS\n• Captura de pantalla',
              'support@curbradar.tech',
              'Descripción del problema',
              const Color(0xFFFFEBEE),
              Colors.red[700]!,
              onTap: () => _launchEmail('support@curbradar.tech', subject: 'Reporte de Error'),
            ),

            const SizedBox(height: 20),
            _buildInfoCard(
              '💡 Sugerir una Función',
              '¿Tienes una idea para mejorar CurbRadar?',
              'support@curbradar.tech',
              'Envíanos tus sugerencias',
              const Color(0xFFFFF3E0),
              Colors.orange[700]!,
              onTap: () => _launchEmail('support@curbradar.tech', subject: 'Sugerencia'),
            ),

            const SizedBox(height: 20),
            _buildInfoCard(
              '🔒 Seguridad',
              'Si detectas actividad sospechosa:',
              'support@curbradar.tech',
              'Problemas de seguridad',
              const Color(0xFFE3F2FD),
              Colors.blue[700]!,
              onTap: () => _launchEmail('support@curbradar.tech', subject: 'Seguridad'),
            ),

            const SizedBox(height: 40),
            const Text(
              '📄 Información Legal',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildLinkTile(context, 'Política de Privacidad', AppRoutes.privacyPolicy),
            _buildLinkTile(context, 'Términos y Condiciones', AppRoutes.terms),
            _buildLinkTile(context, 'Licencias de terceros', AppRoutes.licenses),

            const SizedBox(height: 60),
            const Center(
              child: Column(
                children: [
                  Text(
                    '❤️ Gracias por usar CurbRadar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '"Transformando las calles en oportunidades y reduciendo el desperdicio, un hallazgo a la vez." ♻️🏆',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String beforeEmail, String email, String afterEmail, Color bgColor, Color accentColor, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor),
              ),
              const SizedBox(height: 12),
              Text(
                beforeEmail,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold, 
                  color: accentColor,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                afterEmail,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, String title, String? route) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFFFF8A00))),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
    );
  }
}
