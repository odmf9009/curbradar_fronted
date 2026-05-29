import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/language_service.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
        title: Text(
          tr('terminos_condiciones'),
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
            const Text(
              'TÉRMINOS Y CONDICIONES DE CURBRADAR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _buildSection(
              '1. DESCRIPCIÓN DEL SERVICIO',
              'CurbRadar es una plataforma comunitaria que permite a los usuarios compartir información sobre objetos observados en calles, aceras, bordes de carretera (curbs) y otras áreas accesibles al público para facilitar su localización y posible reutilización.\n\nCurbRadar actúa únicamente como una plataforma de información y no participa en la venta, compra, almacenamiento, transporte o transferencia de objetos.',
            ),
            _buildSection(
              '2. NO PROPIEDAD DE LOS OBJETOS',
              'CurbRadar no es propietario de ninguno de los objetos publicados dentro de la aplicación.\n\nTodos los objetos, fotografías, ubicaciones y descripciones son proporcionados por los usuarios de la comunidad.\n\nCurbRadar no garantiza la existencia, propiedad, disponibilidad, calidad, estado o legalidad de ningún objeto publicado.',
            ),
            _buildSection(
              '3. DISPONIBILIDAD NO GARANTIZADA',
              'Los objetos mostrados en la aplicación pueden haber sido retirados, recogidos, vendidos, movidos o eliminados antes de que otro usuario llegue al lugar.\n\nCurbRadar no garantiza que un objeto continúe disponible en el momento de su visita.',
            ),
            _buildSection(
              '4. RESPONSABILIDAD DEL USUARIO',
              'El usuario es el único responsable de:\n\n• Verificar la disponibilidad del objeto.\n• Evaluar el estado y seguridad del objeto.\n• Cumplir con todas las leyes locales aplicables.\n• Determinar si puede recoger legalmente el objeto.\n\nToda acción realizada por el usuario fuera de la aplicación será bajo su exclusiva responsabilidad.',
            ),
            _buildSection(
              '5. PROPIEDAD PRIVADA',
              'Los usuarios no deben ingresar a propiedades privadas sin autorización expresa del propietario.\n\nCurbRadar no autoriza ni promueve el acceso no autorizado a terrenos, viviendas, negocios o cualquier propiedad privada.\n\nLos usuarios deben respetar todas las leyes locales relacionadas con la propiedad privada y el acceso a espacios restringidos.',
            ),
            _buildSection(
              '6. SEGURIDAD',
              'Los usuarios reconocen que la recogida, transporte o manipulación de objetos puede implicar riesgos.\n\nCurbRadar no será responsable por:\n\n• Accidentes.\n• Lesiones personales.\n• Daños a vehículos.\n• Daños a propiedades.\n• Enfermedades.\n• Pérdidas económicas.\n\nEl usuario asume todos los riesgos asociados con el uso de la información proporcionada por la aplicación.',
            ),
            _buildSection(
              '7. CONTENIDO GENERADO POR LOS USUARIOS',
              'Cada usuario es responsable de todo el contenido que publique dentro de la aplicación, incluyendo:\n\n• Fotografías.\n• Comentarios.\n• Ubicaciones.\n• Descripciones.\n• Mensajes.\n\nCurbRadar no garantiza la exactitud, integridad o veracidad del contenido publicado por terceros.',
            ),
            _buildSection(
              '8. CONDUCTA PROHIBIDA',
              'Está prohibido utilizar CurbRadar para:\n\n• Publicar contenido falso o engañoso.\n• Publicar armas o municiones.\n• Publicar drogas o sustancias ilegales.\n• Publicar materiales peligrosos.\n• Realizar actividades fraudulentas.\n• Acosar a otros usuarios.\n• Suplantar identidades.\n• Distribuir spam.\n• Compartir contenido ofensivo o ilegal.\n\nCurbRadar podrá suspender o eliminar cuentas que incumplan estas normas sin previo aviso.',
            ),
            _buildSection(
              '9. GEOLOCALIZACIÓN',
              'La aplicación utiliza servicios de ubicación para mostrar objetos cercanos y mejorar la experiencia del usuario.\n\nAl utilizar CurbRadar, el usuario acepta el uso de servicios de geolocalización de acuerdo con la Política de Privacidad de la aplicación.',
            ),
            _buildSection(
              '10. LIMITACIÓN DE RESPONSABILIDAD',
              'CurbRadar se proporciona "tal cual" y "según disponibilidad".\n\nEn la máxima medida permitida por la ley, CurbRadar, sus propietarios, desarrolladores, empleados y afiliados no serán responsables por:\n\n• Información incorrecta.\n• Objetos inexistentes.\n• Objetos retirados.\n• Daños personales.\n• Daños materiales.\n• Pérdidas económicas.\n• Disputas entre usuarios.\n• Actividades de terceros.',
            ),
            _buildSection(
              '11. PROPIEDAD INTELECTUAL',
              'Todos los derechos relacionados con el nombre CurbRadar, logotipos, diseño, software, código fuente y contenido propio de la plataforma pertenecen a CurbRadar y están protegidos por las leyes aplicables de propiedad intelectual.',
            ),
            _buildSection(
              '12. TERMINACIÓN DE CUENTAS',
              'CurbRadar podrá suspender, restringir o eliminar cualquier cuenta que:\n\n• Incumpla estos términos.\n• Realice actividades fraudulentas.\n• Perjudique a otros usuarios.\n• Comprometa la seguridad de la plataforma.',
            ),
            _buildSection(
              '13. MODIFICACIONES DEL SERVICIO',
              'CurbRadar podrá modificar, suspender o eliminar funciones de la aplicación en cualquier momento y sin previo aviso.',
            ),
            _buildSection(
              '14. CAMBIOS A LOS TÉRMINOS',
              'CurbRadar podrá actualizar estos Términos y Condiciones periódicamente.\n\nEl uso continuado de la aplicación después de cualquier modificación constituirá la aceptación de los nuevos términos.',
            ),
            _buildSection(
              '15. LEY APLICABLE',
              'Estos Términos y Condiciones se regirán e interpretarán de acuerdo con las leyes del Estado de Florida, Estados Unidos, sin consideración a conflictos de principios legales.',
            ),
            _buildSection(
              '16. CONTACTO',
              'Para preguntas relacionadas con estos Términos y Condiciones, puede contactarnos en:\n\nEmail: support@curbradar.tech',
              onTap: () => _launchEmail('support@curbradar.tech'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CLÁUSULA ESPECIAL DE CURBRADAR',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'CurbRadar es una plataforma comunitaria de información. La publicación de un objeto dentro de la aplicación no constituye una oferta de venta, cesión, transferencia de propiedad ni garantía de disponibilidad. Los usuarios utilizan la información mostrada bajo su propio riesgo y criterio, siendo responsables de verificar la legalidad, seguridad y accesibilidad de cualquier objeto reportado.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
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
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
