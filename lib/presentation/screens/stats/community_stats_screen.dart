import 'package:flutter/material.dart';
import '../../../core/models/community_stats_model.dart';
import '../../../core/services/stats_service.dart';
import '../../../core/services/language_service.dart';

class CommunityStatsScreen extends StatefulWidget {
  const CommunityStatsScreen({super.key});

  @override
  State<CommunityStatsScreen> createState() => _CommunityStatsScreenState();
}

class _CommunityStatsScreenState extends State<CommunityStatsScreen> {
  final _statsService = StatsService();
  bool _isLoading = true;
  CommunityStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _statsService.getCommunityStats();
      if (mounted) setState(() { _stats = stats; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text(tr('estadisticas_comunidad'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8A00)))
              : _stats == null
                  ? const Center(child: Text('No hay datos disponibles aún.'))
                  : RefreshIndicator(
                      onRefresh: _loadStats,
                      color: const Color(0xFFFF8A00),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Resumen de Actividad'),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.3,
                              children: [
                                _buildOverviewCard('Objetos Activos',  _stats!.activeObjects.toString(),  Icons.inventory_2_outlined, Colors.blue),
                                _buildOverviewCard('Recogidos',        _stats!.totalCollected.toString(),  Icons.check_circle_outline,  Colors.green),
                                _buildOverviewCard('Usuarios Activos', _stats!.activeUsers30d.toString(), Icons.people_outline,         Colors.orange),
                                _buildOverviewCard('Publicados Hoy',   _stats!.objectsToday.toString(),   Icons.today,                 Colors.purple),
                              ],
                            ),
                            const SizedBox(height: 32),
                            if (_stats!.categoryDistribution.isNotEmpty) ...[
                              _buildSectionHeader('Categorías Populares'),
                              _buildCategoryCard(_stats!.categoryDistribution),
                              const SizedBox(height: 32),
                            ],
                            if (_stats!.hottestAreas.isNotEmpty) ...[
                              _buildSectionHeader('Zonas con más Tesoros'),
                              ..._stats!.hottestAreas.map(_buildAreaTile),
                              const SizedBox(height: 32),
                            ],
                            _buildSectionHeader('Impacto Ecológico'),
                            _buildImpactSection(_stats!.environmentalImpact),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF121212))),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, double> distribution) {
    final sorted = distribution.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: sorted.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${entry.value.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: entry.value / 100,
                backgroundColor: Colors.grey[100],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8A00)),
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildAreaTile(AreaActivity area) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(area.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('${area.objectCount} objetos reportados', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSection(EnvironmentalImpact impact) {
    return Column(
      children: [
        _buildImpactCard('Objetos Recuperados',        '${impact.objectsRecovered}',             '♻️', 'Evitamos que terminen en vertederos'),
        const SizedBox(height: 12),
        _buildImpactCard('Peso Estimado Reciclado',    '${impact.estimatedWeightKg.toInt()} kg', '⚖️', 'Basado en 15 kg por objeto promedio'),
        const SizedBox(height: 12),
        _buildImpactCard('Emisiones CO₂ Evitadas',     '${impact.co2SavedKg.toInt()} kg',       '🌎', 'Ahorro estimado en producción nueva'),
      ],
    );
  }

  Widget _buildImpactCard(String title, String value, String emoji, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green[600]!, Colors.green[800]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
