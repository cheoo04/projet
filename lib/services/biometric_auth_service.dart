// Point d'entrée du service d'authentification biométrique.
// Le reste de l'app importe toujours ce fichier (inchangé), mais le contenu réel
// vient de biometric_auth_service_web.dart (jamais de local_auth) ou
// biometric_auth_service_mobile.dart (avec local_auth), choisi à la compilation
// selon la plateforme cible. Cela permet de garder local_auth hors du bundle web.

export 'biometric_auth_types.dart';
export 'biometric_auth_service_web.dart'
    if (dart.library.io) 'biometric_auth_service_mobile.dart';