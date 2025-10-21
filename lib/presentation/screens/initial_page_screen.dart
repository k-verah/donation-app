// presentation/screens/initial_page_screen.dart
// Pantalla inicial limpia: sin Firebase directo. Usa DonationProvider para datos.

import 'dart:async';
import 'dart:io';
import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/presentation/providers/donations/donation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'map_screen.dart';
import 'dashboard_screen.dart';
import 'schedule_screen.dart';
import 'pickup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _InitialPageScreenState();
}

class _InitialPageScreenState extends State<HomeScreen> {
  bool _showHub = true;
  int _navIndex = 2;
  int _screenIndex = 0;

  // Para recordar la foto local de la donación recién creada
  String? _lastLocalImagePathOverride;

  // Carrusel de banners
  final _pageController = PageController(viewportFraction: 0.92);
  int _bannerIndex = 0;
  Timer? _autoTimer;

  final _banners = const [
    _BannerCard(texto: 'Give your clothes a second life'),
    _BannerCard(texto: 'Book a pickup at home'),
    _BannerCard(texto: 'Your impact reaches more families'),
  ];

  @override
  void initState() {
    super.initState();

    // Arranca el stream de donaciones del usuario DESDE el provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationProvider>().startUserStream();
    });

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
  }

  @override
  void dispose() {
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

  Widget _buildScreen() {
    switch (_screenIndex) {
      case 0:
        return const MapScreen();
      case 1:
        return const ScheduleScreen();
      case 2:
        return const DashboardScreen(); // ahora el dashboard usa provider/stream
      case 3:
        return const PickupScreen();
      default:
        return const MapScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final donationProv = context.watch<DonationProvider>();

    // Construimos el body con el stream de donaciones
    return StreamBuilder<List<Donation>>(
      stream: donationProv.donationsStream,
      builder: (context, snap) {
        final donations = snap.data ?? const <Donation>[];
        final last = donations.isEmpty ? null : donations.first;

        // Si hay override de imagen local, úsalo sólo para mostrar miniatura
        final lastLocalPath =
            _lastLocalImagePathOverride ?? last?.localImagePath;

        final Widget hub = _buildHub(
          context: context,
          last: last,
          lastLocalPath: lastLocalPath,
        );

        final Widget body = _showHub ? hub : _buildScreen();

        return Scaffold(
          appBar: _showHub
              ? _HubAppBar(
                  onBell: () => Navigator.pushNamed(context, '/notifications'),
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
      },
    );
  }

  Widget _buildHub({
    required BuildContext context,
    required Donation? last,
    required String? lastLocalPath,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Column(
        children: [
          // Header spacing
          const SizedBox(height: 8),

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
                            context,
                            '/new-donation',
                          );

                          // Si la pantalla de “new donation” te devuelve una ruta local,
                          // la guardamos para mostrar miniatura hasta que el stream la
                          // traiga desde la BD (o para siempre si no subes fotos).
                          if (!mounted) return;

                          if (res is String && res.isNotEmpty) {
                            setState(() {
                              _lastLocalImagePathOverride = res;
                              _showHub = true;
                              _navIndex = 2;
                            });
                          } else {
                            // Si devolviste otra cosa (o nada), igualmente volvemos al hub
                            setState(() {
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
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          textStyle: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () => _onNavTap(0), // pestaña Mapa
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

          // Carrusel
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

          if (last != null) ...[
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
              child: _LastDonationCard(
                donation: last,
                localImagePathOverride: lastLocalPath,
              ),
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
  final Donation donation;
  final String? localImagePathOverride; // permite mostrar miniatura local
  const _LastDonationCard({
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
            // Miniatura
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
            // Texto
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
