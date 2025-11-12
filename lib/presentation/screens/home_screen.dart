import 'dart:async';
import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/presentation/providers/donations/donation_provider.dart';
import 'package:donation_app/presentation/widgets/banner_carousel.dart';
import 'package:donation_app/presentation/widgets/hub_app_bar.dart';
import 'package:donation_app/presentation/widgets/last_donation.dart';
import 'package:donation_app/presentation/widgets/primary_actions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'map_screen.dart';
import 'dashboard_screen.dart';
import 'schedule_screen.dart';
import 'pickup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showHub = true;
  int _navIndex = 2;
  int _screenIndex = 0;

  // Para recordar la foto local de la donación recién creada
  String? _lastLocalImagePathOverride;

  @override
  void initState() {
    super.initState();
    // Inicia el stream de donaciones del usuario desde el Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationProvider>().startUserStream();
    });
  }

  void _onNavTap(int index) {
    if (index == 2) {
      setState(() {
        _showHub = true;
        _navIndex = 2;
      });
      return;
    }
    setState(() {
      _showHub = false;
      _navIndex = index;
      _screenIndex = (index < 2) ? index : index - 1;
    });
  }

  Widget _buildScreen() {
    switch (_screenIndex) {
      case 0:
        return const MapScreen();
      case 1:
        return const ScheduleScreen();
      case 2:
        return const PickupScreen();
      case 3:
        return const DashboardScreen();
      default:
        return const MapScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationProv = context.watch<DonationProvider>();

    return StreamBuilder<List<Donation>>(
      stream: donationProv.donationsStream,
      builder: (context, snapshot) {
        final donations = snapshot.data ?? const <Donation>[];
        final last = donations.isEmpty ? null : donations.first;
        final lastLocalPath =
            _lastLocalImagePathOverride ?? last?.localImagePath;

        final Widget body = _showHub
            ? _HubView(
                lastDonation: last,
                lastLocalPath: lastLocalPath,
                onNewDonation: () async {
                  final result =
                      await Navigator.pushNamed(context, '/new-donation');
                  if (!mounted) return null;

                  setState(() {
                    _showHub = true;
                    _navIndex = 2;
                  });

                  if (result is String && result.isNotEmpty) {
                    setState(() => _lastLocalImagePathOverride = result);
                    return result;
                  }
                  return null;
                },
                onGoToMap: () => _onNavTap(0),
              )
            : _buildScreen();

        return Scaffold(
          appBar: _showHub
              ? HubAppBar(
                  onBell: () => Navigator.pushNamed(context, '/notifications'),
                  onViewDonations: () =>
                      Navigator.pushNamed(context, '/donations'),
                )
              : null,
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _navIndex,
            onDestinationSelected: _onNavTap,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_available_outlined),
                selectedIcon: Icon(Icons.event_available),
                label: 'Schedule',
              ),
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping),
                label: 'PickUp',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: 'Impact',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HubView extends StatelessWidget {
  final Donation? lastDonation;
  final String? lastLocalPath;
  final Future<String?> Function() onNewDonation;
  final VoidCallback onGoToMap;

  const _HubView({
    required this.lastDonation,
    required this.lastLocalPath,
    required this.onNewDonation,
    required this.onGoToMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        PrimaryActions(
          onNewDonation: onNewDonation,
          onGoToMap: onGoToMap,
        ),
        const SizedBox(height: 12),
        isLandscape
            ? SizedBox(
                height: 180,
                child: BannerCarousel(),
              )
            : const Expanded(
                child: BannerCarousel(),
              ),
        if (lastDonation != null) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Latest Donation',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LastDonationCard(
              donation: lastDonation!,
              localImagePathOverride: lastLocalPath,
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
    return SafeArea(
      child: isLandscape
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: content,
              ),
            )
          : content,
    );
  }
}
