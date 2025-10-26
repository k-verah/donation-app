import 'package:donation_app/presentation/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class PrimaryActions extends StatelessWidget {
  final Future<String?> Function() onNewDonation;
  final VoidCallback onGoToMap;

  const PrimaryActions({
    super.key,
    required this.onNewDonation,
    required this.onGoToMap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nueva Donación
              SizedBox(
                height: 60,
                child: PrimaryButton(
                  label: 'New Donation',
                  onPressed: () async => await onNewDonation(),
                ),
              ),
              const SizedBox(height: 10),

              // Ubicar fundaciones más cercanas
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    side: BorderSide(color: colorScheme.primary),
                    foregroundColor: colorScheme.primary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: onGoToMap,
                  icon: const Icon(Icons.my_location),
                  label: const Text(
                    'Locate nearby foundations',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
