import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'map_screen.dart';
import 'dashboard_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _showHub = true;
  int _index = 0;

  final _pageController = PageController(viewportFraction: 0.9);
  int _bannerIndex = 0;
  Timer? _autoTimer;

  final _banners = const [
    _BannerCard(texto: 'Dale nueva vida a tu ropa ♻️'),
    _BannerCard(texto: 'Agenda una recolección a domicilio'),
    _BannerCard(texto: 'Tu impacto ayuda a más familias'),
  ];

  @override
  void initState() {
    super.initState();
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_showHub || !mounted) return;
      _bannerIndex = (_bannerIndex + 1) % _banners.length;
      _pageController.animateToPage(
        _bannerIndex,
        duration: const Duration(milliseconds: 400),
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

  void _goHub() {
    setState(() => _showHub = true);
  }

  void _onNavTap(int i) {
    setState(() {
      _index = i;
      if (i == 0) {
        _showHub = false;
      } else if (i == 2) {
        _showHub = false;
      } else {
        _showHub = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_showHub) {
      body = _buildHub(context);
    } else {
      body = (_index == 2) ? const DashboardScreen() : const MapScreen();
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
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
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Impacto',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Home PickUp',
          ),
        ],
      ),
    );
  }

  Widget _buildHub(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                InkWell(
                  onTap: _goHub,
                  borderRadius: BorderRadius.circular(8),
                  child: Text(
                    'recyclothes',
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Nueva Donación'),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              onPageChanged: (i) => setState(() => _bannerIndex = i),
              itemBuilder: (_, i) => _banners[i],
            ),
          ),

          // indicadores
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
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text(
                'Bienvenida a Recyclothes 👋',
                style: GoogleFonts.montserrat(fontSize: 16),
              ),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.12),
                Theme.of(context).colorScheme.secondary.withOpacity(0.12),
              ],
            ),
          ),
          child: Center(
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
