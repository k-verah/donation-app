import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _Campaign(title: "Abriga un Niño", desc: "Ropa de invierno para niños en zonas rurales."),
      _Campaign(title: "Verano Solidario", desc: "Camisetas y sandalias para familias en climas cálidos."),
      _Campaign(title: "Apoyo a Madres", desc: "Ropa de maternidad y para bebés."),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Campañas activas")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final c = items[i];
          return Card(
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.campaign, color: Theme.of(context).colorScheme.primary),
              title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(c.desc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}

class _Campaign {
  final String title;
  final String desc;
  const _Campaign({required this.title, required this.desc});
}