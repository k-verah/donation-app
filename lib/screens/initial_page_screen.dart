// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/donation_item.dart';
import 'map_screen.dart';
import 'dashboard_screen.dart';
import 'schedule_screen.dart';
import 'pickup_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _showHub = true;

  int _navIndex = 2;

  int _screenIndex = 0;

  DonationItem? _lastDonation;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _donationSub;

  // Carrusel
  final _pageController = PageController(viewportFraction: 0.92);
  int _bannerIndex = 0;
  Timer? _autoTimer;

  final _banners = const [
    _BannerCard(texto: 'Give your clothes a second life'),
    _BannerCard(texto: 'Book a pickup at home'),
    _BannerCard(texto: 'Your impact reaches more families'),
  ];

  Widget _buildScreen() {
    switch (_screenIndex) {
      case 0:
        return const MapScreen();
      case 1:
        return const ScheduleScreen();
      case 2:
        return DashboardScreen(lastDonation: _lastDonation);
      case 3:
        return const PickupScreen();
      default:
        return const MapScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_showHub || !mounted) return;
      _bannerIndex = (_bannerIndex + 1) % _banners.length;
      _pageController.animateToPage(
        _bannerIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
      );
      setState(() {});
    });
    _listenLastDonation();
  }

  void _listenLastDonation() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _donationSub = FirebaseFirestore.instance
        .collection('donations')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .listen((snap) {
      if (!mounted || snap.docs.isEmpty) return;
      final data = snap.docs.first.data();
      final fromDb = DonationItem.fromMap(data);

      setState(() {
        _lastDonation = DonationItem(
          imagePath: _lastDonation?.imagePath,
          description: fromDb.description,
          type: fromDb.type,
          size: fromDb.size,
          brand: fromDb.brand,
          tags: fromDb.tags,
          createdAt: fromDb.createdAt,
        );
      });
    });
  }

  @override
  void dispose() {
    _donationSub?.cancel();
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int i) {
    if (i == 2) {
      setState(() {
        _showHub = true;
        _navIndex = 2;
      });
      return;
    }
    setState(() {
      _showHub = false;
      _navIndex = i;
      _screenIndex = (i < 2) ? i : i - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = _showHub ? _buildHub(context) : _buildScreen();

    return Scaffold(
      appBar: _showHub
          ? _HubAppBar(onBell: () {
              Navigator.pushNamed(context, '/notifications');
            })
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
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Impact',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'PickUp',
          ),
        ],
      ),
    );
  }

  Widget _buildHub(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [],
            ),
          ),

          Padding(
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
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          textStyle: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () async {
                          final res = await Navigator.pushNamed(
                              context, '/new-donation');
                          if (!mounted) return;
                          if (res is DonationItem) {
                            setState(() {
                              _lastDonation = res;
                              _showHub = true;
                              _navIndex = 2;
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('New Donation'),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Ubicar fundaciones más cercanas
                    SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.primary),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          textStyle: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          _onNavTap(0); // ir a la pestaña Mapa
                        },
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
          ),

          Expanded(
            child: Center(
              child: SizedBox(
                height: 320,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _banners.length,
                  onPageChanged: (i) => setState(() => _bannerIndex = i),
                  itemBuilder: (_, i) => _banners[i],
                ),
              ),
            ),
          ),

          // Indicadores
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (i) {
              final active = i == _bannerIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? primary : primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),

          if (_lastDonation != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Donations',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _LastDonationCard(item: _lastDonation!),
            ),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String texto;
  const _BannerCard({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.10),
                Theme.of(context).colorScheme.secondary.withOpacity(0.10),
              ],
            ),
          ),
          child: Center(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LastDonationCard extends StatelessWidget {
  final DonationItem item;
  const _LastDonationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Miniatura
            SizedBox(
              width: 64,
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (item.imagePath != null && item.imagePath!.isNotEmpty)
                    ? Image.file(
                        File(item.imagePath!),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Icon(Icons.image_not_supported),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.type} · ${item.brand}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (item.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: -6,
                      children: item.tags.take(3).map((t) {
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

class _HubAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBell;
  const _HubAppBar({required this.onBell});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleSpacing: 16,
      title: Text(
        'Recyclothes',
        style: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Campaings and notifications',
          onPressed: onBell,
          icon: const Icon(Icons.notifications_none),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
