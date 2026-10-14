# Icon Studio

Application Android personnelle de création et de personnalisation d’icônes, en français. Flutter / Dart, avec une passerelle Android en Kotlin. Sans compte, publicité, serveur ou accès réseau dans l’APK de livraison.

## Installer

- [Télécharger le ZIP avec l’APK](https://github.com/Lucas3646/IconChanger/releases/latest/download/Icon-Studio.zip)
- [Télécharger l’APK directement](https://github.com/Lucas3646/IconChanger/releases/latest/download/Icon-Studio.apk)

Sur le téléphone, téléchargez le fichier avec Chrome. Si vous choisissez le ZIP, extrayez-le dans Fichiers, puis ouvrez `Icon-Studio.apk`. Android demande éventuellement d’autoriser cette source à installer des applications. Validez l’installation. Le navigateur ne peut pas installer un APK automatiquement.

## V1

- Applications lançables installées : nom, icône actuelle, recherche, filtres et état de création.
- Quatre onglets : Applications, Explorer, Studio, Mes icônes.
- Huit collections : Neon Red, Blue, Purple, Minimal Dark, Light, Pastel, Glass, Monochrome.
- 23 logos courants, 24 symboles et import PNG/JPG/WebP via le sélecteur Android.
- Éditeur à 20 calques : images, logos, symboles, texte et initiales ; duplication, ordre de superposition et suppression.
- Zoom, déplacement, cadrage par les limites de l’icône, rotation, opacité ; gestes dans l’aperçu et curseurs précis.
- Fond uni ou dégradé, couleurs libres et code hexadécimal, transparence, arrondis et bordures.
- Effets réels : néon, lueur, ombre, contour, colorisation ; extraction des contours d’une image et suppression des fonds noirs ou blancs par luminosité.
- Historique de 40 modifications, annulation/rétablissement, variantes indépendantes.
- Sauvegarde locale atomique avec copie de secours ; les images importées sont copiées dans le stockage privé.
- Export PNG en 512, 1024 ou 2048 pixels avec transparence, vers un emplacement choisi.
- Association d’une création à une application ; ajout ou mise à jour d’un raccourci épinglé via `ShortcutManager`.
- Thème clair, sombre ou automatique, interface sobre, sans nom de créateur.

## Utilisation

1. Dans Applications, cherchez l’application et ouvrez son éditeur.
2. Dans Fond, choisissez un style rapide ; ou importez un élément dans Calques.
3. Réglez le cadrage dans Réglages et la lumière dans Effets.
4. Enregistrez avec la coche ou appuyez sur Appliquer.
5. Confirmez la demande d’ajout affichée par l’écran d’accueil.

Studio permet également de créer librement sans application. Mes icônes permet d’éditer, dupliquer ou supprimer les créations. Pour recréer un raccourci, rouvrez sa création puis Appliquer. Pour revenir à l’image d’origine, utilisez « Créer l’icône originale » dans le menu de la création.

## Limites réelles

- L’icône originale dans la liste des applications n’est jamais remplacée. L’application ajoute un **raccourci**.
- La forme finale, le badge Icon Studio, la confirmation et le placement sont contrôlés par le launcher. Le badge ne peut pas être supprimé avec cette méthode standard.
- Une demande envoyée n’est pas une confirmation d’ajout : le statut est vérifié auprès du launcher au retour dans l’application.
- Une création déjà épinglée conserve son identité et son raccourci est mis à jour ; créez une variante pour un deuxième raccourci.
- Supprimer une création locale ne supprime pas le raccourci de l’écran d’accueil. Retirez-le manuellement depuis celui-ci.
- Une application désinstallée n’est plus lançable. Le raccourci affiche un message au lieu de planter.
- Applications sans activité de lancement, profils professionnels et espaces privés peuvent ne pas apparaître. Aucun `QUERY_ALL_PACKAGES` n’est demandé.
- Le retrait d’un fond repose sur sa luminosité ; il ne s’agit pas d’une segmentation IA du sujet. Glass est un rendu graphique, sans accès au fond d’écran.
- L’export 2048 px augmente la résolution du fichier, pas le détail d’une petite image importée.
- Désinstaller Icon Studio efface ses créations locales et peut supprimer ses raccourcis. Les PNG exportés restent disponibles.
- Android 10 minimum. La compatibilité de chaque launcher et des futures versions Android doit être vérifiée sur appareil.

## Compiler

Prérequis : Flutter stable compatible Dart 3.9.2+, Android SDK et JDK 17, licences Android acceptées.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Résultat : `build/app/outputs/flutter-apk/app-release.apk`. L’APK universel comprend arm64-v8a (Pixel 9 et Samsung récents), armeabi-v7a et x86_64 (émulateur).

La livraison utilise une clé de signature personnelle dédiée, conservée hors du dépôt. Pour conserver la compatibilité des mises à jour, réutilisez cette clé. Sur un autre environnement, renseignez `android/key.properties` (fichier ignoré par Git) :

```properties
storeFile=/chemin/vers/icon-studio.jks
storePassword=VOTRE_MOT_DE_PASSE
keyPassword=VOTRE_MOT_DE_PASSE
keyAlias=iconstudio
```

Sans ce fichier, une compilation locale utilise la clé de développement : son APK ne pourra pas mettre à jour la livraison signée sans désinstallation. N’ajoutez jamais la clé ou ses mots de passe au dépôt.

## Architecture

- `lib/models` : créations, calques, applications, collections et correspondances de logos.
- `lib/services` : stockage local et passerelle Android.
- `lib/widgets` : moteur de rendu commun à l’aperçu et au PNG, composants et couleurs.
- `lib/screens` : navigation, collections et éditeur.
- `android/.../MainActivity.kt` : visibilité des applications, sélection/export des fichiers, traitement des images, raccourcis et ouverture des applications.
- `test` : isolation des variantes, persistance/récupération, rendu PNG et éditeur sur petit écran.

Aucun root, permission de stockage globale, compte ou dépendance cloud n’est utilisé. Les imports sont limités à 40 Mo et ramenés à 2048 px pour limiter l’usage mémoire. Les ressources des logos sont incluses pour fonctionner hors ligne.

## Ressources et marques

Les SVG proviennent de [Simple Icons](https://simpleicons.org/) et sont distribués sous CC0 (voir `assets/brands/LICENSE.md`). Les noms et logos restent des marques de leurs propriétaires ; aucune affiliation n’est revendiquée. Les symboles Material et les dépendances Flutter conservent leurs licences. Les images importées doivent appartenir à l’utilisateur ou être utilisées avec les droits nécessaires.

Les résultats de vérification et les essais sur émulateur sont consignés dans `VALIDATION.md`.
