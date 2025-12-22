enum ObjectType { deepSky, solarSystem }

class AstronomicalObject {
  final String? proper; // Proper name
  final double ra; // Right Ascension (derajat)
  final double dec; // Declination (derajat)
  final double? dist; // Jarak (parsec)
  final double? pmra; // Proper motion RA
  final double? pmdec; // Proper motion Dec
  final double? rv; // Radial velocity
  final double? mag; // Magnitudo
  final double? absmag; // Absolute Magnitude
  final String? spect; // Spektrum / tipe
  final double? ci; // Color index
  final String? bayer; // Nama Bayer (Greek letter)
  final String? con; // Konstelasi
  final double? lum; // Luminositas
  final String name; // Nama tampilan (proper atau bayer+con)

  AstronomicalObject({
    this.proper,
    required this.ra,
    required this.dec,
    this.dist,
    this.pmra,
    this.pmdec,
    this.rv,
    this.mag,
    this.absmag,
    this.spect,
    this.ci,
    this.bayer,
    this.con,
    this.lum,
    required this.name,
  });

  // Factory constructor dari database Map
  factory AstronomicalObject.fromMap(Map<String, dynamic> map) {
    // Generate display name: prioritas proper name, fallback ke bayer+con
    String displayName = '';
    if (map['proper'] != null && (map['proper'] as String).trim().isNotEmpty) {
      displayName = (map['proper'] as String).trim();
    } else if (map['name'] != null &&
        (map['name'] as String).trim().isNotEmpty) {
      displayName = (map['name'] as String).trim();
    } else if (map['bayer'] != null && map['con'] != null) {
      displayName = '${map['bayer']} ${map['con']}';
    } else {
      displayName = 'Unknown Star';
    }

    return AstronomicalObject(
      proper: map['proper'] as String?,
      ra: (map['ra'] as num).toDouble(),
      dec: (map['dec'] as num).toDouble(),
      dist: map['dist'] != null ? (map['dist'] as num).toDouble() : null,
      pmra: map['pmra'] != null ? (map['pmra'] as num).toDouble() : null,
      pmdec: map['pmdec'] != null ? (map['pmdec'] as num).toDouble() : null,
      rv: map['rv'] != null ? (map['rv'] as num).toDouble() : null,
      mag: map['mag'] != null ? (map['mag'] as num).toDouble() : null,
      absmag: map['absmag'] != null ? (map['absmag'] as num).toDouble() : null,
      spect: map['spect'] as String?,
      ci: map['ci'] != null ? (map['ci'] as num).toDouble() : null,
      bayer: map['bayer'] as String?,
      con: map['con'] as String?,
      lum: map['lum'] != null ? (map['lum'] as num).toDouble() : null,
      name: displayName,
    );
  }

  // Get object type based on available data
  ObjectType get type {
    // Untuk saat ini semua dari HYG adalah deep sky objects (stars)
    return ObjectType.deepSky;
  }

  // Helper untuk mendapatkan deskripsi singkat
  String get description {
    List<String> parts = [];

    if (spect != null) parts.add('Type: $spect');
    if (mag != null) parts.add('Mag: ${mag!.toStringAsFixed(2)}');
    if (con != null) parts.add('in $con');

    return parts.join(' • ');
  }
}
