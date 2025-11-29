import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:donation_app/presentation/providers/sync/sync_provider.dart';
import 'package:donation_app/data/services/sync/sync_service.dart';

/// Widget que muestra el estado de conectividad y sincronización
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, _) {
        final isOnline = syncProvider.isOnline;
        final isSyncing = syncProvider.isSyncing;
        final pendingCount = syncProvider.pendingCount;

        // Si está todo bien, no mostrar nada
        if (isOnline && pendingCount == 0 && !isSyncing) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getBackgroundColor(isOnline, isSyncing, pendingCount),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(isOnline, isSyncing),
              const SizedBox(width: 8),
              Text(
                _getMessage(isOnline, isSyncing, pendingCount),
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(isOnline, isSyncing),
                ),
              ),
              if (!isOnline && pendingCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$pendingCount',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildIcon(bool isOnline, bool isSyncing) {
    if (isSyncing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (!isOnline) {
      return const Icon(
        Icons.cloud_off,
        size: 16,
        color: Colors.white,
      );
    }

    return const Icon(
      Icons.cloud_done,
      size: 16,
      color: Colors.white,
    );
  }

  Color _getBackgroundColor(bool isOnline, bool isSyncing, int pendingCount) {
    if (!isOnline) {
      return Colors.orange.shade700;
    }
    if (isSyncing) {
      return Colors.blue.shade600;
    }
    if (pendingCount > 0) {
      return Colors.amber.shade700;
    }
    return Colors.green.shade600;
  }

  Color _getTextColor(bool isOnline, bool isSyncing) {
    return Colors.white;
  }

  String _getMessage(bool isOnline, bool isSyncing, int pendingCount) {
    if (!isOnline) {
      return pendingCount > 0
          ? 'Offline - $pendingCount pending'
          : 'You are offline';
    }
    if (isSyncing) {
      return 'Syncing...';
    }
    if (pendingCount > 0) {
      return '$pendingCount items pending';
    }
    return 'All synced';
  }
}

/// Banner compacto para mostrar en la parte inferior de pantallas
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, _) {
        if (syncProvider.isOnline && syncProvider.pendingCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: syncProvider.isOnline
              ? Colors.blue.shade50
              : Colors.orange.shade50,
          child: Row(
            children: [
              Icon(
                syncProvider.isOnline ? Icons.sync : Icons.cloud_off,
                size: 18,
                color: syncProvider.isOnline
                    ? Colors.blue.shade700
                    : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  syncProvider.isOnline
                      ? 'Syncing your data...'
                      : 'You\'re offline. Changes will sync when connected.',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: syncProvider.isOnline
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
              if (syncProvider.pendingCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: syncProvider.isOnline
                        ? Colors.blue.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${syncProvider.pendingCount} pending',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: syncProvider.isOnline
                          ? Colors.blue.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
