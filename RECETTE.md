# Procès-verbal de recette — Studio TikTok

Vérification des **critères de recette (cahier des charges, §11)**. La suite de tests est verte :
**25 tests unitaires** (`flutter test test/`) + **16 tests e2e** (`integration_test/app_e2e_test.dart`) + `flutter analyze` sans erreur.

> Écart assumé vs cahier : l'API n'est plus Claude/Anthropic mais **Ollama Cloud** (modèle gratuit `gemma4:31b` par défaut), à la demande du propriétaire. Les messages d'erreur §7 sont conservés et adaptés.

| # | Critère (§11) | Statut | Vérification |
|---|---------------|--------|--------------|
| 1 | Générations consécutives → script valide, sans plantage | ✅ | e2e « Rrihla kemla » + nettoyage/validation JSON (` ```json `, 1er `{`…dernier `}`, rejet si aucun segment) |
| 2 | Segments couvrent 0→N sans trou ni chevauchement | ⚙️ | Imposé par le prompt (`prompts.dart`) + `duration` validée ; dépend de la sortie du modèle |
| 3 | Exemples de code s'exécutent | ⚙️ | Qualité de contenu (relecture avant tournage) ; règle « code correct < 12 lignes » dans le prompt |
| 4 | Clé invalide → message 401, sans plantage | ✅ | e2e « 401 » : affiche « المفتاح موش صحيح ولا ما عندوش الحق… », aucun `ResultScreen`, rien enregistré |
| 5 | Mode avion → « pas de connexion » + saisie conservée | ✅ | `errorMessage` gère `SocketException`/`TimeoutException` ; les `TextEditingController` ne sont jamais vidés sur erreur |
| 6 | Clé persiste après redémarrage + absente de l'APK | ✅ | e2e « المفتاح والموديل يقعدو محفوظين » ; clé dans `flutter_secure_storage` (Android Keystore), jamais dans le code/APK |
| 7 | Téléprompteur défile jusqu'au dernier segment et s'arrête seul | ✅ | e2e Teleprompter (offset > 0 au play, stop à `maxScrollExtent`) ; `AutoScroller` |
| 8 | Chaque bouton Copier → bon texte au presse-papiers | ✅ | e2e « انسخ الكل » (clipboard contient titre, `[10–20s]`, hashtags) |
| 9 | 1000 scripts → recherche < 200 ms, suppression immédiate, favoris persistent | ✅ | `history_db_test` : recherche sur 1000 lignes **< 200 ms** (mesurée), favoris/suppression ✅ |
| 10 | Interface de droite à gauche, sans texte coupé | ✅ | `Directionality.rtl` global ; mode **sombre** uniquement (choix de design — charte graphique) |
| 11 | `flutter analyze` sans erreur ; APK de prod < 25 Mo | ✅ | `No issues found` ; `app-arm64-v8a-release.apk` = **~20 Mo** < 25 Mo |

## Couverture des exigences fonctionnelles

Toutes les exigences **F01→F24** sont implémentées (Must/Should/Could), plus des modules au-delà du périmètre V1 :

- **F01–F06** Création : thèmes, idée libre, mode de présentation, durée, 5 idées suggérées, génération avec indicateur de chargement.
- **F07–F11** Résultat : segments 0→N, code sélectionnable (LTR), étapes de tournage, légende/hashtags/conseils, copie séparée.
- **F12–F15** Téléprompteur : défilement sur fond noir, play/pause/début, vitesse ×0,4→×4 + taille 20→64, **écran maintenu allumé** (wakelock).
- **F16–F17, F21–F24** Historique : **SQLite (drift)** illimité, rouvrir/supprimer, **recherche**, **favoris**, **filtre par thème + tri**, **marquer publié**.
- **F18–F20** Réglages : clé API (saisie/masque/enregistre/efface), choix du modèle, **plafond mensuel + alerte 80 %**.

### Modules hors périmètre V1 (bonus)
Enregistrement caméra (téléprompteur), calendrier de publication + rappels (notifications locales), partage/export `.txt`, écran de lancement, charte graphique complète, icône + assets Play Store, signature release + AAB.

## Non fonctionnel (§5)
- **Compatibilité** : Android 7.0 (API 24)+. **Thèmes** : sombre (choix de design) + RTL.
- **Fiabilité** : messages d'erreur clairs en darija, sans plantage, saisie conservée.
- **Taille** : APK arm64 ~20 Mo (< 25 Mo).
- **Maintenabilité** : `flutter analyze` propre ; prompts isolés dans `prompts.dart`.
- **Accessibilité** : `tooltip` (libellés TalkBack) sur les icônes d'action.

_Légende : ✅ vérifié automatiquement / ⚙️ dépend de la qualité de sortie du modèle (recette manuelle)._
