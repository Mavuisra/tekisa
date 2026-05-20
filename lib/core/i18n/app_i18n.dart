library;

import 'package:flutter/widgets.dart';

import 'locale_controller.dart';

class AppI18n {
  AppI18n._();

  static final Map<String, String> _ln = {
    'Commencer': 'Banda kobanda',
    'Connexion': 'Kokota',
    'Créer un compte': 'Kosala compte',
    'J\'ai déjà un compte': 'Nazali déjà na compte',
    'Se connecter': 'Kokota',
    'Parametres': 'Baparametre',
    'Préférences': 'Makambo ya boponi',
    'Securite du compte': 'Bokengi ya compte',
    'A propos': 'Na ntina ya app',
    'Se deconnecter': 'Kobima na compte',
    'Enregistrer les modifications': 'Kobomba mbongwana',
    'Informations entreprise': 'Ba informations ya entreprise',
    'Langue': 'Monoko',
    'Langue de l’application': 'Monoko ya application',
    'Français': 'Falansé',
    'Lingala': 'Lingala',
    'Format de temps': 'Format ya ngonga',
    'Fuseau horaire': 'Etuka ya ngonga',
    '24 heures': 'Ngonga 24',
    '12 heures (AM/PM)': 'Ngonga 12 (AM/PM)',
    'Étape': 'Etape',
    'Suivant': 'Kolanda',
    'Retour': 'Kozonga',
    'Compte utilisateur': 'Compte ya mosaleli',
    'Profil d’activité': 'Profil ya mosala',
    'Contact et adresse': 'Contact mpe adresi',
    'Nom affiché': 'Kombo oyo emonanaka',
    'Utilisateur': 'Mosaleli',
    'Téléphone personnel': 'Telephone ya moto',
    'Raison sociale': 'Kombo ya entreprise',
    'Nom commercial': 'Kombo ya boteki',
    'Forme juridique': 'Lolenge ya mibeko',
    'Pays': 'Mboka',
    'Province': 'Province',
    'Ville': 'Engumba',
    'Commune': 'Commune',
    'Quartier': 'Kartie',
    'Avenue': 'Avenue',
    'Mot de passe et sessions actives': 'Mot de passe mpe ba session active',
    'Numéro parcelle / porte': 'Numero parcelle / porte',
    'Email entreprise': 'Email ya entreprise',
    'Téléphone entreprise': 'Telephone ya entreprise',
    'Kinshasa (UTC+1)': 'Kinshasa (UTC+1)',
    'Lubumbashi (UTC+2)': 'Lubumbashi (UTC+2)',
    'Paramètres enregistrés.': 'Baparametre ebombami.',
    'Mode hors ligne actif': 'Mode hors ligne ezali kosala',
    'Assistant': 'Mosungi',
    'Actualiser': 'Kobongisa lisusu',
    'Deconnexion': 'Kobima',
    'Alertes': 'Mikakatano',
    'Aujourd\'hui': 'Lelo',
    'Actions prioritaires': 'Misala ya motuya',
    'Chargement...': 'Kozwa...',
    'Charger': 'Kozwa',
    'Analyses avancees': 'Analyse ya likolo',
    'Consulter les tendances de vente et recommandations':
        'Talá ndenge boteki ezali kotambola mpe makanisi',
    'Ouvrir': 'Kofungola',
    'Comptabilite': 'Comptabilite',
    'Rapports SYCOHADA et etats financiers':
        'Ba rapport SYCOHADA mpe etat financier',
  };

  static String text(BuildContext context, String frText) {
    final code = LocaleController.instance.locale.languageCode;
    if (code != 'ln') return frText;
    return _ln[frText] ?? frText;
  }
}

extension AppI18nBuildContext on BuildContext {
  String tr(String frText) => AppI18n.text(this, frText);
}
