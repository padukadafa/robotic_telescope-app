import 'dart:math' as math;

class HorizontalCoordinates {
  final double azimuth; // degrees 0-360 (0 = north)
  final double altitude; // degrees above horizon

  const HorizontalCoordinates({required this.azimuth, required this.altitude});
}

class Astronomy {
  static double _degToRad(double deg) => deg * math.pi / 180.0;
  static double _radToDeg(double rad) => rad * 180.0 / math.pi;

  static double _normalizeDegrees(double deg) {
    final normalized = deg % 360.0;
    return normalized < 0 ? normalized + 360.0 : normalized;
  }

  static double _normalizeHours(double hours) {
    final normalized = hours % 24.0;
    return normalized < 0 ? normalized + 24.0 : normalized;
  }

  static double julianDate(DateTime dateTime) {
    final dt = dateTime.toUtc();
    var year = dt.year;
    var month = dt.month;
    final dayFraction =
        (dt.day +
        (dt.hour +
                (dt.minute + (dt.second + dt.millisecond / 1000.0) / 60.0) /
                    60.0) /
            24.0);

    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();

    final jd =
        (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        dayFraction +
        b -
        1524.5;
    return jd;
  }

  static double greenwichMeanSiderealTime(DateTime dateTime) {
    final jd = julianDate(dateTime);
    final t = (jd - 2451545.0) / 36525.0;
    final gmst =
        280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t -
        t * t * t / 38710000.0;
    return _normalizeDegrees(gmst);
  }

  static double localSiderealTime(DateTime dateTime, double longitudeDeg) {
    final gmst = greenwichMeanSiderealTime(dateTime);
    return _normalizeDegrees(gmst + longitudeDeg);
  }

  static double hourAngle(double lstDeg, double raDeg) {
    return _normalizeDegrees(lstDeg - raDeg);
  }

  static HorizontalCoordinates equatorialToHorizontal({
    required double raDeg,
    required double decDeg,
    required double latitudeDeg,
    required double longitudeDeg,
    required DateTime dateTime,
  }) {
    final lst = localSiderealTime(dateTime, longitudeDeg);
    final ha = hourAngle(lst, raDeg);

    final haRad = _degToRad(ha);
    final decRad = _degToRad(decDeg);
    final latRad = _degToRad(latitudeDeg);

    final sinAlt =
        math.sin(decRad) * math.sin(latRad) +
        math.cos(decRad) * math.cos(latRad) * math.cos(haRad);
    final altitude = _radToDeg(math.asin(sinAlt));

    final azRad = math.atan2(
      -math.sin(haRad) * math.cos(decRad),
      math.sin(decRad) * math.cos(latRad) -
          math.cos(decRad) * math.sin(latRad) * math.cos(haRad),
    );
    final azimuth = _normalizeDegrees(_radToDeg(azRad));

    return HorizontalCoordinates(azimuth: azimuth, altitude: altitude);
  }

  static bool isAboveHorizon({
    required double raDeg,
    required double decDeg,
    required double latitudeDeg,
    required double longitudeDeg,
    required DateTime dateTime,
    double minAltitudeDeg = 0,
  }) {
    // HYG catalog stores RA in hours (0-24). Convert to degrees when the
    // provided value looks like hours so horizon checks stay accurate.
    final normalizedRaDeg = raDeg <= 24 ? raDeg * 15 : raDeg;

    final coords = equatorialToHorizontal(
      raDeg: normalizedRaDeg,
      decDeg: decDeg,
      latitudeDeg: latitudeDeg,
      longitudeDeg: longitudeDeg,
      dateTime: dateTime,
    );

    return coords.altitude >= minAltitudeDeg;
  }
}
