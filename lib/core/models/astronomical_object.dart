class AstronomicalObject {
  final String name;
  final String type;
  final double ra; // Right Ascension in hours
  final double dec; // Declination in degrees
  final double magnitude;
  final String description;

  AstronomicalObject({
    required this.name,
    required this.type,
    required this.ra,
    required this.dec,
    required this.magnitude,
    required this.description,
  });
}
