import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/objects_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/upload_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/utils/reward_helper.dart';

class PublishObjectScreen extends StatefulWidget {
  const PublishObjectScreen({super.key});

  @override
  State<PublishObjectScreen> createState() => _PublishObjectScreenState();
}

class _PublishObjectScreenState extends State<PublishObjectScreen> {
  final ObjectsService _objectsService = ObjectsService();
  final LocationService _locationService = LocationService();
  final UploadService _uploadService = UploadService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // State
  final List<File> _imageFiles = [];
  double? _lat;
  double? _lng;
  String _currentAddress = 'Detectando ubicación...';
  String? _currentLocality;
  String _selectedCategory = 'Muebles';
  bool _isChatEnabled = true;
  bool _isLoading = false;

  final List<String> _categories = [
    'Muebles',
    'Electrodomésticos',
    'Electrónica',
    'Ropa',
    'Juguetes',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final hasPermission =
          await _locationService.checkAndRequestPermissions();
      if (hasPermission) {
        final position = await _locationService.getCurrentLocation();
        if (position != null) {
          setState(() {
            _lat = position.latitude;
            _lng = position.longitude;
          });
          _getAddressFromLatLng(position.latitude, position.longitude);
        }
      }
    } catch (e) {
      print('Error obteniendo ubicación inicial: $e');
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        if (mounted) {
          setState(() {
            _currentAddress =
                '${place.street}, ${place.locality}, ${place.administrativeArea}';
            _currentLocality = place.locality;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentAddress = 'Ubicación manual');
      }
    }
  }

  Future<void> _pickImage() async {
    if (_imageFiles.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 3 fotos permitidas')),
      );
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() => _imageFiles.add(File(pickedFile.path)));
    }
  }

  void _removeImage(int index) {
    setState(() => _imageFiles.removeAt(index));
  }

  Future<void> _publish() async {
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, toma al menos una foto del objeto')),
      );
      return;
    }

    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hemos podido detectar tu ubicación')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload images via backend-mediated upload
      final List<String> imageUrls = [];
      for (final file in _imageFiles) {
        final url = await _uploadService.uploadObjectImage(file);
        imageUrls.add(url);
      }

      // 2. Create object via REST
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await _objectsService.createObject({
        'title': _titleController.text.isEmpty
            ? 'Hallazgo sin título'
            : _titleController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'imageUrls': imageUrls,
        'latitude': _lat,
        'longitude': _lng,
        'address': _currentAddress,
        if (_currentLocality != null) 'locality': _currentLocality,
        'isChatEnabled': _isChatEnabled,
      });

      // 3. Backend awards +50 points automatically on createObject
      if (mounted) {
        RewardHelper.showReward(context, 50);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Objeto publicado con éxito!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al publicar: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('publicar'),
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8A00)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Photo Section
                  Text(
                    tr('fotos'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imageFiles.length +
                          (_imageFiles.length < 3 ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _imageFiles.length &&
                            _imageFiles.length < 3) {
                          return GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.grey[300]!,
                                    style: BorderStyle.solid),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined,
                                      color: Colors.grey, size: 30),
                                  SizedBox(height: 4),
                                  Text('Añadir',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        }

                        return Stack(
                          children: [
                            Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: FileImage(_imageFiles[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Section
                  Text(
                    tr('categoria'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    items: _categories
                        .map((cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 24),

                  // Title Section
                  Text(
                    tr('titulo'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Ej: Sofá de cuero negro',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description Section
                  Text(
                    tr('descripcion'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Ej: Está un poco sucio pero estructuralmente bien.',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location Section
                  Text(
                    tr('ubicacion'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Colors.black87),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentAddress,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: _initLocation,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Chat Option Section
                  Material(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    child: SwitchListTile(
                      title: Text(
                        tr('habilitar_chat'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: const Text(
                        'Permite que el recolector te contacte cuando esté en camino.',
                        style: TextStyle(fontSize: 12),
                      ),
                      activeColor: const Color(0xFFFF8A00),
                      value: _isChatEnabled,
                      onChanged: (val) =>
                          setState(() => _isChatEnabled = val),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Publish Button
                  ElevatedButton(
                    onPressed: _publish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      tr('publicar'),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
