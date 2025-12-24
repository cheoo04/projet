/// Données géographiques de Côte d'Ivoire
/// Villes et communes pour la livraison

class CoteIvoireLocations {
  /// Liste des villes principales avec leurs communes
  static const Map<String, List<String>> villesCommunes = {
    'Abidjan': [
      'Abobo',
      'Adjamé',
      'Anyama',
      'Attécoubé',
      'Bingerville',
      'Cocody',
      'Koumassi',
      'Marcory',
      'Plateau',
      'Port-Bouët',
      'Treichville',
      'Yopougon',
      'Songon',
    ],
    'Yamoussoukro': [
      'Yamoussoukro Centre',
      'Attiégouakro',
      'Kossou',
    ],
    'Bouaké': [
      'Bouaké Centre',
      'Dar Es Salam',
      'Zone Industrielle',
      'Koko',
      'N\'Gattakro',
      'Ahougnanssou',
      'Belleville',
      'Air France',
    ],
    'San-Pédro': [
      'San-Pédro Centre',
      'Bardot',
      'Cité',
      'Lac',
      'Seweke',
      'Zimbabwe',
    ],
    'Daloa': [
      'Daloa Centre',
      'Tazibouo',
      'Orly',
      'Lobia',
      'Garage',
      'Huberson',
    ],
    'Korhogo': [
      'Korhogo Centre',
      'Petit Paris',
      'Soba',
      'Koko',
      'Mongaha',
    ],
    'Man': [
      'Man Centre',
      'Domoraud',
      'Libreville',
      'Kpanpli',
    ],
    'Gagnoa': [
      'Gagnoa Centre',
      'Dioulabougou',
      'Garahio',
    ],
    'Abengourou': [
      'Abengourou Centre',
      'Agnibelekrou',
    ],
    'Divo': [
      'Divo Centre',
      'Yaokro',
    ],
    'Grand-Bassam': [
      'Grand-Bassam Ville',
      'Quartier France',
      'Azuretti',
      'Mondoukou',
      'Modeste',
    ],
    'Adzopé': [
      'Adzopé Centre',
    ],
    'Agboville': [
      'Agboville Centre',
    ],
    'Bondoukou': [
      'Bondoukou Centre',
    ],
    'Bouna': [
      'Bouna Centre',
    ],
    'Dabou': [
      'Dabou Centre',
    ],
    'Dimbokro': [
      'Dimbokro Centre',
    ],
    'Duékoué': [
      'Duékoué Centre',
    ],
    'Ferkessédougou': [
      'Ferkessédougou Centre',
    ],
    'Guiglo': [
      'Guiglo Centre',
    ],
    'Issia': [
      'Issia Centre',
    ],
    'Katiola': [
      'Katiola Centre',
    ],
    'Oumé': [
      'Oumé Centre',
    ],
    'Sassandra': [
      'Sassandra Centre',
    ],
    'Séguéla': [
      'Séguéla Centre',
    ],
    'Soubré': [
      'Soubré Centre',
    ],
    'Toumodi': [
      'Toumodi Centre',
    ],
    'Tiassalé': [
      'Tiassalé Centre',
    ],
  };

  /// Liste des villes triées par population/importance
  static List<String> get villes => villesCommunes.keys.toList();

  /// Obtenir les communes d'une ville
  static List<String> getCommunesPourVille(String ville) {
    return villesCommunes[ville] ?? [];
  }

  /// Rechercher une ville
  static List<String> rechercherVilles(String query) {
    if (query.isEmpty) return villes;
    final lowerQuery = query.toLowerCase();
    return villes
        .where((v) => v.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Rechercher une commune dans une ville
  static List<String> rechercherCommunes(String ville, String query) {
    final communes = getCommunesPourVille(ville);
    if (query.isEmpty) return communes;
    final lowerQuery = query.toLowerCase();
    return communes
        .where((c) => c.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
