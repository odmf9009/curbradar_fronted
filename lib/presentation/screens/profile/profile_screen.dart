import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/routes.dart';
import '../../../core/services/users_service.dart';
import '../../../core/services/upload_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/models/curb_object.dart';
import '../../../core/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UsersService _usersService = UsersService();
  final UploadService _uploadService = UploadService();
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  UserModel? _user;
  List<CurbObject> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await _usersService.getMyProfile();
      final posts = await _usersService.getMyObjects();
      if (mounted) {
        setState(() {
          _user = user;
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditAliasDialog(BuildContext context) {
    final controller =
        TextEditingController(text: _user?.username ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Alias Público',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Este nombre se mostrará cuando vayas en camino a recoger un objeto.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Ej: CazadorMiami99',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                final updated = await _usersService.updateProfile(
                    username: controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  if (updated != null && mounted) {
                    setState(() => _user = updated);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Alias actualizado correctamente')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                minimumSize: const Size(80, 36)),
            child: const Text('Guardar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfilePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final imageUrl =
          await _uploadService.uploadProfileImage(File(pickedFile.path));
      final updated =
          await _usersService.updateProfile(profileImageUrl: imageUrl);

      if (mounted) {
        if (updated != null) setState(() => _user = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Foto de perfil actualizada!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al subir foto: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              tr('mi_perfil'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.settings),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFFF8A00)))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: const Color(0xFFFF8A00),
                  child: _buildBody(currentUserId),
                ),
        );
      },
    );
  }

  Widget _buildBody(String currentUserId) {
    final user = _user;
    final posts = _posts;
    final activeCount =
        posts.where((p) => p.status != CurbObjectStatus.pickedUp).length;
    final pickedUpCount =
        posts.where((p) => p.status == CurbObjectStatus.pickedUp).length;
    final bool isAdmin = user?.isAdmin ?? false;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // User Info Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _updateProfilePhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: NetworkImage(
                          user?.profileImageUrl.isNotEmpty == true
                              ? user!.profileImageUrl
                              : 'https://i.pravatar.cc/150?u=$currentUserId',
                        ),
                        child: _isUploading
                            ? const CircularProgressIndicator(
                                color: Color(0xFFFF8A00))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Color(0xFFFF8A00),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Usuario',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user?.username != null &&
                                      user!.username.isNotEmpty
                                  ? '@${user.username}'
                                  : 'Sin alias configurado',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user?.username == null ||
                              (user?.username.isEmpty ?? true))
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 16, color: Color(0xFFFF8A00)),
                              onPressed: () =>
                                  _showEditAliasDialog(context),
                            ),
                        ],
                      ),
                      Text(
                        'Nivel ${user?.level ?? 1} - ${user?.levelTitle ?? 'Explorador'}',
                        style: const TextStyle(
                            color: Color(0xFFFF8A00),
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Nivel ${user?.level ?? 1}',
                        style: const TextStyle(
                            color: Color(0xFFFF8A00),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    Text(
                        '${(user?.points ?? 0) % 500} / 500 XP',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: ((user?.points ?? 0) % 500) / 500,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF8A00)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Main Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    posts.length.toString(), tr('publicaciones')),
                _buildStatItem(
                    pickedUpCount.toString(), tr('recogidos')),
                _buildStatItem(
                    '${user?.reliability.toInt() ?? 100}%',
                    tr('fiabilidad')),
                _buildStatItem(
                    '\$${user?.totalImpactValue.toInt() ?? 0}',
                    tr('impacto')),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Achievements Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Logros',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.achievements),
                        child: const Text('Ver todos',
                            style: TextStyle(color: Color(0xFFFF8A00)))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAchievementIcon(Icons.upload_file,
                        'Primer Post', posts.isNotEmpty),
                    _buildAchievementIcon(
                        Icons.search, 'Cazador', false),
                    _buildAchievementIcon(Icons.check_circle_outline,
                        'Confirmador', false),
                    _buildAchievementIcon(
                        Icons.star_outline, 'Experto', false),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(height: 1),

          // Menu Items
          if (isAdmin)
            _buildMenuItem(
                Icons.admin_panel_settings, 'Panel de Administrador',
                () {
              Navigator.pushNamed(context, AppRoutes.adminPanel);
            }),
          _buildMenuItem(
              Icons.edit_note_outlined, tr('mis_publicaciones'), () {
            Navigator.pushNamed(context, AppRoutes.myPosts);
          }, count: activeCount),
          _buildMenuItem(
              Icons.inventory_2_outlined, tr('objetos_recogidos'), () {
            Navigator.pushNamed(context, AppRoutes.myPosts);
          }, count: pickedUpCount),
          _buildMenuItem(Icons.history, tr('historial'), () {
            Navigator.pushNamed(context, AppRoutes.activityHistory);
          }),
          _buildMenuItem(Icons.emoji_events_outlined, tr('logros'), () {
            Navigator.pushNamed(context, AppRoutes.achievements);
          }),
          _buildMenuItem(Icons.card_giftcard_outlined, tr('recompensas'), () {
            Navigator.pushNamed(context, AppRoutes.rewards);
          }),
          _buildMenuItem(Icons.group_add_outlined, tr('referidos'), () {
            Navigator.pushNamed(context, AppRoutes.referral);
          }),
          _buildMenuItem(Icons.bookmark_border, tr('guardados'), () {
            Navigator.pushNamed(context, AppRoutes.saved);
          }),
          _buildMenuItem(Icons.bar_chart_outlined, 'Estadísticas Comunidad', () {
            Navigator.pushNamed(context, AppRoutes.communityStats);
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildAchievementIcon(
      IconData icon, String label, bool unlocked) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: unlocked
                ? const Color(0xFF121212)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon,
              color: unlocked ? Colors.white : Colors.grey[500],
              size: 24),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: unlocked ? Colors.black87 : Colors.grey)),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap,
      {int? count}) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          leading: Icon(icon, color: Colors.black87, size: 24),
          title: Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (count != null && count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFF8A00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(count.toString(),
                      style: const TextStyle(
                          color: Color(0xFFFF8A00),
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 20),
            ],
          ),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 24, endIndent: 24),
      ],
    );
  }
}
