import 'package:flutter/material.dart';
import '../../../core/models/reward_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/rewards_service.dart';
import '../../../core/services/users_service.dart';
import '../../../core/services/language_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final _rewardsService = RewardsService();
  final _usersService = UsersService();

  bool _isLoading = true;
  UserModel? _user;
  List<RewardItem> _rewards = [];
  List<XPTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _usersService.getMyProfile(),
        _rewardsService.getAvailableRewards(),
        _rewardsService.getXPHistory(),
      ]);
      if (mounted) {
        setState(() {
          _user         = results[0] as UserModel?;
          _rewards      = results[1] as List<RewardItem>;
          _transactions = results[2] as List<XPTransaction>;
          _isLoading    = false;
        });
      }
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(tr('recompensas'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFFFF8A00),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressHeader(),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('Canjear Recompensas'),
                              _buildRewardsCatalog(),
                              const SizedBox(height: 32),
                              _buildSectionHeader('Cómo Ganar XP'),
                              _buildXPActionList(),
                              const SizedBox(height: 32),
                              _buildSectionHeader('Historial de XP'),
                              _buildXPHistory(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProgressHeader() {
    final progress = _user?.levelProgress ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TU PROGRESO', style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text('Nivel ${_user?.level ?? 1}: ${_user?.levelTitle ?? 'Explorador'}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFF8A00), borderRadius: BorderRadius.circular(20)),
                child: Text('${_user?.points ?? 0} Puntos', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withOpacity(0.1), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF8A00)), minHeight: 12),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(_user?.points ?? 0) % 500} / 500 XP', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              Text('Total: ${_user?.points ?? 0} XP', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF121212))),
    );
  }

  Widget _buildRewardsCatalog() {
    if (_rewards.isEmpty) {
      return const Center(child: Text('No hay recompensas disponibles', style: TextStyle(color: Colors.grey)));
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _rewards.length,
        itemBuilder: (context, index) {
          final reward = _rewards[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 16, bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              border: Border.all(color: reward.isRedeemed ? Colors.green.withOpacity(0.3) : Colors.grey[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(reward.icon, style: const TextStyle(fontSize: 32)),
                    if (reward.isRedeemed) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(reward.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Text('${reward.xpRequired} XP', style: TextStyle(color: reward.isRedeemed ? Colors.grey : const Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (reward.canAfford && !reward.isRedeemed) ? () => _confirmRedeem(reward) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: reward.isRedeemed ? Colors.green : const Color(0xFF121212),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                    ),
                    child: Text(reward.isRedeemed ? 'Canjeado' : 'Canjear', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildXPActionList() {
    final actions = [
      {'title': 'Publicar un Objeto',   'xp': '+50 XP',  'icon': Icons.add_a_photo},
      {'title': 'Marcar como Recogido', 'xp': '+100 XP', 'icon': Icons.check_circle},
      {'title': 'Referido Exitoso',     'xp': '+100 XP', 'icon': Icons.group_add},
      {'title': 'Primera Acción de Referido', 'xp': '+150 XP', 'icon': Icons.bolt},
      {'title': 'Confirmar Objeto',     'xp': '+20 XP',  'icon': Icons.fact_check},
    ];
    return Column(
      children: actions.map((action) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(action['icon'] as IconData, color: const Color(0xFFFF8A00), size: 24),
            const SizedBox(width: 16),
            Expanded(child: Text(action['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text(action['xp'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildXPHistory() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('Aún no tienes historial de XP.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.take(5).length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isPositive = tx.xpAmount > 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(isPositive ? Icons.add : Icons.remove, color: isPositive ? Colors.green : Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${tx.date.day}/${tx.date.month}/${tx.date.year}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ),
              Text('${isPositive ? '+' : ''}${tx.xpAmount} XP', style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.red)),
            ],
          ),
        );
      },
    );
  }

  void _confirmRedeem(RewardItem reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Canjear ${reward.title}'),
        content: Text('¿Deseas canjear esta recompensa por ${reward.xpRequired} XP?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _redeemReward(reward); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00), foregroundColor: Colors.white),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _redeemReward(RewardItem reward) async {
    try {
      await _rewardsService.redeemReward(reward.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('¡"${reward.title}" canjeado!'), backgroundColor: Colors.green));
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tienes suficientes puntos o hubo un error.'), backgroundColor: Colors.red));
      }
    }
  }
}
