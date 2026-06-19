import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/filter_model.dart';
import '../../../core/config/routes.dart';

class FiltersScreen extends StatefulWidget {
  final FilterModel initialFilters;

  const FiltersScreen({super.key, required this.initialFilters});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late double _distance;
  late String _selectedCategory;
  late String _selectedStatus;
  late String _selectedTime;
  final TextEditingController _searchController = TextEditingController();

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  @override
  void initState() {
    super.initState();
    final filters = widget.initialFilters;
    _distance = _isGuest ? 1.0 : filters.distance;
    _selectedCategory = filters.category;
    _selectedStatus = filters.status;
    _selectedTime = filters.timeRange;
    _searchController.text = filters.searchQuery;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filtros Avanzados',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _distance = 10;
                _selectedCategory = 'Todos';
                _selectedStatus = 'available';
                _selectedTime = 'all';
                _searchController.clear();
              });
            },
            child: const Text(
              'Limpiar',
              style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search keyword
            const Text('Buscar por palabra clave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ej: madera, iphone, sofá...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF8A00)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
              children: [
                _buildCategoryItem('Todos', Icons.all_inclusive_rounded),
                _buildCategoryItem('Muebles', Icons.chair_outlined),
                _buildCategoryItem('Electrodomésticos', Icons.wash_rounded),
                _buildCategoryItem('Electrónica', Icons.tv_rounded),
                _buildCategoryItem('Ropa', Icons.checkroom_rounded),
                _buildCategoryItem('Juguetes', Icons.toys_rounded),
                _buildCategoryItem('Herramientas', Icons.build_rounded),
                _buildCategoryItem('Otros', Icons.more_horiz_rounded),
              ],
            ),
            
            const SizedBox(height: 24),

            const Text('Distancia máxima', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('1 mi', style: TextStyle(color: Colors.grey)),
                Text('${_distance.toInt()} millas', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8A00))),
                const Text('50 mi', style: TextStyle(color: Colors.grey)),
              ],
            ),
            Slider(
              value: _distance,
              min: 1,
              max: 50,
              divisions: 49,
              activeColor: const Color(0xFFFF8A00),
              inactiveColor: Colors.grey[200],
              onChanged: (value) {
                if (_isGuest && value > 1.0) {
                  _showLoginRequiredDialog(
                      'para ver objetos a más de 1 milla de distancia');
                  return;
                }
                setState(() => _distance = value);
              },
            ),

            const SizedBox(height: 24),

            const Text('Fecha de publicación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSelectableBadge('Últimas 24h', '24h', _selectedTime, (val) => setState(() => _selectedTime = val)),
                const SizedBox(width: 8),
                _buildSelectableBadge('Últimos 3 días', '3d', _selectedTime, (val) => setState(() => _selectedTime = val)),
                const SizedBox(width: 8),
                _buildSelectableBadge('Siempre', 'all', _selectedTime, (val) => setState(() => _selectedTime = val)),
              ],
            ),

            const SizedBox(height: 24),

            const Text('Estado del objeto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSelectableTab('Todos', 'Todos'),
                  _buildSelectableTab('Disponibles', 'available'),
                  _buildSelectableTab('Reservados', 'onMyWay'),
                  _buildSelectableTab('Recogidos', 'pickedUp'),
                ],
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                final result = FilterModel(
                  distance: _distance,
                  category: _selectedCategory,
                  status: _selectedStatus,
                  timeRange: _selectedTime,
                  searchQuery: _searchController.text.trim(),
                );
                Navigator.pop(context, result);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Mostrar resultados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableBadge(String label, String value, String groupValue, Function(String) onSelected) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8A00) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF8A00) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? null : Border.all(color: Colors.grey[300]!),
            ),
            child: Icon(icon, color: isSelected ? Colors.white : Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? const Color(0xFFFF8A00) : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableTab(String label, String value) {
    final isSelected = _selectedStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8A00).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFFFF8A00) : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF8A00) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showLoginRequiredDialog(String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Inicio de sesión necesario',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Necesitas iniciar sesión $reason.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Luego', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A00),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Iniciar sesión',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
