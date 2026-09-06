import 'package:flutter/foundation.dart';

/// Système de traduction volontairement simple — pas de génération ARB
/// ni de dépendance supplémentaire, juste une table de correspondance
/// et un ValueNotifier pour que l'UI se redessine au changement de
/// langue. Suffisant pour un pilote ; à migrer vers `flutter gen-l10n`
/// si le nombre de chaînes grossit beaucoup.
///
/// Important, cohérent avec la maquette et la note de synthèse : les
/// noms de rues et l'info trafic officielle restent TOUJOURS en
/// suédois, quelle que soit la langue choisie ici — ce fichier ne
/// traduit que le texte d'interface, jamais les noms de lieux ou de
/// lignes de transport.
class AppStrings {
  static final ValueNotifier<String> locale = ValueNotifier('sv');

  static const Map<String, Map<String, String>> _translations = {
    'welcome_title': {
      'sv': 'Välkommen till Skåne',
      'en': 'Welcome to Skåne',
      'fr': 'Bienvenue en Scanie',
    },
    'welcome_subtitle': {
      'sv': 'Gång- och cykelvägar, väder och realtidsvarningar för hela regionen, från Malmö till Ystad',
      'en': 'Walking and cycling routes, weather and real-time alerts for the whole region, from Malmö to Ystad',
      'fr': 'Itinéraires piétons et cyclables, météo et alertes en temps réel pour toute la région, de Malmö à Ystad',
    },
    'get_started': {
      'sv': 'Kom igång',
      'en': 'Get started',
      'fr': 'Commencer',
    },
    'change_language': {
      'sv': 'Byt språk',
      'en': 'Change language',
      'fr': 'Changer de langue',
    },
    'search_hint': {
      'sv': 'Vart vill du åka?',
      'en': 'Where do you want to go?',
      'fr': 'Où veux-tu aller ?',
    },
    'search_trip_title': {
      'sv': 'Sök resa',
      'en': 'Search trip',
      'fr': 'Rechercher un trajet',
    },
    'mode_cycling': {'sv': 'Cykel', 'en': 'Bike', 'fr': 'Vélo'},
    'mode_walking': {'sv': 'Gång', 'en': 'Walk', 'fr': 'Marche'},
    'mode_transit': {'sv': 'Kollektivt', 'en': 'Transit', 'fr': 'Transport'},
    'newcomer_services_title': {
      'sv': 'Nyanländ i Skåne',
      'en': 'New to Skåne',
      'fr': 'Nouvel arrivant en Scanie',
    },
    'street_names_note': {
      'sv': 'Vägnamn och trafikinformation visas alltid på svenska, resten av appen översätts',
      'en': 'Street names and traffic info are always shown in Swedish, the rest of the app is translated',
      'fr': 'Les noms de rues et les infos trafic restent toujours en suédois, le reste de l\'appli est traduit',
    },
    'station_entrances_subtitle': {
      'sv': 'Ingångar och plattformar',
      'en': 'Entrances and platforms',
      'fr': 'Entrées et quais',
    },
    'station_all_entrances': {
      'sv': 'Alla entréer',
      'en': 'All entrances',
      'fr': 'Toutes les entrées',
    },
    'station_not_surveyed': {
      'sv': 'Ingångarna för denna station har inte kartlagts ännu.',
      'en': 'This station\'s entrances haven\'t been surveyed yet.',
      'fr': 'Les entrées de cette gare n\'ont pas encore été relevées.',
    },
    'micromobility_title': {
      'sv': 'Cyklar och elsparkcyklar',
      'en': 'Bikes and scooters',
      'fr': 'Vélos et trottinettes',
    },
    'micromobility_searching': {
      'sv': 'Söker…',
      'en': 'Searching…',
      'fr': 'Recherche en cours…',
    },
    'micromobility_unavailable': {
      'sv': 'Inte tillgängligt än — partneravtal krävs',
      'en': 'Not available yet — partner agreement required',
      'fr': 'Pas encore disponible — accord partenaire à mettre en place',
    },
    'micromobility_count_nearby': {
      'sv': 'tillgängliga i närheten',
      'en': 'available nearby',
      'fr': 'disponibles à proximité',
    },
    'newcomer_services_subtitle': {
      'sv': 'Praktiska platser nära dig',
      'en': 'Practical places near you',
      'fr': 'Lieux pratiques près de toi',
    },
    'filter_all': {'sv': 'Alla', 'en': 'All', 'fr': 'Tous'},
    'filter_sfi': {'sv': 'Sfi', 'en': 'SFI', 'fr': 'SFI'},
    'filter_library': {'sv': 'Bibliotek', 'en': 'Library', 'fr': 'Bibliothèque'},
    'filter_food_hall': {'sv': 'Saluhall', 'en': 'Food hall', 'fr': 'Halle gourmande'},
    'newcomer_services_empty': {
      'sv': 'Inga tjänster i denna kategori',
      'en': 'No services in this category',
      'fr': 'Aucun service dans cette catégorie',
    },
  };

  /// Renvoie la traduction pour `key` dans la langue courante, ou la
  /// clé elle-même si elle manque (visible en dev, jamais un crash).
  static String t(String key) {
    return _translations[key]?[locale.value] ?? key;
  }

  static void setLocale(String code) {
    if (_translations.values.first.containsKey(code)) {
      locale.value = code;
    }
  }
}
