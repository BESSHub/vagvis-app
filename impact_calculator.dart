/// Calcule le CO₂ et l'argent économisés en choisissant vélo/marche
/// plutôt que la voiture, à partir de la distance d'un trajet.
///
/// HYPOTHÈSES À GARDER VISIBLES, PAS CACHÉES DANS LE CODE :
/// - Émissions moyennes voiture : 150 g CO₂/km. C'est une estimation
///   d'usage réel du parc automobile existant (plus élevée que les
///   ~108 g/km visés pour les voitures neuves vendues en UE) — à
///   ajuster si tu trouves un chiffre officiel suédois plus précis
///   (Trafikverket ou Naturvårdsverket publient ce genre de statistique).
/// - Coût moyen voiture : 3 SEK/km (carburant + usure + entretien,
///   hors assurance/achat). C'est un ordre de grandeur, pas un calcul
///   précis — présente-le comme tel à l'utilisateur, jamais comme un
///   chiffre exact.
class ImpactCalculator {
  static const double _carEmissionsGramsPerKm = 150;
  static const double _carCostSekPerKm = 3.0;

  static double co2SavedKg(double distanceMeters) {
    final km = distanceMeters / 1000;
    return (km * _carEmissionsGramsPerKm) / 1000;
  }

  static double moneySavedSek(double distanceMeters) {
    final km = distanceMeters / 1000;
    return km * _carCostSekPerKm;
  }
}
