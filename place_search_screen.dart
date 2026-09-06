import 'dart:async';
import 'package:flutter/material.dart';
import '../services/geocoding_service.dart';
import '../theme/app_theme.dart';

/// Écran de recherche de lieu — retourne un GeocodingResult via
/// Navigator.pop quand l'utilisateur choisit une suggestion.
class PlaceSearchScreen extends StatefulWidget {
  final String title;
  final List<double>? proximity;

  const PlaceSearchScreen({super.key, required this.title, this.proximity});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final _geocodingService = GeocodingService(
    accessToken: const String.fromEnvironment('MAPBOX_TOKEN', defaultValue: 'YOUR_MAPBOX_TOKEN'),
  );
  final _controller = TextEditingController();
  Timer? _debounce;
  List<GeocodingResult> _results = [];
  bool _loading = false;

  // Attendre que l'utilisateur arrête de taper avant d'interroger l'API —
  // évite un appel réseau à chaque lettre.
  static const _debounceDuration = Duration(milliseconds: 350);

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await _geocodingService.search(query, proximity: widget.proximity);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.title,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.cyclingGreen))
          : ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) {
                final result = _results[i];
                return ListTile(
                  leading: const Icon(Icons.place_outlined, color: AppColors.textSecondary, size: 20),
                  title: Text(result.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5)),
                  subtitle: result.fullAddress != null
                      ? Text(result.fullAddress!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5))
                      : null,
                  onTap: () => Navigator.of(context).pop(result),
                );
              },
            ),
    );
  }
}
