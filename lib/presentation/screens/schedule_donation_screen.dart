import 'package:donation_app/presentation/providers/donations/schedule_donation_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ScheduleDonationScreen extends StatefulWidget {
  const ScheduleDonationScreen({super.key});

  @override
  State<ScheduleDonationScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleDonationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _selectedDate = picked;
      _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      setState(() {});
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      _selectedTime = picked;
      _timeController.text = picked.format(context);
      setState(() {});
    }
  }

  Future<void> _confirmSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick a donation date.")),
      );
      return;
    }

    DateTime finalDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    final provider = context.read<ScheduleDonationProvider>();
    final error = await provider.onConfirm(
      title: _titleController.text.trim(),
      date: finalDate,
      time: _selectedTime != null ? _timeController.text : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Donation scheduled successfully!")),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('You already have a donation scheduled for today.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // deja que el teclado reduzca el viewport
      appBar: AppBar(
        title: const Text('Schedule your Donation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (_) => false),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final kb = MediaQuery.of(context).viewInsets.bottom; // teclado
            final safe = MediaQuery.of(context).padding.bottom; // notch / barra

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + kb + safe),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "Plan ahead when you want to deliver your items",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                            labelText: "Donation Title (Required)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: const Icon(Icons.title)),
                        validator: (value) =>
                            value!.isEmpty ? "Please enter a title" : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _dateController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: InputDecoration(
                          labelText: "Donation Date (Required)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickDate,
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Please pick a date" : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        onTap: _pickTime,
                        decoration: InputDecoration(
                          labelText: "Donation Time (Optional)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: _pickTime,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                            labelText: "Additional Notes (Optional)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: const Icon(Icons.comment_outlined)),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        onPressed: _confirmSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF003137),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: Text("Confirm Schedule",
                            style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
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
