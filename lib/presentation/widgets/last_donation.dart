import 'dart:io';
import 'package:flutter/material.dart';
import 'package:donation_app/domain/entities/donations/donation.dart';

class LastDonationCard extends StatelessWidget {
  final Donation donation;
  final String? localImagePathOverride;

  const LastDonationCard({
    super.key,
    required this.donation,
    required this.localImagePathOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imgPath = localImagePathOverride ?? donation.localImagePath;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (imgPath != null &&
                        imgPath.isNotEmpty &&
                        File(imgPath).existsSync())
                    ? Image.file(File(imgPath), fit: BoxFit.cover)
                    : Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${donation.type} · ${donation.brand}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
