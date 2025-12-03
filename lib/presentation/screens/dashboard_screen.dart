import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/presentation/providers/donations/donation_provider.dart';
import 'package:donation_app/presentation/widgets/sync_status_indicator.dart';
import 'package:donation_app/presentation/screens/donation_insights_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        context.read<DonationProvider>().startUserStream();
        _started = true;
      }
    });
  }

  String? _daysMessageFrom(DateTime? last) {
    if (last == null) return null;
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(last.year, last.month, last.day)).inDays;

    if (days == 0) return "You just donated today!";
    return "It's been $days days since your last donation.\nWe hope to see you again soon!";
  }

  @override
  Widget build(BuildContext context) {
    final donationProv = context.watch<DonationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Impact'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (_) => false),
        ),
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(
            child: StreamBuilder<List<Donation>>(
              stream: donationProv.donationsStream,
              builder: (context, snap) {
                final donations = snap.data ?? const <Donation>[];
                final lastDonation = donations.isEmpty ? null : donations.first;

                const annualGoal = 20;
                final goalProgress =
                    (donations.length / annualGoal).clamp(0.0, 1.0).toDouble();

                final daysMsg = _daysMessageFrom(lastDonation?.createdAt);

                final streak = donationProv.streakFrom(donations);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Donation summary",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ImpactCard(
                            icon: Icons.favorite,
                            value: donations.length.toString(),
                            label: "Donations",
                          ),
                          const SizedBox(width: 12),
                          const _ImpactCard(
                            icon: Icons.people,
                            value: "30",
                            label: "Beneficiaries",
                          ),
                          const SizedBox(width: 12),
                          const _ImpactCard(
                            icon: Icons.recycling,
                            value: "45kg",
                            label: "Clothes",
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        "Annual goal",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: goalProgress,
                        minHeight: 12,
                        color: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "You’ve reached ${(goalProgress * 100).toStringAsFixed(0)}% of your goal!",
                      ),

                      const SizedBox(height: 24),

                      if (daysMsg != null) ...[
                        const Text(
                          "How many days since your last donation?",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text(
                                  daysMsg,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pushNamed(
                                      context, '/new-donation'),
                                  icon: const Icon(Icons.volunteer_activism),
                                  label: const Text("Donate now"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      if (streak > 0)
                        Chip(label: Text('Streak: $streak days 🔥')),

                      const SizedBox(height: 24),
                      const Text(
                        "Recent activity",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      ...const [
                        _ActionTile(
                          title:
                              "You donated 3 items to Fundación Niñez Feliz.",
                          date: "Yesterday",
                        ),
                        _ActionTile(
                          title: "You added 'Coat for Everyone' to favorites.",
                          date: "2 days ago",
                        ),
                        _ActionTile(
                          title: "You registered as a volunteer.",
                          date: "1 week ago",
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Donation Insights Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DonationInsightsScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bar_chart,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Donation Insights',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'View detailed statistics by foundation',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
        leading: Icon(
          Icons.check_circle,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(title),
        subtitle: Text(date),
      ),
    );
  }
}
