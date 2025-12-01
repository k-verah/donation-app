import 'package:donation_app/presentation/providers/analytics/analytics_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsProv = context.watch<AnalyticsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: analyticsProv.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Combination Analysis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Most popular filter combinations',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (analyticsProv.filterStats.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No filter usage data available yet'),
                        ),
                      ),
                    )
                  else
                    ...analyticsProv.filterStats.take(10).map((stat) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: Text(
                                '${stat.usageCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '${stat.cause} • ${stat.access} • ${stat.schedule}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('${stat.usageCount} uses'),
                            trailing: const Icon(Icons.trending_up),
                          ),
                        )),
                  const SizedBox(height: 32),
                  const Text(
                    'Point Usage Analysis',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Most visited donation points',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (analyticsProv.pointStats.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('No point usage data available yet'),
                        ),
                      ),
                    )
                  else
                    ...analyticsProv.pointStats.take(10).map((stat) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              child: Text(
                                '${stat.usageCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              stat.pointTitle,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('${stat.usageCount} visits'),
                            trailing: const Icon(Icons.location_on),
                          ),
                        )),
                  const SizedBox(height: 24),
                  if (analyticsProv.filterStats.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Top Filter Combinations',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: analyticsProv.filterStats.isNotEmpty
                                        ? analyticsProv
                                                .filterStats.first.usageCount
                                                .toDouble() *
                                            1.2
                                        : 10,
                                    barTouchData: BarTouchData(
                                      enabled: false,
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index < 0 ||
                                                index >=
                                                    analyticsProv
                                                        .filterStats.length) {
                                              return const SizedBox.shrink();
                                            }

                                            // Mostramos el ranking (1, 2, 3, ...) para que
                                            // el eje X sea entendible sin saturar de texto.
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: analyticsProv.filterStats
                                        .take(5)
                                        .toList() // ✅ CORRECCIÓN: Agregar .toList() aquí
                                        .asMap()
                                        .entries
                                        .map((e) {
                                      return BarChartGroupData(
                                        x: e.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: e.value.usageCount.toDouble(),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            width: 20,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(4),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
