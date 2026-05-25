import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/curb_object.dart';
import '../../../core/services/users_service.dart';
import '../../../core/config/routes.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final UsersService _usersService = UsersService();
  UserModel? _user;
  List<CurbObject> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final userId =
        ModalRoute.of(context)?.settings.arguments as String?;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final user = await _usersService.getPublicProfile(userId);
      if (user != null) {
        final posts = await _usersService.getMyObjects(); // Note: only works for self
        // Use empty posts for public profiles if no dedicated endpoint
        if (mounted) {
          setState(() {
            _user = user;
            _posts = [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Perfil del Cazador',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8A00)))
          : _user == null
              ? const Center(child: Text('Usuario no encontrado'))
              : _buildProfile(_user!),
    );
  }

  Widget _buildProfile(UserModel user) {
    final pickedUpCount =
        _posts.where((p) => p.status == CurbObjectStatus.pickedUp).length;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Header
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: user.profileImageUrl.isNotEmpty
                ? NetworkImage(user.profileImageUrl)
                : null,
            child: user.profileImageUrl.isEmpty
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            '@${user.username.isNotEmpty ? user.username : user.name}',
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Nivel ${user.level} - ${user.levelTitle}',
            style: const TextStyle(
                color: Color(0xFFFF8A00), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),

          // Trust Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Puntuación de Confianza',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${user.reliability.toInt()}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: user.reliability / 100,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF8A00)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(user.postsCount.toString(), 'Publicados'),
                _buildStatItem(
                    pickedUpCount.toString(), 'Recogidos'),
                _buildStatItem(
                    '\$${user.totalImpactValue.toInt()}', 'Impacto'),
              ],
            ),
          ),

          const SizedBox(height: 40),
          const Divider(),

          // Recent Activity Preview
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Publicaciones Recientes',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_posts.isEmpty)
                  const Text(
                      'Este cazador aún no ha publicado tesoros.',
                      style: TextStyle(color: Colors.grey)),
                ..._posts.take(3).map((post) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: post.imageUrls.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(post.imageUrls[0],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image,
                                  color: Colors.grey),
                            ),
                      title: Text(post.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500)),
                      subtitle: Text(post.category),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.objectDetail,
                          arguments: post),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
