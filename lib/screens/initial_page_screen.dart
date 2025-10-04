import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final _pageController = PageController(viewportFraction: 0.92);
  int _bannerIndex = 0;
  Timer? _autoTimer;

  final _banners = const [
    _BannerCard(texto: 'Dale nueva vida a tu ropa'),
    _BannerCard(texto: 'Agenda una recolección a domicilio'),
    _BannerCard(texto: 'Tu impacto ayuda a más familias'),
  ];

  final _screens = const [
    MapScreen(),
    ScheduleScreen(),
    DashboardScreen(),
    PickupScreen(),
  ];

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
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goHub() => setState(() {
        _showHub = true;
        _navIndex = 2;
      });

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
    final Widget body = _showHub ? _buildHub(context) : _screens[_screenIndex];

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onNavTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Agendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Impacto',
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
              children: [
                InkWell(
                  onTap: _goHub,
                  borderRadius: BorderRadius.circular(8),
                  child: Text(
                    'Recyclothes',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Campañas y avisos',
                  onPressed: () =>
                      Navigator.pushNamed(context, '/notifications'),
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  textStyle: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: const StadiumBorder(),
                ),
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Nueva Donación'),
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
