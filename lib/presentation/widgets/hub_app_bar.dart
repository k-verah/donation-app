import 'package:donation_app/presentation/providers/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HubAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBell;
  final VoidCallback onViewDonations;

  const HubAppBar({
    super.key,
    required this.onBell,
    required this.onViewDonations,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final user = authProv.user;
    final name = user?.name ?? 'User';
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Recyclothes'),
      actions: [
        IconButton(
          tooltip: 'Campaigns and notifications',
          onPressed: onBell,
          icon: const Icon(Icons.notifications_none),
        ),
        PopupMenuButton<String>(
          tooltip: 'Options',
          icon: const Icon(Icons.menu),
          onSelected: (value) async {
            if (value == 'donations') {
              onViewDonations();
            } else if (value == 'logout') {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'greeting',
              enabled: false,
              child: Text(
                'Hello, $name 👋',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'donations',
              child: Text('My donations'),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Sign Out'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
