/*
import 'package:donation_app/presentation/providers/donations/donation_insights_provider.dart';
import 'package:donation_app/domain/use_cases/donations/get_donation_insights_by_foundation.dart';
import 'package:donation_app/presentation/providers/sensors/location_provider.dart';
import 'package:donation_app/presentation/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class DonationInsightsScreen extends StatefulWidget {
  const DonationInsightsScreen({super.key});

  @override
  State<DonationInsightsScreen> createState() => _DonationInsightsScreenState();
}

class _DonationInsightsScreenState extends State<DonationInsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonationInsightsProvider>().loadInsights();
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Hace menos de un minuto';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }

  @override
  Widget build(BuildContext context) {
    final insightsProv = context.watch<DonationInsightsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Insights'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: insightsProv.loading
          ? const Center(child: CircularProgressIndicator())
          : insightsProv.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          insightsProv.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => insightsProv.loadInsights(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : insightsProv.insights.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.insights_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No donation insights available yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Make some donations to see statistics',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => insightsProv.refresh(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Donations by Foundation',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'How many donations you made to each foundation and average distance',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            //  Banner de estado offline
                            if (insightsProv.isOffline)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(top: 16, bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.cloud_off, color: Colors.orange[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Modo offline: mostrando datos guardados.\nÚltima actualización: ${insightsProv.lastUpdatedAt != null ? _formatDate(insightsProv.lastUpdatedAt!) : 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[900],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.refresh, color: Colors.orange[700]),
                                      onPressed: () => insightsProv.refresh(),
                                      tooltip: 'Reintentar actualización',
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                            // Gráfico de barras
                            SizedBox(
                              height: 300,
                              child: Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Top Foundations by Donations',
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
                                            maxY: insightsProv.insights.isNotEmpty
                                                ? insightsProv.insights.first.donationCount.toDouble() * 1.2
                                                : 10,
                                            barTouchData: BarTouchData(
                                              enabled: true,
                                              touchTooltipData: BarTouchTooltipData(
                                                getTooltipColor: (_) => Colors.blueGrey,
                                                tooltipRoundedRadius: 8,
                                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                                  final insight = insightsProv.insights[groupIndex];
                                                  return BarTooltipItem(
                                                    '${insight.donationCount} donations\n${insight.foundation.title}',
                                                    const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            titlesData: FlTitlesData(
                                              show: true,
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 50,
                                                  getTitlesWidget: (value, meta) {
                                                    if (value.toInt() >= 0 &&
                                                        value.toInt() < insightsProv.insights.length) {
                                                      final foundation = insightsProv.insights[value.toInt()].foundation;
                                                      return Padding(
                                                        padding: const EdgeInsets.only(top: 8),
                                                        child: Text(
                                                          foundation.title.length > 12
                                                              ? '${foundation.title.substring(0, 12)}...'
                                                              : foundation.title,
                                                          style: const TextStyle(fontSize: 10),
                                                          textAlign: TextAlign.center,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      );
                                                    }
                                                    return const Text('');
                                                  },
                                                ),
                                              ),
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 40,
                                                  getTitlesWidget: (value, meta) {
                                                    return Text(
                                                      value.toInt().toString(),
                                                      style: const TextStyle(fontSize: 12),
                                                    );
                                                  },
                                                ),
                                              ),
                                              topTitles: AxisTitles(
                                                sideTitles: SideTitles(showTitles: false),
                                              ),
                                              rightTitles: AxisTitles(
                                                sideTitles: SideTitles(showTitles: false),
                                              ),
                                            ),
                                            gridData: FlGridData(
                                              show: true,
                                              drawVerticalLine: false,
                                            ),
                                            borderData: FlBorderData(show: false),
                                            barGroups: insightsProv.insights
                                                .take(5)
                                                .toList()
                                                .asMap()
                                                .entries
                                                .map((e) {
                                              return BarChartGroupData(
                                                x: e.key,
                                                barRods: [
                                                  BarChartRodData(
                                                    toY: e.value.donationCount.toDouble(),
                                                    color: Theme.of(context).colorScheme.primary,
                                                    width: 20,
                                                    borderRadius: const BorderRadius.vertical(
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
                            const SizedBox(height: 32),
                            // Lista detallada
                            const Text(
                              'Detailed Statistics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...insightsProv.insights.map((insight) => Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  child: InkWell(
                                    onTap: () {
                                      // Aplicar filtros en LocationProvider
                                      final locationProvider = context.read<LocationProvider>();
                                      locationProvider.setFilters(
                                        causeVal: insight.foundation.cause,
                                        accessVal: insight.foundation.access,
                                        scheduleVal: insight.foundation.schedule,
                                      );
                                      
                                      // Navegar directamente al mapa
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const MapScreen(),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(16),
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        radius: 24,
                                        child: Text(
                                          '${insight.donationCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        insight.foundation.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.category,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Cause: ${insight.foundation.cause}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.accessibility,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Access: ${insight.foundation.access}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Schedule
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                size: 14,
                                                color: Colors.orange[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Schedule: ${insight.foundation.schedule}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (insight.averageDistance > 0)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 14,
                                                  color: Colors.blue[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Distance: ${insight.averageDistance.toStringAsFixed(0)} m',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_off,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  'Distance: Not available',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      trailing: Icon(
                                        Icons.map,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                )),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
*/
