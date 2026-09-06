# Vägvis — checklist du premier `flutter run`

Rien dans ce projet n'a été compilé ni testé (voir README). Cette liste
classe ce qui va probablement casser en premier, du plus probable au
moins probable, avec où regarder pour chaque cas. L'objectif n'est pas
d'éviter les erreurs — c'est normal d'en avoir — mais de savoir tout de
suite si une erreur vient d'un oubli de configuration ou d'un vrai bug.

## 1. Ça ne compile même pas (`flutter analyze` ou `flutter run` échoue direct)

- **`flutter create .` pas encore lancé** : si android/ et ios/ n'existent
  pas dans le dossier, Flutter n'a rien à builder. Lance `flutter create .`
  à la racine du projet en premier.
- **Version de `mapbox_maps_flutter` différente de celle prévue** : c'est
  le paquet le plus susceptible d'avoir changé de forme d'API entre le
  moment où ce code a été écrit et le moment où tu fais `flutter pub get`.
  Si `CameraOptions`, `Position`, `LocationComponentSettings` ou
  `StyleLoadedEventData` ne sont pas reconnus, ouvre le changelog du
  paquet sur pub.dev et compare avec la version installée.
- **`String.fromEnvironment` renvoie la valeur par défaut sans erreur** :
  ce n'est pas un crash, donc facile à rater. Si la carte reste grise ou
  que les itinéraires échouent silencieusement, vérifie d'abord que le
  token est bien passé (`--dart-define=MAPBOX_TOKEN=...`), pas juste que
  le code compile.

## 2. Ça compile mais rien ne s'affiche

- **Carte grise/vide** : token Mapbox manquant ou invalide. Teste-le
  d'abord isolément avec une requête simple avant de chercher ailleurs :
  `curl "https://api.mapbox.com/geocoding/v5/mapbox.places/Malmo.json?access_token=TON_TOKEN"`
  Si ça renvoie une erreur d'auth, le token est le problème, pas le code
  Flutter.
- **Calques cyclables/piétons absents** : deux causes possibles à
  distinguer — (a) `_onStyleLoaded` ne s'est jamais déclenché (regarde les
  logs pour l'exception attrapée dans le `catch`), ou (b) Overpass a
  renvoyé une réponse vide pour la bbox donnée (teste l'URL Overpass
  directement dans un navigateur ou via curl, indépendamment de l'app).
- **Alertes toujours vides** : le schéma SQL (`alerts_schema_fixed.sql`)
  doit avoir été exécuté dans Supabase AVANT de lancer l'app — sinon
  `fetchNearbyAlerts` échoue sur une fonction RPC inexistante. Vérifie
  dans le Dashboard Supabase (Database → Functions) que `get_nearby_alerts`
  apparaît bien.

## 3. Ça s'affiche mais le contenu est faux ou vide

- **Recherche de lieu (PlaceSearchScreen) ne renvoie rien** : la structure
  de réponse de Geocoding v6 (`geocoding_service.dart`) n'a jamais été
  vérifiée avec un vrai appel — si `_results` reste vide alors que la
  requête réseau réussit (regarde le code retour HTTP), le problème est
  probablement le nom des champs JSON (`name`, `full_address`) qui a pu
  changer. Imprime `response.body` brut pour comparer avec ce que le code
  attend.
- **Météo absente sans message d'erreur** : volontaire — le bandeau
  météo se masque silencieusement si l'appel échoue (voir le `catch` vide
  dans `_fetchWeather`). Pour déboguer, ajoute temporairement un
  `debugPrint` dans ce `catch` plutôt que de chercher un crash qui
  n'existe pas.
- **Itinéraire "Snabbaste vägen" avec une durée qui semble fausse** :
  vérifie le profil demandé (`cycling` vs `walking`) correspond bien à
  l'onglet sélectionné — c'est le genre d'erreur silencieuse facile à
  introduire en modifiant `_setMode` plus tard.

## 4. Erreurs qui n'apparaîtront qu'à l'usage réel, pas au premier lancement

- **Overpass qui timeout ou refuse la requête** après plusieurs
  rechargements de carte — rappel du README : Overpass n'est pas fait
  pour un usage répété en direct. Si ça arrive dès les tests, c'est le
  signal qu'il faut passer au cache PostGIS plus tôt que prévu.
- **Un même utilisateur votant plusieurs fois sur une alerte** : normalement
  empêché par la contrainte `PRIMARY KEY (alert_id, user_id)` sur
  `alert_votes` — si ça ne bloque pas, vérifie que `user_id` est bien
  rempli (pas `null`) au moment du vote.

## Comment prioriser si plusieurs choses cassent en même temps

Dans l'ordre : (1) le token Mapbox d'abord, tant que la carte n'affiche
rien le reste ne peut pas être testé ; (2) le schéma Supabase ensuite,
puisque les alertes en dépendent ; (3) le reste au cas par cas. Ne cherche
pas à tout corriger d'un coup — un projet qui avance, c'est une erreur
réglée puis testée, pas dix hypothèses empilées avant de relancer.
