import 'package:donation_app/presentation/widgets/sync_status_indicator.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _Campaign(
        title: "Warm a Child",
        desc: "Winter clothing for children in rural areas.",
      ),
      _Campaign(
        title: "Summer Solidarity",
        desc: "T-shirts and sandals for families in warm climates.",
      ),
      _Campaign(
        title: "Support for Mothers",
        desc: "Maternity and baby clothing.",
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Active Campaigns")),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final c = items[i];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(
                      Icons.campaign,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      c.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(c.desc),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Campaign {
  final String title;
  final String desc;
  const _Campaign({required this.title, required this.desc});
}
