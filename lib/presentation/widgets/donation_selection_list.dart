import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:donation_app/domain/entities/donations/donation.dart';

/// Widget reutilizable para seleccionar donaciones
class DonationSelectionList extends StatelessWidget {
  final List<Donation> donations;
  final Set<String> selectedIds;
  final void Function(String donationId) onToggle;
  final String emptyMessage;

  const DonationSelectionList({
    super.key,
    required this.donations,
    required this.selectedIds,
    required this.onToggle,
    this.emptyMessage = 'No donations available',
  });

  @override
  Widget build(BuildContext context) {
    if (donations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.montserrat(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a donation first to schedule it',
              style: GoogleFonts.montserrat(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con contador
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Donations',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selectedIds.isEmpty
                    ? Colors.grey.shade200
                    : const Color(0xFF003137),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${selectedIds.length} selected',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      selectedIds.isEmpty ? Colors.grey.shade600 : Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de donaciones
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: donations.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final donation = donations[index];
              final isSelected = selectedIds.contains(donation.id);

              return _DonationTile(
                donation: donation,
                isSelected: isSelected,
                onTap: () => onToggle(donation.id!),
              );
            },
          ),
        ),

        if (selectedIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '* Select at least one donation',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: Colors.red.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _DonationTile extends StatelessWidget {
  final Donation donation;
  final bool isSelected;
  final VoidCallback onTap;

  const _DonationTile({
    required this.donation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? const Color(0xFF003137).withOpacity(0.08) : null,
        child: Row(
          children: [
            // Checkbox animado
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF003137) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF003137)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // Icono de tipo
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(donation.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTypeIcon(donation.type),
                size: 20,
                color: _getTypeColor(donation.type),
              ),
            ),
            const SizedBox(width: 12),

            // Información de la donación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.description,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${donation.type} • ${donation.size} • ${donation.brand}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Tags (solo mostrar el primero si hay)
            if (donation.tags.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  donation.tags.first,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'shirt':
      case 'top':
        return Icons.checkroom;
      case 'pants':
      case 'jeans':
        return Icons.straighten;
      case 'jacket':
      case 'coat':
        return Icons.layers;
      case 'dress':
        return Icons.woman;
      case 'shoes':
        return Icons.ice_skating;
      case 'accessories':
        return Icons.watch;
      default:
        return Icons.dry_cleaning;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'shirt':
      case 'top':
        return Colors.blue;
      case 'pants':
      case 'jeans':
        return Colors.indigo;
      case 'jacket':
      case 'coat':
        return Colors.brown;
      case 'dress':
        return Colors.pink;
      case 'shoes':
        return Colors.orange;
      case 'accessories':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }
}
