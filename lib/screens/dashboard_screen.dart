import 'package:flutter/material.dart';
import '../models/donation_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatelessWidget {
  final DonationItem? lastDonation;
  const DashboardScreen({super.key, this.lastDonation});

  @override
  Widget build(BuildContext context) {
    // Datos estáticos para el prototipo
    const goalProgress = 0.6;

    String? _daysMessageFrom(DateTime? last) {
      if (last == null) return null;
      final now = DateTime.now();
      final days = DateTime(now.year, now.month, now.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;

      if (days == 0) return "You just donated today!";

      return "It's been $days days since your last donation.\nWe hope to see you again soon!";
    }

    final daysMsg = _daysMessageFrom(lastDonation?.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Impact'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Donation summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                _ImpactCard(
                    icon: Icons.favorite, value: "12", label: "Donations"),
                SizedBox(width: 12),
                _ImpactCard(
                    icon: Icons.people, value: "30", label: "Beneficiaries"),
                SizedBox(width: 12),
                _ImpactCard(
                    icon: Icons.recycling, value: "45kg", label: "Clothes"),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Annual goal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goalProgress,
              minHeight: 12,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 6),
            const Text("You’ve reached 60% of your goal!"),
            const SizedBox(height: 24),
            if (daysMsg != null) ...[
              const Text(
                "How many days since your last donation?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(daysMsg,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/new-donation'),
                        icon: const Icon(Icons.volunteer_activism),
                        label: const Text("Donate now"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const StreakBadgeLive(),
            const SizedBox(height: 24),
            const Text(
              "Recent activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...const [
              _ActionTile(
                  title: "You donated 3 items to Fundación Niñez Feliz.",
                  date: "Yesterday"),
              _ActionTile(
                  title: "You added 'Coat for Everyone' to favorites.",
                  date: "2 days ago"),
              _ActionTile(
                  title: "You registered as a volunteer.", date: "1 week ago"),
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

  const _ImpactCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon,
                  size: 28, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
        leading: Icon(Icons.check_circle,
            color: Theme.of(context).colorScheme.secondary),
        title: Text(title),
        subtitle: Text(date),
      ),
    );
  }
}

class StreakBadgeLive extends StatelessWidget {
  const StreakBadgeLive({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final q = FirebaseFirestore.instance
        .collection('donations')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final days = <DateTime>{};
        for (final d in snap.data!.docs) {
          final raw = d.data()['createdAt'];
          if (raw == null) continue;
          final dt = raw is Timestamp ? raw.toDate() : raw as DateTime;
          final local = dt.toLocal();
          days.add(DateTime(local.year, local.month, local.day));
        }
        if (days.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        DateTime latest = days.reduce((a, b) => a.isAfter(b) ? a : b);
        final isToday = latest == today;
        final isYesterday = latest == today.subtract(const Duration(days: 1));
        if (!isToday && !isYesterday) return const SizedBox.shrink();

        int streak = 0;
        var cursor = latest;
        while (days.contains(cursor)) {
          streak += 1;
          cursor = cursor.subtract(const Duration(days: 1));
        }

        if (streak <= 0) return const SizedBox.shrink();

        return Row(
          children: [
            Chip(label: Text('Streak: $streak days 🔥')),
          ],
        );
      },
    );
  }
}
