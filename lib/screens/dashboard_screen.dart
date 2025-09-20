import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos estáticos para el prototipo
    const donations = 12;
    const beneficiaries = 30;
    const recycledKg = 45;
    const goalProgress = 0.6;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Impacto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Resumen de donaciones", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: const [
                _ImpactCard(icon: Icons.favorite, value: "12", label: "Donaciones"),
                SizedBox(width: 12),
                _ImpactCard(icon: Icons.people, value: "30", label: "Beneficiarios"),
                SizedBox(width: 12),
                _ImpactCard(icon: Icons.recycling, value: "45kg", label: "Ropa reciclada"),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Meta anual", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goalProgress,
              minHeight: 12,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 6),
            const Text("Has cumplido el 60% de tu meta 🎉"),
            const SizedBox(height: 24),
            const Text("Últimas acciones", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...const [
              _ActionTile(title: "Donaste 3 prendas a Fundación Niñez Feliz", date: "Ayer"),
              _ActionTile(title: "Agregaste Abrigo para Todos a favoritos", date: "Hace 2 días"),
              _ActionTile(title: "Te registraste como voluntario", date: "Hace 1 semana"),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ImpactCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String date;

  const _ActionTile({required this.title, required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
        title: Text(title),
        subtitle: Text(date),
      ),
    );
  }
}