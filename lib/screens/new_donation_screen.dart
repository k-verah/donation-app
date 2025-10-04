import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'camera_sensor_screen.dart';
import '../models/donation_item.dart';

class NewDonationScreen extends StatefulWidget {
  const NewDonationScreen({super.key});

  @override
  State<NewDonationScreen> createState() => _NewDonationScreenState();
}

class _NewDonationScreenState extends State<NewDonationScreen> {
  final _picker = ImagePicker();
  XFile? _image;

  final _desc = TextEditingController();
  final _brand = TextEditingController();
  final _size = TextEditingController();

  final _types = const [
    'Camisa',
    'Pantalón',
    'Chaqueta',
    'Vestido',
    'Accesorio'
  ];
  String? _type;

  final _allTags = const [
    'Mujer',
    'Hombre',
    'Niño',
    'Invierno',
    'Verano',
    'Formal',
    'Casual',
    'Deportivo',
    'Fiesta',
    'Abrigo'
  ];
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _desc.dispose();
    _brand.dispose();
    _size.dispose();
    super.dispose();
  }

  Future<void> _openCameraSensor() async {
    final shot = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(builder: (_) => const CameraSensorScreen()),
    );
    if (shot != null) setState(() => _image = shot);
  }

  Future<void> _pickFromGallery() async {
    final img = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90);
    if (img != null) setState(() => _image = img);
  }

  void _submit() {
    if (_image == null ||
        _desc.text.trim().isEmpty ||
        _type == null ||
        _size.text.trim().isEmpty ||
        _brand.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Ha habido un error creando su donación'),
          content: Text('Por favor revise los datos ingresados.'),
        ),
      );
      return;
    }

    final item = DonationItem(
      imagePath: _image!.path,
      description: _desc.text.trim(),
      type: _type!,
      size: _size.text.trim(),
      brand: _brand.text.trim(),
      tags: _selectedTags.toList(),
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Donación')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Donate Your Clothing',
                style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: primary.withOpacity(0.9))),
            const SizedBox(height: 6),
            Text("Let's find the perfect new home for your pre-loved items.",
                style: TextStyle(
                    color: theme.colorScheme.onBackground.withOpacity(0.7))),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _openCameraSensor,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.25)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: _image == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt, size: 40, color: primary),
                              const SizedBox(height: 8),
                              Text('Item Image (Required)',
                                  style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Toca para abrir la cámara',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              Image.file(File(_image!.path), fit: BoxFit.cover),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Elegir de la galería'),
              ),
            ),
            const SizedBox(height: 12),
            _Input(
                controller: _desc,
                label: 'Description (Required)',
                maxLines: 3),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v),
              decoration: const InputDecoration(
                  labelText: 'Clothing Type (Required)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            _Input(controller: _size, label: 'Size (Required)'),
            const SizedBox(height: 12),
            _Input(controller: _brand, label: 'Brand (Required)'),
            const SizedBox(height: 16),
            Text('Tags',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allTags.map((t) {
                final selected = _selectedTags.contains(t);
                return FilterChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    v ? _selectedTags.add(t) : _selectedTags.remove(t);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _submit,
                child: Text('Submit Donation',
                    style: GoogleFonts.montserrat(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  const _Input(
      {required this.controller, required this.label, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}
