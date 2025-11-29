import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/domain/entities/donations/schedule_donation.dart';
import 'package:donation_app/domain/entities/donations/pickup_donation.dart';
import 'package:donation_app/presentation/providers/donations/donation_provider.dart';
import 'package:donation_app/presentation/widgets/sync_status_indicator.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Donations'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Available', icon: Icon(Icons.inventory_2_outlined)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle_outline)),
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
          ],
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AvailableDonationsTab(),
                _CompletedDonationsTab(),
                _PendingDeliveriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 1: Donaciones Disponibles
// ============================================================

class _AvailableDonationsTab extends StatelessWidget {
  const _AvailableDonationsTab();

  @override
  Widget build(BuildContext context) {
    final donationProv = context.watch<DonationProvider>();
    final donations = donationProv.availableDonations;

    if (donations.isEmpty) {
      return _EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'No available donations',
        subtitle: 'Create a new donation to get started',
        actionLabel: 'New Donation',
        onAction: () => Navigator.pushNamed(context, '/new-donation'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: donations.length,
      itemBuilder: (context, index) =>
          _DonationCard(donation: donations[index]),
    );
  }
}

// ============================================================
// TAB 2: Donaciones Completadas
// ============================================================

class _CompletedDonationsTab extends StatelessWidget {
  const _CompletedDonationsTab();

  @override
  Widget build(BuildContext context) {
    final donationProv = context.watch<DonationProvider>();
    final donations = donationProv.completedDonations;

    if (donations.isEmpty) {
      return const _EmptyStateWidget(
        icon: Icons.check_circle_outline,
        title: 'No completed donations yet',
        subtitle: 'Complete a delivery to see your donations here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: donations.length,
      itemBuilder: (context, index) => _DonationCard(
        donation: donations[index],
        showCompletedBadge: true,
      ),
    );
  }
}

// ============================================================
// TAB 3: Entregas Pendientes (Paquetes)
// ============================================================

class _PendingDeliveriesTab extends StatelessWidget {
  const _PendingDeliveriesTab();

  @override
  Widget build(BuildContext context) {
    final donationProv = context.watch<DonationProvider>();
    final schedules = donationProv.undeliveredSchedules;
    final pickups = donationProv.undeliveredPickups;

    if (schedules.isEmpty && pickups.isEmpty) {
      return _EmptyStateWidget(
        icon: Icons.pending_actions,
        title: 'No pending deliveries',
        subtitle: 'Schedule or request a pickup to see your packages here',
        actionLabel: 'Go to Schedule',
        onAction: () => Navigator.pushNamed(context, '/schedule'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (schedules.isNotEmpty) ...[
          _SectionHeader(
            title: 'Scheduled Deliveries',
            count: schedules.length,
            icon: Icons.event_available,
          ),
          const SizedBox(height: 8),
          ...schedules.map((s) => _SchedulePackageCard(schedule: s)),
          const SizedBox(height: 16),
        ],
        if (pickups.isNotEmpty) ...[
          _SectionHeader(
            title: 'Pickup Requests',
            count: pickups.length,
            icon: Icons.local_shipping,
          ),
          const SizedBox(height: 8),
          ...pickups.map((p) => _PickupPackageCard(pickup: p)),
        ],
      ],
    );
  }
}

// ============================================================
// Widget: Tarjeta de Donación
// ============================================================

class _DonationCard extends StatelessWidget {
  final Donation donation;
  final bool showCompletedBadge;

  const _DonationCard({
    required this.donation,
    this.showCompletedBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imgPath = donation.localImagePath;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen
            SizedBox(
              width: 70,
              height: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: (imgPath != null &&
                        imgPath.isNotEmpty &&
                        File(imgPath).existsSync())
                    ? Image.file(File(imgPath), fit: BoxFit.cover)
                    : Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.checkroom,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${donation.type} · ${donation.brand}',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (showCompletedBadge)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Done',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    donation.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (donation.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: donation.tags.take(3).map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Widget: Tarjeta de Paquete de Schedule
// ============================================================

class _SchedulePackageCard extends StatelessWidget {
  final ScheduleDonation schedule;

  const _SchedulePackageCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final donationProv = context.read<DonationProvider>();
    final donations = donationProv.getDonationsByIds(schedule.donationIds);

    return _PackageCard(
      icon: Icons.event_available,
      iconColor: Colors.blue,
      title: 'Scheduled for ${_formatDate(schedule.date)}',
      subtitle: schedule.time ?? 'No specific time',
      donationCount: schedule.donationIds.length,
      donations: donations,
      onComplete: () async {
        final confirmed = await _showConfirmDialog(context);
        if (confirmed == true) {
          await donationProv.completeScheduleDelivery(schedule.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ ${schedule.donationIds.length} donations marked as completed!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Delivery'),
        content: Text(
          'Mark ${schedule.donationIds.length} donation(s) as delivered?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Widget: Tarjeta de Paquete de Pickup
// ============================================================

class _PickupPackageCard extends StatelessWidget {
  final PickupDonation pickup;

  const _PickupPackageCard({required this.pickup});

  @override
  Widget build(BuildContext context) {
    final donationProv = context.read<DonationProvider>();
    final donations = donationProv.getDonationsByIds(pickup.donationIds);

    return _PackageCard(
      icon: Icons.local_shipping,
      iconColor: Colors.orange,
      title: 'Pickup on ${_formatDate(pickup.date)}',
      subtitle: 'At ${pickup.time}',
      donationCount: pickup.donationIds.length,
      donations: donations,
      onComplete: () async {
        final confirmed = await _showConfirmDialog(context);
        if (confirmed == true) {
          await donationProv.completePickupDelivery(pickup.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ ${pickup.donationIds.length} donations marked as completed!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Pickup'),
        content: Text(
          'Mark ${pickup.donationIds.length} donation(s) as picked up?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Widget: Tarjeta de Paquete Genérica
// ============================================================

class _PackageCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int donationCount;
  final List<Donation> donations;
  final VoidCallback onComplete;

  const _PackageCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.donationCount,
    required this.donations,
    required this.onComplete,
  });

  @override
  State<_PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<_PackageCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${widget.donationCount} items',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Donations list (expandable)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  const Divider(height: 1),
                  ...widget.donations.map(
                    (d) => _MiniDonationTile(donation: d),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onComplete,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Complete Delivery'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF003137),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _MiniDonationTile extends StatelessWidget {
  final Donation donation;

  const _MiniDonationTile({required this.donation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: donation.localImagePath != null &&
                    File(donation.localImagePath!).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(donation.localImagePath!),
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.checkroom, size: 20, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${donation.type} · ${donation.size}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Widget: Header de Sección
// ============================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Widget: Estado Vacío
// ============================================================

class _EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
