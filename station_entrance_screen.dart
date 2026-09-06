import 'package:flutter/material.dart';
import '../data/station_data.dart';
import '../models/station_model.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

IconData _iconForAccess(AccessType access) {
  switch (access) {
    case AccessType.elevator:
      return Icons.elevator_outlined;
    case AccessType.wheelchairAccessible:
      return Icons.accessible;
    case AccessType.ramp:
      return Icons.moving;
    case AccessType.stairsOnly:
      return Icons.stairs;
  }
}

String _labelForAccess(AccessType access) {
  switch (access) {
    case AccessType.elevator:
      return 'Hiss';
    case AccessType.wheelchairAccessible:
      return 'Tillgänglig ingång';
    case AccessType.ramp:
      return 'Ramp';
    case AccessType.stairsOnly:
      return 'Trappa';
  }
}

/// Fiche d'entrée de gare. stationId doit exister dans StationData —
/// voir le commentaire dans ce fichier sur le fait que ces données sont
/// relevées à la main, gare par gare, pas récupérées d'une API.
class StationEntranceScreen extends StatelessWidget {
  final String stationId;
  const StationEntranceScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    final station = StationData.byId(stationId);

    if (station == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.background, title: const Text('Station')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ValueListenableBuilder<String>(
              valueListenable: AppStrings.locale,
              builder: (context, _, __) => Text(
                AppStrings.t('station_not_surveyed'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ),
        ),
      );
    }

    final best = _bestEntrance(station.entrances);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(station.name, style: const TextStyle(fontSize: 15)),
            ValueListenableBuilder<String>(
              valueListenable: AppStrings.locale,
              builder: (context, _, __) => Text(
                AppStrings.t('station_entrances_subtitle'),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          if (best != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(_iconForAccess(best.access), size: 18, color: AppColors.cyclingGreen),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entré ${best.label} leder till ${_labelForAccess(best.access).toLowerCase()}, plattform ${best.platforms.join(', ')}',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${best.walkingMinutesFromEntrance} min gångväg',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: ValueListenableBuilder<String>(
              valueListenable: AppStrings.locale,
              builder: (context, _, __) => Text(
                AppStrings.t('station_all_entrances'),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ),

          for (final entrance in station.entrances) _EntranceTile(entrance: entrance),
        ],
      ),
    );
  }

  /// Priorise l'entrée avec ascenseur/accessible en fauteuil — cf. la
  /// logique de la maquette qui met en avant l'accès le plus universel.
  StationEntrance? _bestEntrance(List<StationEntrance> entrances) {
    if (entrances.isEmpty) return null;
    return entrances.firstWhere(
      (e) => e.access == AccessType.elevator || e.access == AccessType.wheelchairAccessible,
      orElse: () => entrances.first,
    );
  }
}

class _EntranceTile extends StatelessWidget {
  final StationEntrance entrance;
  const _EntranceTile({required this.entrance});

  @override
  Widget build(BuildContext context) {
    final isAccessible = entrance.access == AccessType.elevator || entrance.access == AccessType.wheelchairAccessible;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isAccessible ? AppColors.cyclingGreenDark : AppColors.chip,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(entrance.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${entrance.description}, plattform ${entrance.platforms.join(' och ')}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          Icon(
            _iconForAccess(entrance.access),
            size: 16,
            color: isAccessible ? AppColors.cyclingGreen : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
