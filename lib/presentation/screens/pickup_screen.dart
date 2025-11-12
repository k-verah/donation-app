import 'package:donation_app/presentation/providers/sensors/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PickupScreen extends StatefulWidget {
  const PickupScreen({super.key});

  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

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
    _locationController.text =
        "Lat: ${point.lat.toStringAsFixed(4)}, Lng: ${point.lng.toStringAsFixed(4)}";
    setState(() {});
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      _dateController.text =
          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      setState(() {});
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      _timeController.text = pickedTime.format(context);
      setState(() {});
    }
  }

  void _confirmPickup() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pickup confirmed successfully!")),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final kb = MediaQuery.of(context).viewInsets.bottom;
            final safe = MediaQuery.of(context).padding.bottom;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + kb + safe),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "Select the details for your pickup",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _locationController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        validator: (value) =>
                            value!.isEmpty ? "Please pick a pickup date" : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _timeController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        validator: (value) =>
                            value!.isEmpty ? "Please pick a pickup time" : null,
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: _confirmPickup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF003137),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: Text(
                          "Confirm PickUp",
                          style: GoogleFonts.montserrat(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
