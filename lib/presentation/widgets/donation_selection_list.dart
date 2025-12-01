import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:donation_app/domain/entities/donations/donation.dart';

/// Widget reutilizable para seleccionar donaciones mediante un modal
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

  void _showSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DonationSelectionModal(
        donations: donations,
        selectedIds: selectedIds,
        onToggle: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay donaciones disponibles
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
            Icon(Icons.dry_cleaning, size: 48, color: Colors.grey.shade400),
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

    // Obtener las donaciones seleccionadas
    final selectedDonations =
        donations.where((d) => selectedIds.contains(d.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón para abrir el modal de selección
        InkWell(
          onTap: () => _showSelectionModal(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selectedIds.isNotEmpty
                  ? const Color(0xFF003137).withOpacity(0.08)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedIds.isNotEmpty
                    ? const Color(0xFF003137)
                    : Colors.grey.shade300,
                width: selectedIds.isNotEmpty ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selectedIds.isNotEmpty
                        ? const Color(0xFF003137).withOpacity(0.15)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.dry_cleaning,
                    color: selectedIds.isNotEmpty
                        ? const Color(0xFF003137)
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedIds.isEmpty
                            ? 'Select Donations'
                            : '${selectedIds.length} donation${selectedIds.length > 1 ? 's' : ''} selected',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: selectedIds.isNotEmpty
                              ? const Color(0xFF003137)
                              : Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'Tap to ${selectedIds.isEmpty ? 'choose' : 'edit'} items',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selectedIds.isEmpty
                        ? Colors.grey.shade300
                        : const Color(0xFF003137),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${selectedIds.length}/${donations.length}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selectedIds.isEmpty
                          ? Colors.grey.shade600
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),

        // Mostrar las donaciones seleccionadas
        if (selectedDonations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Selected items:',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedDonations.map((donation) {
              return _SelectedDonationChip(
                donation: donation,
                onRemove: () => onToggle(donation.id!),
              );
            }).toList(),
          ),
        ],

        // Mensaje si no hay selección
        if (selectedIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Select at least one donation',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Chip que muestra una donación seleccionada
class _SelectedDonationChip extends StatelessWidget {
  final Donation donation;
  final VoidCallback onRemove;

  const _SelectedDonationChip({
    required this.donation,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF003137).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF003137).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dry_cleaning,
            size: 16,
            color: const Color(0xFF003137),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              donation.description,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF003137),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                size: 16,
                color: const Color(0xFF003137),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal para seleccionar donaciones
class _DonationSelectionModal extends StatefulWidget {
  final List<Donation> donations;
  final Set<String> selectedIds;
  final void Function(String donationId) onToggle;

  const _DonationSelectionModal({
    required this.donations,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  State<_DonationSelectionModal> createState() =>
      _DonationSelectionModalState();
}

class _DonationSelectionModalState extends State<_DonationSelectionModal> {
  late Set<String> _localSelectedIds;

  @override
  void initState() {
    super.initState();
    _localSelectedIds = Set.from(widget.selectedIds);
  }

  void _toggleLocal(String id) {
    setState(() {
      if (_localSelectedIds.contains(id)) {
        _localSelectedIds.remove(id);
      } else {
        _localSelectedIds.add(id);
      }
    });
  }

  void _confirmSelection() {
    // Sincronizar con el estado del padre
    final toAdd = _localSelectedIds.difference(widget.selectedIds);
    final toRemove = widget.selectedIds.difference(_localSelectedIds);

    for (final id in toAdd) {
      widget.onToggle(id);
    }
    for (final id in toRemove) {
      widget.onToggle(id);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003137).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.dry_cleaning,
                    color: Color(0xFF003137),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Donations',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_localSelectedIds.length} of ${widget.donations.length} selected',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_localSelectedIds.length == widget.donations.length) {
                        _localSelectedIds.clear();
                      } else {
                        _localSelectedIds =
                            widget.donations.map((d) => d.id!).toSet();
                      }
                    });
                  },
                  child: Text(
                    _localSelectedIds.length == widget.donations.length
                        ? 'Clear all'
                        : 'Select all',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF003137),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Lista de donaciones
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.donations.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 70,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final donation = widget.donations[index];
                final isSelected = _localSelectedIds.contains(donation.id);

                return _DonationTile(
                  donation: donation,
                  isSelected: isSelected,
                  onTap: () => _toggleLocal(donation.id!),
                );
              },
            ),
          ),

          // Botón de confirmar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _localSelectedIds.isNotEmpty ? _confirmSelection : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003137),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _localSelectedIds.isEmpty
                        ? 'Select items to continue'
                        : 'Confirm ${_localSelectedIds.length} item${_localSelectedIds.length > 1 ? 's' : ''}',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _localSelectedIds.isNotEmpty
                          ? Colors.white
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile individual de donación en el modal
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isSelected ? const Color(0xFF003137).withOpacity(0.06) : null,
        child: Row(
          children: [
            // Checkbox animado
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF003137) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF003137)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),

            // Icono de gancho de ropa
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF003137).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.dry_cleaning,
                size: 22,
                color: Color(0xFF003137),
              ),
            ),
            const SizedBox(width: 14),

            // Información de la donación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.description,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

            // Tag (si hay)
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
}
