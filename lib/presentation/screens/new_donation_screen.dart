// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:donation_app/presentation/providers/donations/donation_provider.dart';
import 'package:donation_app/presentation/providers/sensors/camera_provider.dart';
import 'package:donation_app/presentation/screens/camara_sensor_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
    'Shirt',
    'T-Shirt',
    'Pants',
    'Jacket',
    'Dress',
    'Accessory',
  ];
  String? _type;

  final _allTags = const [
    'Women',
    'Men',
    'Kids',
    'Winter',
    'Summer',
    'Formal',
    'Casual',
    'Sport',
    'Party',
    'Coat',
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
    final img = await context.read<CameraProvider>().pickGallery();
    if (img != null) setState(() => _image = img);
  }

  Future<void> _submit() async {
    if (_desc.text.trim().isEmpty ||
        _type == null ||
        _size.text.trim().isEmpty ||
        _brand.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('There was an error creating your donation.'),
          content: Text('Please review the information you entered.'),
        ),
      );
      return;
    }

    final donationProv = context.read<DonationProvider>();
    await donationProv.create(
      description: _desc.text.trim(),
      type: _type!.trim(),
      size: _size.text.trim(),
      brand: _brand.text.trim(),
      tags: _selectedTags.toList(),
      localImagePath: _image?.path,
    );
    Navigator.pop(context, _image?.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('New Donation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Donate Your Clothing',
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: primary.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Let's find the perfect new home for your items.",
              style: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
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
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _image == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt, size: 40, color: primary),
                              const SizedBox(height: 8),
                              Text(
                                'Item Image (Required)',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Touch to open the camera.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_image!.path),
                            fit: BoxFit.cover,
                          ),
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
                label: const Text('Choose from library.'),
              ),
            ),
            const SizedBox(height: 12),
            _Input(
              controller: _desc,
              label: 'Description (Required)',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v),
              decoration: const InputDecoration(
                labelText: 'Clothing Type (Required)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _Input(controller: _size, label: 'Size (Required)'),
            const SizedBox(height: 12),
            _Input(controller: _brand, label: 'Brand (Required)'),
            const SizedBox(height: 16),
            Text(
              'Tags',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
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
                child: Text(
                  'Submit Donation',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
  const _Input({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ).copyWith(labelText: label),
    );
  }
}
