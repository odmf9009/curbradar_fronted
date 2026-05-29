import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/language_service.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Política de Privacidad',
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
              'POLÍTICA DE PRIVACIDAD DE CURBRADAR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bienvenido a CurbRadar. Su privacidad es importante para nosotros. Esta Política de Privacidad explica cómo recopilamos, utilizamos, almacenamos y protegemos su información cuando utiliza nuestra aplicación.\n\nAl utilizar CurbRadar, usted acepta las prácticas descritas en esta Política de Privacidad.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            
            _buildSection('1. INFORMACIÓN QUE RECOPILAMOS', 
              'Información proporcionada por el usuario\nPodemos recopilar:\n• Nombre de usuario\n• Dirección de correo electrónico\n• Foto de perfil (opcional)\n• Comentarios y publicaciones\n• Fotografías cargadas por el usuario\n• Mensajes enviados dentro de la plataforma\n\nInformación de ubicación\nPara proporcionar las funciones principales de CurbRadar, recopilamos:\n• Ubicación actual del dispositivo\n• Coordenadas GPS de las publicaciones\n• Historial limitado de ubicaciones relacionadas con publicaciones realizadas por el usuario\n\nLa ubicación se utiliza únicamente para mostrar objetos cercanos y mejorar la experiencia dentro de la aplicación.\n\nInformación del dispositivo\nPodemos recopilar:\n• Modelo del dispositivo\n• Sistema operativo\n• Versión de la aplicación\n• Idioma del dispositivo\n• Dirección IP\n• Identificadores del dispositivo'),

            _buildSection('2. CÓMO UTILIZAMOS LA INFORMACIÓN',
              'Utilizamos la información recopilada para:\n• Proporcionar los servicios de CurbRadar.\n• Mostrar objetos cercanos.\n• Mejorar la precisión de las publicaciones.\n• Mantener la seguridad de la plataforma.\n• Detectar actividades fraudulentas.\n• Responder solicitudes de soporte.\n• Mejorar el rendimiento y funcionalidad de la aplicación.'),

            _buildSection('3. INFORMACIÓN COMPARTIDA CON OTROS USUARIOS',
              'Cuando publica un objeto, cierta información puede ser visible para otros usuarios, incluyendo:\n• Fotografías publicadas\n• Descripción del objeto\n• Ubicación aproximada o exacta del objeto\n• Nombre de usuario\n• Fecha y hora de publicación\n\nNo compartimos públicamente su correo electrónico ni información sensible.'),

            _buildSection('4. PUBLICIDAD Y ANALÍTICAS',
              'CurbRadar podrá utilizar servicios de terceros para:\n• Analizar el uso de la aplicación.\n• Mostrar publicidad.\n• Medir el rendimiento de campañas.\n• Detectar errores.\n\nEstos proveedores pueden recopilar información de acuerdo con sus propias políticas de privacidad.'),

            _buildSection('5. ALMACENAMIENTO DE DATOS',
              'Tomamos medidas razonables para proteger la información almacenada.\nSin embargo, ningún sistema es completamente seguro y no podemos garantizar la seguridad absoluta de los datos transmitidos por Internet.'),

            _buildSection('6. RETENCIÓN DE DATOS',
              'Conservaremos la información únicamente durante el tiempo necesario para:\n• Operar la plataforma.\n• Cumplir obligaciones legales.\n• Resolver disputas.\n• Hacer cumplir nuestros términos y condiciones.'),

            _buildSection('7. ELIMINACIÓN DE CUENTA',
              'Los usuarios pueden solicitar la eliminación de su cuenta.\nAl eliminar una cuenta:\n• Se eliminará la información personal asociada.\n• Algunas publicaciones podrán mantenerse de forma anonimizada cuando sea necesario para la integridad de la plataforma.\n• Los datos podrán conservarse cuando la ley lo exija.'),

            _buildSection('8. MENORES DE EDAD',
              'CurbRadar no está dirigido a menores de 13 años. No recopilamos intencionalmente información personal de menores de 13 años. Si descubrimos que hemos recopilado información de un menor de edad sin consentimiento adecuado, eliminaremos dicha información.'),

            _buildSection('9. DERECHOS DEL USUARIO',
              'Dependiendo de su ubicación, puede tener derecho a:\n• Acceder a sus datos personales.\n• Corregir información incorrecta.\n• Solicitar la eliminación de datos.\n• Limitar el procesamiento de datos.\n• Solicitar una copia de sus datos.\n\nLas solicitudes pueden enviarse a nuestro correo de soporte.'),

            _buildSection('10. COOKIES Y TECNOLOGÍAS SIMILARES',
              'La aplicación puede utilizar tecnologías similares a cookies para:\n• Mantener sesiones activas.\n• Recordar preferencias.\n• Analizar el uso de la aplicación.\n• Mejorar la experiencia del usuario.'),

            _buildSection('11. SERVICIOS DE TERCEROS',
              'CurbRadar puede utilizar servicios externos, incluyendo:\n• Firebase\n• Google Maps\n• Google Analytics\n• Google Sign-In\n• Apple Sign-In\n• Servicios de almacenamiento en la nube\n\nCada proveedor mantiene sus propias políticas de privacidad.'),

            _buildSection('12. CAMBIOS A ESTA POLÍTICA',
              'Podemos actualizar esta Política de Privacidad ocasionalmente. Los cambios entrarán en vigor una vez publicados dentro de la aplicación o en nuestro sitio web.'),

            _buildSection('13. CONTACTO',
              'Si tiene preguntas sobre esta Política de Privacidad, puede comunicarse con nosotros:\nCorreo electrónico: support@curbradar.tech',
              onTap: () => _launchEmail('support@curbradar.tech')),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RESUMEN SIMPLE PARA LOS USUARIOS',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryItem('✅ Utilizamos tu ubicación para mostrar objetos cercanos.'),
                  _buildSummaryItem('✅ No vendemos tu información personal.'),
                  _buildSummaryItem('✅ Solo mostramos la información necesaria para que la comunidad funcione.'),
                  _buildSummaryItem('✅ Puedes solicitar la eliminación de tu cuenta y datos.'),
                  _buildSummaryItem('✅ Protegemos tu información utilizando medidas de seguridad razonables.'),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'CurbRadar existe para ayudar a las personas a encontrar y reutilizar objetos, creando comunidades más sostenibles y reduciendo el desperdicio. ♻️🌎🏆',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}
