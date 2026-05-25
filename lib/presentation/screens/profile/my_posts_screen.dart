import 'package:flutter/material.dart';
import '../../../core/models/curb_object.dart';
import '../../../core/services/users_service.dart';
import '../../../core/config/routes.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final UsersService _usersService = UsersService();
  String _activeFilter = 'Activas';
  List<CurbObject> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      final posts = await _usersService.getMyObjects();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _posts.where((post) {
      if (_activeFilter == 'Activas') {
        return post.status != CurbObjectStatus.pickedUp;
      }
      if (_activeFilter == 'Recogidas') {
        return post.status == CurbObjectStatus.pickedUp;
      }
      return true; // Historial shows all
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mis publicaciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildFilterTab('Activas'),
                const SizedBox(width: 10),
                _buildFilterTab('Historial'),
                const SizedBox(width: 10),
                _buildFilterTab('Recogidas'),
              ],
            ),
          ),

          // Posts List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF8A00)))
                : filteredPosts.isEmpty
                    ? const Center(
                        child: Text(
                          'No tienes publicaciones en esta categoría',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPosts,
                        color: const Color(0xFFFF8A00),
                        child: ListView.separated(
                          itemCount: filteredPosts.length,
                          separatorBuilder: (context, index) =>
                              const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16),
                          itemBuilder: (context, index) {
                            final post = filteredPosts[index];
                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                  milliseconds: 400 + (index * 100)),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildPostItem(post),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF8A00)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF8A00)
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPostItem(CurbObject post) {
    Color statusColor;
    String statusText;

    switch (post.status) {
      case CurbObjectStatus.available:
        statusColor = const Color(0xFF4CAF50);
        statusText = 'Disponible';
        break;
      case CurbObjectStatus.onMyWay:
        statusColor = const Color(0xFF2196F3);
        statusText = 'Alguien va en camino';
        break;
      case CurbObjectStatus.pickedUp:
        statusColor = Colors.grey;
        statusText = 'Recogido';
        break;
    }

    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.objectDetail,
          arguments: post),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Image with Hero
            Hero(
              tag: 'image_${post.id}',
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: post.imageUrls.isNotEmpty
                      ? Image.network(post.imageUrls[0],
                          fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Publicado el ${_formatDate(post.createdAt)}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
