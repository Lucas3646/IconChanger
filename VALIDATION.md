# Vérification de la V1

Les vérifications ci-dessous distinguent les tests exécutés des validations encore nécessaires sur les téléphones physiques.

## Automatisé

- `flutter analyze` : aucune anomalie signalée.
- `flutter test` : dix tests réussis.
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

## Mise à jour 1.0.1

- Le choix d’application distingue explicitement le widget sans badge du raccourci classique ; ce parcours est vérifié par un sixième test.
- Les raccourcis utilisent un bitmap adaptatif avec un fond correspondant à la création, au lieu d’un bitmap ordinaire normalisé sur un cercle blanc.
- Le widget affiche directement le PNG sur une surface transparente, sans badge de raccourci, et ouvre l’application associée.
- La configuration des widgets est conservée dans le stockage privé. Les créations préparées restent sélectionnables dans le sélecteur manuel de widgets si l’ajout direct n’est pas pris en charge.
- Le widget n’est pas une icône système : son espace, ses marges et son redimensionnement dépendent du launcher, et il ne se range pas dans un dossier d’applications.

## Catalogue prioritaire

- Présence exacte des 31 applications demandées, sans doublon, et validité des quatre compositions : vérifiées par test.
- YouTube Music distingué de YouTube ; Samsung Browser distingué d’un navigateur simplement nommé Internet ; noms génériques et paquet Wilgo : vérifiés.
- Illustrations des jeux préservées en Signature et utilisation du fichier de contours en Néon : vérifiées.
- Chaque logo vectoriel utilisé par les profils prioritaires est décodé et rendu dans un vrai PNG, avec pixels visibles et coins transparents : vérifié.
- Pour les applications sans SVG intégré, les visuels réels ne peuvent être vérifiés qu’avec l’application installée ou une image importée. Les 31 applications ne sont pas toutes installées dans l’émulateur.

### Essai du widget sans badge

Sur un émulateur propre Android 12 / API 31, avec Pixel Launcher : ajout du widget confirmé par la fenêtre système ; PNG effectivement affiché sur l’écran d’accueil sans badge ni cercle blanc ajouté ; clic sur le widget ouvrant `com.android.chrome/...Main` confirmé par les activités Android. La création testée était un logo Chrome rouge sur fond noir. Le placement et les marges restent ceux du launcher.

L’émulateur Android 15 utilisé au premier développement a présenté des blocages de son interface système lors de cette nouvelle session ; les nouvelles vérifications de widget sont donc attribuées à Android 12, et non à cet environnement instable. Les téléphones Pixel 9 et Galaxy S23 n’ont pas été pilotés pour ces essais.

Après ajustement des dimensions minimales, le launcher propose bien un widget **1 × 1**, confirmé dans la fenêtre native d’ajout de l’APK final. La signature de la mise à jour correspond à celle de la V1 et l’installation par-dessus conserve la bibliothèque.
