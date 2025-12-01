import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/presentation/providers/donations/donation_provider.dart';
import 'package:donation_app/presentation/providers/donations/pickup_donation_provider.dart';
import 'package:donation_app/presentation/providers/sensors/location_provider.dart';
import 'package:donation_app/presentation/widgets/donation_selection_list.dart';
import 'package:donation_app/presentation/widgets/sync_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PickupDonationScreen extends StatefulWidget {
  const PickupDonationScreen({super.key});

  @override
  State<PickupDonationScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupDonationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  GeoPoint? _selectedLocation;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    // Limpiar selección anterior
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PickupDonationProvider>().clearSelection();
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _fillWithCurrentLocation() async {
    final locProv = context.read<LocationProvider>();
    final point = await locProv.getCurrentLocation();
    if (!mounted) return;
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enable location services to continue.")),
      );
      return;
    }
    _selectedLocation = point;
    _locationController.text =
        "Lat: ${point.lat.toStringAsFixed(4)}, Lng: ${point.lng.toStringAsFixed(4)}";
    setState(() {});
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      _selectedDate = pickedDate;
      _dateController.text =
          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      setState(() {});
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      _selectedTime = pickedTime;
      _timeController.text = pickedTime.format(context);
      setState(() {});
    }
  }

  Future<void> _confirmPickup() async {
    final pickupProvider = context.read<PickupDonationProvider>();

    if (pickupProvider.selectedDonationIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one donation.")),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your location.")),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a pickup date.")),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a pickup time.")),
      );
      return;
    }

    final pickupDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final error = await pickupProvider.onConfirm(
      location: _selectedLocation!,
      date: pickupDateTime,
      time: _timeController.text,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pickup scheduled! Will sync when online."),
          backgroundColor: Color(0xFF003137),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final pickupProvider = context.watch<PickupDonationProvider>();
    // Solo mostrar donaciones disponibles (no asociadas a ningún schedule/pickup)
    final donations = donationProvider.availableDonations;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('PickUp at Home'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (_) => false),
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final kb = MediaQuery.of(context).viewInsets.bottom;
                  final safe = MediaQuery.of(context).padding.bottom;

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + kb + safe),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Select items for home pickup",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Lista de donaciones seleccionables
                          DonationSelectionList(
                            donations: donations,
                            selectedIds: pickupProvider.selectedDonationIds,
                            onToggle: pickupProvider.toggleDonation,
                            emptyMessage: 'No donations for pickup',
                          ),

                          const SizedBox(height: 24),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 16),

                          Text(
                            "Pickup Details",
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _locationController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            readOnly: true,
                            onTap: _fillWithCurrentLocation,
                            decoration: InputDecoration(
                              labelText: "Select Location (Required)",
                              hintText: "Tap to use current location",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.my_location),
                                onPressed: _fillWithCurrentLocation,
                              ),
                            ),
                            validator: (value) => value!.isEmpty
                                ? "Please select your location"
                                : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _dateController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            readOnly: true,
                            onTap: _selectDate,
                            decoration: InputDecoration(
                              labelText: "PickUp Date (Required)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: _selectDate,
                              ),
                            ),
                            validator: (value) => value!.isEmpty
                                ? "Please pick a pickup date"
                                : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _timeController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            readOnly: true,
                            onTap: _selectTime,
                            decoration: InputDecoration(
                              labelText: "PickUp Time (Required)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.access_time),
                                onPressed: _selectTime,
                              ),
                            ),
                            validator: (value) => value!.isEmpty
                                ? "Please pick a pickup time"
                                : null,
                          ),
                          const SizedBox(height: 25),

                          // Botón de confirmar
                          ElevatedButton(
                            onPressed:
                                pickupProvider.selectedDonationIds.isNotEmpty
                                    ? _confirmPickup
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003137),
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Text(
                              "Confirm PickUp (${pickupProvider.selectedDonationIds.length} items)",
                              style: GoogleFonts.montserrat(
                                color: pickupProvider
                                        .selectedDonationIds.isNotEmpty
                                    ? Colors.white
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          Text(
                            "⚡ Works offline! Will sync when connected.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
