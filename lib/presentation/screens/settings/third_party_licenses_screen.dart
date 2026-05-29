import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/language_service.dart';

class ThirdPartyLicensesScreen extends StatelessWidget {
  const ThirdPartyLicensesScreen({super.key});

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
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
        title: const Text(
          'Licencias de Terceros',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            const Text(
              'LICENCIAS DE TERCEROS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              'CurbRadar utiliza software, bibliotecas, servicios y tecnologías de terceros para proporcionar sus funcionalidades.\n\nTodos los nombres comerciales, marcas registradas y derechos de autor pertenecen a sus respectivos propietarios.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            
            _buildLicenseSection('Google Maps Platform', 'CurbRadar utiliza Google Maps para mostrar mapas, ubicaciones y navegación.\n© Google LLC\nLos servicios de Google Maps están sujetos a los términos y políticas de Google.'),
            
            _buildLicenseSection('Firebase', 'CurbRadar utiliza Firebase para servicios de autenticación, almacenamiento de datos, análisis y notificaciones.\n© Google LLC'),
            
            _buildLicenseSection('Google Sign-In', 'CurbRadar permite iniciar sesión utilizando cuentas de Google.\n© Google LLC'),
            
            _buildLicenseSection('Apple Sign-In', 'CurbRadar permite iniciar sesión utilizando Apple ID.\n© Apple Inc.'),
            
            _buildLicenseSection('Flutter Framework', 'Esta aplicación ha sido desarrollada utilizando Flutter.\n© Google LLC\nLicencia: BSD 3-Clause License'),
            
            _buildLicenseSection('Dart', 'Lenguaje de programación utilizado para el desarrollo de la aplicación.\n© Google LLC\nLicencia: BSD 3-Clause License'),
            
            _buildLicenseSection('Open Source Software', 'CurbRadar incorpora diversas bibliotecas de código abierto bajo sus respectivas licencias.\n\nEstas licencias pueden incluir:\n• MIT License\n• Apache License 2.0\n• BSD License\n• Mozilla Public License (MPL)\n• ISC License\n\nLos derechos de autor y licencias correspondientes pertenecen a sus respectivos autores.'),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    '📜 Librerías de Código Abierto',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Para ver la lista completa de licencias de las bibliotecas utilizadas en esta aplicación, presiona el botón de abajo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => showLicensePage(
                      context: context,
                      applicationName: 'CurbRadar',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.stars_rounded, color: Color(0xFFFF8A00), size: 48),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF121212),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ver todas las licencias'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('Créditos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Agradecemos a la comunidad de software libre y a los desarrolladores de las bibliotecas utilizadas en este proyecto.', style: TextStyle(fontSize: 14, color: Colors.black87)),

            const SizedBox(height: 24),
            const Text('Contacto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchEmail('support@curbradar.tech'),
              child: const Text('Para consultas relacionadas con licencias de terceros:\nsupport@curbradar.tech', style: TextStyle(fontSize: 14, color: Colors.black87)),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }
}
