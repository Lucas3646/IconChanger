# Vérification de la V1

Les vérifications ci-dessous distinguent les tests exécutés des validations encore nécessaires sur les téléphones physiques.

## Automatisé

- `flutter analyze` : aucune anomalie signalée.
- `flutter test` : cinq tests réussis.
- Une variante conserve les réglages et l’association, possède un identifiant de raccourci distinct et n’altère pas le modèle original.
- La bibliothèque est relue après redémarrage du stockage ; suppression et restauration de la copie de secours sont vérifiées.
- Un véritable PNG 512 × 512 est décodé et ses pixels contrôlés : coins transparents et logo néon coloré présent.
- L’éditeur s’affiche sur une surface de 360 × 640 pixels et ses onglets s’ouvrent sans débordement de mise en page.

- L’accueil reste utilisable sur un petit écran avec du texte agrandi à 130 %.

## Android

Émulateur Android 15 / API 35, Pixel Launcher, APK de livraison signé en mode release. Aucun téléphone physique n’a été manipulé.

- Compilation de l’APK universel : réussie ; minimum API 29, cible API 36.
- Signature APK v2 RSA 2048 : vérifiée avec `apksigner` ; certificat dédié `CN=Icon Studio`.
- Installation puis réinstallation avec conservation des données : réussies.
- Liste réelle des applications et navigation vers l’éditeur : exécutées.
- Style Neon Red appliqué au logo Chrome ; demande d’épinglage, confirmation native et raccourci enregistré par Pixel Launcher : exécutés.
- Mise à jour de ce même raccourci sans création d’un doublon : exécutée et confirmée par le retour natif.
- Clic sur ce raccourci : ouverture de `com.android.chrome/...Main` confirmée dans les événements Android. Chrome a ensuite affiché son accueil de première utilisation.
- Import réel d’un PNG de test depuis le sélecteur Documents Android : exécuté.
- Extraction des contours par le code Kotlin et rendu néon rouge dans l’aperçu : exécutés.
- Sauvegarde de cette création et export vers Downloads via le sélecteur Android : exécutés.
- PNG exporté relu sur le disque : 1024 × 1024, RGBA, coin transparent ; effet lumineux présent.
- Aucun crash de l’application détecté dans les journaux Android pendant ces parcours.

Les essais n’établissent pas une compatibilité universelle entre launchers. Le badge et le cercle de présentation autour du raccourci ont été observés sur Pixel Launcher, conformément aux limitations annoncées.

## À vérifier sur appareil

Pixel 9 et Samsung de l’utilisateur : confirmation d’ajout, emplacement final, forme, badge, mise à jour du raccourci et restrictions propres à Pixel Launcher / One UI Home. Aucun essai sur ces téléphones ne sera revendiqué avant d’avoir eu lieu.
