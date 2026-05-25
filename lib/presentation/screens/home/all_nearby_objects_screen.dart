import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/curb_object.dart';
import '../../../core/config/routes.dart';

class AllNearbyObjectsScreen extends StatelessWidget {
  final List<CurbObject> objects;
  final Position? currentPosition;

  const AllNearbyObjectsScreen({super.key, required this.objects, this.currentPosition});

  @override
  Widget build(BuildContext context) {
    // Limit to 20 objects as requested
    final displayedObjects = objects.take(20).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hallazgos cercanos',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: displayedObjects.isEmpty
          ? const Center(
              child: Text('No hay objetos en tu rango de búsqueda',
                  style: TextStyle(color: Colors.grey)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: displayedObjects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final obj = displayedObjects[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 100)),
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
                  child: _buildListItem(context, obj),
                );
              },
            ),
    );
  }

  Widget _buildListItem(BuildContext context, CurbObject obj) {
    Color statusColor = obj.status == CurbObjectStatus.available 
        ? const Color(0xFF4CAF50) 
        : const Color(0xFF1976D2);

    String distanceText = '';
    if (currentPosition != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        currentPosition!.latitude, currentPosition!.longitude,
        obj.latitude, obj.longitude
      );
      double distanceInMiles = distanceInMeters / 1609.34;
      distanceText = '${distanceInMiles.toStringAsFixed(1)} mi';
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.objectDetail, arguments: obj),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          children: [
            // Image with status border and Hero
            Hero(
              tag: 'image_${obj.id}',
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: obj.imageUrls.isNotEmpty
                      ? Image.network(obj.imageUrls[0], fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          obj.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          obj.remainingTimeText,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        obj.category,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (distanceText.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, size: 4, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          distanceText,
                          style: const TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          obj.address,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
