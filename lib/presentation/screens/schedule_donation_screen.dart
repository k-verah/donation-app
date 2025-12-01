import 'package:donation_app/presentation/providers/donations/donation_provider.dart';
import 'package:donation_app/presentation/providers/donations/schedule_donation_provider.dart';
import 'package:donation_app/presentation/widgets/donation_selection_list.dart';
import 'package:donation_app/presentation/widgets/sync_status_indicator.dart';
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

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    // Limpiar selección anterior
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleDonationProvider>().clearSelection();
    });
  }

  @override
  void dispose() {
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
    final scheduleProvider = context.read<ScheduleDonationProvider>();

    if (scheduleProvider.selectedDonationIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one donation."),
          backgroundColor: Color(0xFF003137),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please pick a donation date."),
          backgroundColor: Color(0xFF003137),
        ),
      );
      return;
    }

    DateTime finalDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    final error = await scheduleProvider.onConfirm(
      date: finalDate,
      time: _selectedTime != null ? _timeController.text : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Donation scheduled!"),
          backgroundColor: Color(0xFF003137),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFF003137),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationProvider = context.watch<DonationProvider>();
    final scheduleProvider = context.watch<ScheduleDonationProvider>();
    // Solo mostrar donaciones disponibles (no asociadas a ningún schedule/pickup)
    final donations = donationProvider.availableDonations;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Schedule your Donation'),
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Select the items you want to deliver",
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
                            selectedIds: scheduleProvider.selectedDonationIds,
                            onToggle: scheduleProvider.toggleDonation,
                            emptyMessage: 'No donations to schedule',
                          ),

                          const SizedBox(height: 24),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 16),

                          Text(
                            "Schedule Details",
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _dateController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
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
                              suffixIcon: const Icon(Icons.comment_outlined),
                            ),
                          ),
                          const SizedBox(height: 25),

                          // Botón de confirmar
                          ElevatedButton(
                            onPressed:
                                scheduleProvider.selectedDonationIds.isNotEmpty
                                    ? _confirmSchedule
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
                              "Confirm Schedule (${scheduleProvider.selectedDonationIds.length} items)",
                              style: GoogleFonts.montserrat(
                                color: scheduleProvider
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
