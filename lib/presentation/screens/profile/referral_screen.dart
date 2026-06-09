import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/referral_service.dart';
import '../../../core/services/users_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/models/user_model.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _referralService = ReferralService();
  final _usersService = UsersService();

  bool _isLoading = true;
  UserModel? _user;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _usersService.getMyProfile(),
        _referralService.getReferralHistory(),
      ]);
      if (mounted) {
        setState(() {
          _user    = results[0] as UserModel?;
          _history = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareCode(String code) {
    Share.share('¡Únete a CurbRadar y descubre tesoros gratis! Usa mi código: $code\nhttps://curbradar.tech');
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Código copiado!')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(tr('referidos'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsGrid(),
                            const SizedBox(height: 32),
                            const Text('Historial de Referidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildHistory(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final code = _user?.referralCode ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const Icon(Icons.group_add_outlined, size: 64, color: Color(0xFFFF8A00)),
          const SizedBox(height: 16),
          const Text('Invita Amigos y Gana XP', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Comparte tu código y gana premios cuando tus amigos se unan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF8A00).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text('TU CÓDIGO DE REFERIDO', style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(code.isNotEmpty ? code : '---', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(width: 12),
                    if (code.isNotEmpty)
                      IconButton(
                        onPressed: () => _copyCode(code),
                        icon: const Icon(Icons.copy, color: Colors.grey, size: 20),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (code.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _shareCode(code),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('COMPARTIR CÓDIGO', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Invitados', _user?.referralCount.toString() ?? '0', Icons.people_outline, Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('Exitosos', _user?.successfulReferrals.toString() ?? '0', Icons.verified_outlined, Colors.green)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard('Pendientes', ((_user?.referralCount ?? 0) - (_user?.successfulReferrals ?? 0)).toString(), Icons.hourglass_empty, Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard('XP Ganada', _user?.referralXpEarned.toString() ?? '0', Icons.bolt, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          children: [
            Icon(Icons.group_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Aún no tienes referidos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Invita a tus amigos para verlos aquí', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (context, index) => _buildReferralTile(_history[index]),
    );
  }

  Widget _buildReferralTile(Map<String, dynamic> referral) {
    final status = referral['status'] as String? ?? 'registered';
    final xp = (referral['xpEarned'] as num?)?.toInt() ?? 0;
    Color statusColor;
    String statusText;
    double progress;
    switch (status) {
      case 'first_post': statusColor = Colors.orange; statusText = 'Primer Reporte'; progress = 0.66; break;
      case 'completed':  statusColor = Colors.green;  statusText = 'Completado';     progress = 1.0;  break;
      default:           statusColor = Colors.blue;   statusText = 'Registrado';     progress = 0.33;
    }

    final userName   = referral['userName'] as String? ?? 'Usuario';
    final userAvatar = referral['userAvatar'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: userAvatar.isNotEmpty ? NetworkImage(userAvatar) : null,
                backgroundColor: const Color(0xFFFF8A00).withOpacity(0.1),
                child: userAvatar.isEmpty ? Text(userName[0].toUpperCase(), style: const TextStyle(color: Color(0xFFFF8A00))) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+$xp XP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const Text('Ganados', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[100], valueColor: AlwaysStoppedAnimation<Color>(statusColor), minHeight: 6, borderRadius: BorderRadius.circular(10)),
        ],
      ),
    );
  }
}
