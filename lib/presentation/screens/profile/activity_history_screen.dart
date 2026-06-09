import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/models/activity_model.dart';
import '../../../core/models/achievement_model.dart';
import '../../../core/services/activity_service.dart';
import '../../../core/services/achievement_service.dart';
import '../../../core/services/users_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/models/user_model.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  final _activityService = ActivityService();
  final _achievementService = AchievementService();
  final _usersService = UsersService();

  bool _isLoading = true;
  List<ActivityModel> _allActivities = [];
  List<AchievementModel> _achievements = [];
  UserModel? _user;
  String _activeFilter = 'All';

  final List<String> _filters = ['All', 'Publications', 'Collected', 'Community', 'Achievements', 'Ranking'];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _activityService.getMyActivities(),
        _achievementService.getUserAchievements(),
        _usersService.getMyProfile(),
      ]);
      if (mounted) {
        setState(() {
          _allActivities = results[0] as List<ActivityModel>;
          _achievements  = results[1] as List<AchievementModel>;
          _user          = results[2] as UserModel?;
          _isLoading     = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ActivityModel> get _filtered {
    if (_activeFilter == 'All') return _allActivities;
    if (_activeFilter == 'Publications') return _allActivities.where((a) => a.type == ActivityType.publish).toList();
    if (_activeFilter == 'Collected') return _allActivities.where((a) => a.type == ActivityType.collect || a.type == ActivityType.objectCollectedByOther).toList();
    if (_activeFilter == 'Community') return _allActivities.where((a) => [ActivityType.confirm, ActivityType.photoUpdate, ActivityType.communityAppreciation].contains(a.type)).toList();
    if (_activeFilter == 'Achievements') return _allActivities.where((a) => [ActivityType.achievement, ActivityType.levelUp].contains(a.type)).toList();
    if (_activeFilter == 'Ranking') return _allActivities.where((a) => a.type == ActivityType.rankingEntry).toList();
    return _allActivities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(tr('historial'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildShimmer()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildUserSummary()),
                SliverToBoxAdapter(child: _buildRecentAchievements()),
                SliverToBoxAdapter(child: _buildFilterTabs()),
                _filtered.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No hay actividad en esta categoría', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildActivityItem(_filtered[index], index == 0, index == _filtered.length - 1),
                          childCount: _filtered.length,
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildUserSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(_user?.postsCount.toString() ?? '0', tr('publicaciones'), Icons.add_a_photo_outlined),
          _buildStat(_user?.foundCount.toString() ?? '0', tr('recogidos'), Icons.shopping_bag_outlined),
          _buildStat(_user?.points.toString() ?? '0', tr('puntos'), Icons.stars_rounded),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF8A00), size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildRecentAchievements() {
    final unlocked = _achievements.where((a) => a.isUnlocked).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(tr('logros_recientes'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 100,
          child: unlocked.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(child: Text('¡Empieza a explorar para ganar insignias!', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: unlocked.length,
                  itemBuilder: (context, index) {
                    final ach = unlocked[index];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFF8A00).withOpacity(0.5)),
                            ),
                            child: Icon(ach.icon, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(tr(ach.titleKey), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (val) { if (val) setState(() => _activeFilter = filter); },
              selectedColor: const Color(0xFFFF8A00),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? const Color(0xFFFF8A00) : Colors.grey[300]!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityItem(ActivityModel activity, bool isFirst, bool isLast) {
    final diff = DateTime.now().difference(activity.createdAt);
    String timeText;
    if (diff.inMinutes < 60) timeText = 'hace ${diff.inMinutes} min';
    else if (diff.inHours < 24) timeText = 'hace ${diff.inHours}h';
    else if (diff.inDays == 1) timeText = 'ayer';
    else timeText = 'hace ${diff.inDays} días';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(width: 2, height: 20, color: isFirst ? Colors.transparent : Colors.grey[200]),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: activity.color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(activity.icon, color: activity.color, size: 16),
                ),
                Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : Colors.grey[200])),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                        if (activity.points != 0)
                          Text(
                            '${activity.points > 0 ? '+' : ''}${activity.points} pts',
                            style: const TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(activity.description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(timeText, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.white,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 100,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
