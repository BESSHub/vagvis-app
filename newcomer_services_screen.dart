import 'package:flutter/material.dart';
import '../data/newcomer_service_data.dart';
import '../models/newcomer_service_model.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';

/// Écran "Nyanländ i Skåne" — SFI/Komvux, bibliothèques, Saluhall
/// réunis avec des filtres, comme décidé dans la note de synthèse
/// (fusion plutôt que trois écrans séparés). Données relevées à la main
/// — voir newcomer_service_data.dart.
class NewcomerServicesScreen extends StatefulWidget {
  const NewcomerServicesScreen({super.key});

  @override
  State<NewcomerServicesScreen> createState() => _NewcomerServicesScreenState();
}

class _NewcomerServicesScreenState extends State<NewcomerServicesScreen> {
  NewcomerServiceType? _filter;

  static const _filters = [
    (null, 'filter_all'),
    (NewcomerServiceType.sfi, 'filter_sfi'),
    (NewcomerServiceType.library, 'filter_library'),
    (NewcomerServiceType.foodHall, 'filter_food_hall'),
  ];

  @override
  Widget build(BuildContext context) {
    final services = NewcomerServiceData.byType(_filter);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: ValueListenableBuilder<String>(
          valueListenable: AppStrings.locale,
          builder: (context, _, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.t('newcomer_services_title'), style: const TextStyle(fontSize: 15)),
              Text(AppStrings.t('newcomer_services_subtitle'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: ValueListenableBuilder<String>(
              valueListenable: AppStrings.locale,
              builder: (context, _, __) => Row(
                children: [
                  for (final (type, key) in _filters) ...[
                    _FilterChip(label: AppStrings.t(key), selected: _filter == type, onTap: () => setState(() => _filter = type)),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: services.isEmpty
                ? Center(
                    child: ValueListenableBuilder<String>(
                      valueListenable: AppStrings.locale,
                      builder: (context, _, __) => Text(
                        AppStrings.t('newcomer_services_empty'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, i) => _ServiceTile(service: services[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.cyclingGreen : AppColors.chip,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: selected ? const Color(0xFF04342C) : AppColors.textPrimary)),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final NewcomerService service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _styleFor(service.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                const SizedBox(height: 1),
                Text('${service.detail} · ${service.walkingMinutes} min med cykel', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _styleFor(NewcomerServiceType type) {
    switch (type) {
      case NewcomerServiceType.sfi:
        return (Icons.school_outlined, const Color(0xFF1F2E3D));
      case NewcomerServiceType.folkhogskola:
        return (Icons.account_balance_outlined, const Color(0xFF1F2E3D));
      case NewcomerServiceType.library:
        return (Icons.menu_book_outlined, const Color(0xFF2E2347));
      case NewcomerServiceType.foodHall:
        return (Icons.bakery_dining_outlined, const Color(0xFF3D2A1F));
    }
  }
}
