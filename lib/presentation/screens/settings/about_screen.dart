import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/language_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/config/routes.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await ApiService().get(ApiConfig.stats);
      if (mounted) setState(() {
        _stats = Map<String, dynamic>.from(response.data);
        _loadingStats = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _launchEmail(String email, {String? subject}) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: subject != null ? {'subject': subject} : null,
    );
    try {
      await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error lanzando email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('acerca_de'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF121212),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFFF8A00), size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Treasure Hunter Community',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  const Text('CurbRadar', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    'Encuentra tesoros ocultos cerca de ti',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🚀 ¿Qué es CurbRadar?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                    'CurbRadar es una plataforma comunitaria que ayuda a las personas a descubrir objetos gratuitos y reutilizables que han sido colocados en calles, aceras y vecindarios.\n\nNuestra misión es reducir el desperdicio, fomentar la reutilización y conectar a las personas con oportunidades que normalmente pasarían desapercibidas.',
                    style: TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionCard(
                    '🌎 Nuestra Misión',
                    'Dar una segunda vida a los objetos y ayudar a las comunidades a compartir recursos de forma rápida, sencilla y gratuita.',
                    Colors.blue.withOpacity(0.1),
                    Colors.blue,
                  ),

                  const SizedBox(height: 32),
                  const Text('♻️ Cómo Funciona', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildStep(1, 'Encuentra un objeto en la calle.'),
                  _buildStep(2, 'Toma una foto y publícala.'),
                  _buildStep(3, 'Otros usuarios la verán en el mapa.'),
                  _buildStep(4, 'Alguien puede recogerlo antes de que termine en la basura.'),

                  const SizedBox(height: 32),
                  const Text('🏆 Estadísticas de la Comunidad',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_loadingStats)
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(color: Color(0xFFFF8A00)),
                    ))
                  else if (stats != null)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildStatItem('📦',
                                stats['totalObjectsPosted'].toString(), 'Publicados')),
                            Expanded(child: _buildStatItem('♻️',
                                stats['totalObjectsReused'].toString(), 'Reutilizados')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildStatItem('👥',
                                stats['totalUsers'].toString(), 'Usuarios')),
                            Expanded(child: _buildStatItem('🌎',
                                stats['totalCities'].toString(), 'Ciudades')),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),
                  const Text('🎯 ¿Por qué usar CurbRadar?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildBulletPoint('Encuentra objetos gratis cerca de ti'),
                  _buildBulletPoint('Reduce el desperdicio'),
                  _buildBulletPoint('Ayuda al medio ambiente'),
                  _buildBulletPoint('Descubre oportunidades únicas'),
                  _buildBulletPoint('Forma parte de una comunidad activa'),

                  const SizedBox(height: 40),
                  const Center(
                    child: Column(
                      children: [
                        Text('⭐ Versión', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Versión: 1.0.0', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('🔗 Enlaces', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildLink(context, 'Política de Privacidad',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy)),
                  _buildLink(context, 'Términos y Condiciones',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.terms)),
                  _buildLink(context, 'Soporte',
                      onTap: () => _launchEmail('support@curbradar.tech', subject: 'Soporte')),
                  _buildLink(context, 'Reportar un problema',
                      onTap: () => _launchEmail('support@curbradar.tech', subject: 'Reporte de problema')),
                  _buildLink(context, 'Contacto',
                      onTap: () => _launchEmail('support@curbradar.tech', subject: 'Contacto')),

                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: const Column(
                      children: [
                        Text('❤️ Hecho para la comunidad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 12),
                        Text(
                          '"CurbRadar transforma las calles en oportunidades. Lo que alguien ya no necesita puede convertirse en el próximo tesoro de otra persona."',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      '"Turn every street into a treasure hunt."',
                      style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, String content, Color bgColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentColor)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(color: Color(0xFF121212), shape: BoxShape.circle),
            child: Center(child: Text(number.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFFFF8A00), size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLink(BuildContext context, String title, {required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFFFF8A00))),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFFFF8A00)),
      onTap: onTap,
    );
  }
}
