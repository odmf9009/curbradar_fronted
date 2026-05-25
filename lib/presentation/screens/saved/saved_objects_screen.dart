import 'package:flutter/material.dart';
import '../../../core/models/curb_object.dart';
import '../../../core/services/users_service.dart';
import '../../../core/config/routes.dart';

class SavedObjectsScreen extends StatefulWidget {
  const SavedObjectsScreen({super.key});

  @override
  State<SavedObjectsScreen> createState() => _SavedObjectsScreenState();
}

class _SavedObjectsScreenState extends State<SavedObjectsScreen> {
  final UsersService _usersService = UsersService();
  List<CurbObject> _objects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final objects = await _usersService.getFavoriteObjects();
      if (mounted) {
        setState(() {
          _objects = objects;
          _isLoading = false;
        });
      }
    } catch (e) {
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
        title: const Text(
          'Mis Guardados',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8A00)))
          : _objects.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_border,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aún no has guardado nada',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildTab('Mis favoritos',
                                  isSelected: true)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadFavorites,
                        color: const Color(0xFFFF8A00),
                        child: ListView.separated(
                          itemCount: _objects.length,
                          separatorBuilder: (context, index) =>
                              const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16),
                          itemBuilder: (context, index) {
                            return _buildSavedItem(_objects[index]);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTab(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF8A00) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFF8A00)
              : Colors.grey[300]!,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSavedItem(CurbObject obj) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.objectDetail,
          arguments: obj),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: obj.imageUrls.isNotEmpty
                    ? Image.network(obj.imageUrls[0], fit: BoxFit.cover)
                    : const Icon(Icons.image,
                        color: Colors.grey, size: 30),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    obj.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    obj.address,
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    obj.category,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
