import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchRadiusScreen extends StatefulWidget {
  const SearchRadiusScreen({super.key});

  @override
  State<SearchRadiusScreen> createState() => _SearchRadiusScreenState();
}

class _SearchRadiusScreenState extends State<SearchRadiusScreen> {
  double _radius = 10.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRadius();
  }

  Future<void> _loadRadius() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _radius = prefs.getDouble('search_radius') ?? 10.0;
      _isLoading = false;
    });
  }

  Future<void> _saveRadius(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('search_radius', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _radius),
        ),
        title: const Text(
          'Radio de Búsqueda',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8A00)))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Define el radio por defecto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este será el rango de distancia inicial que usará el mapa para mostrarte tesoros cercanos.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8A00).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.track_changes_rounded, size: 60, color: Color(0xFFFF8A00)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '${_radius.toInt()} millas',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF8A00)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Slider(
                    value: _radius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: const Color(0xFFFF8A00),
                    inactiveColor: Colors.grey[200],
                    onChanged: (value) {
                      setState(() => _radius = value);
                    },
                    onChangeEnd: (value) => _saveRadius(value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 mi', style: TextStyle(color: Colors.grey[400])),
                      Text('50 mi', style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _radius),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF121212),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Guardar configuración', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
