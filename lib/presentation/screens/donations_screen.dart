import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/presentation/providers/donations/donation_provider.dart';

class DonationsScreen extends StatelessWidget {
  const DonationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final donationProv = context.watch<DonationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My donations'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Donation>>(
        stream: donationProv.donationsStream,
        builder: (context, snapshot) {
          final donations = snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text('Loading your donations...'));
          }

          if (donations.isEmpty) {
            return const _EmptyDonationsView();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final donation = donations[index];
              return _DonationItem(donation: donation);
            },
          );
        },
      ),
    );
  }
}

class _DonationItem extends StatelessWidget {
  final Donation donation;

  const _DonationItem({required this.donation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imgPath = donation.localImagePath;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen o placeholder
            SizedBox(
              width: 70,
              height: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (imgPath != null &&
                        imgPath.isNotEmpty &&
                        File(imgPath).existsSync())
                    ? Image.file(File(imgPath), fit: BoxFit.cover)
                    : Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Detalles
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${donation.type} · ${donation.brand}',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    donation.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (donation.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: -6,
                      children: donation.tags.take(3).map((t) {
                        return Chip(
                          label: Text(t),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDonationsView extends StatelessWidget {
  const _EmptyDonationsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            Text(
              'You do not have donations yet',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Make your first donation!',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: theme.colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/new-donation'),
              icon: const Icon(Icons.add),
              label: const Text('New donation'),
            ),
          ],
        ),
      ),
    );
  }
}
