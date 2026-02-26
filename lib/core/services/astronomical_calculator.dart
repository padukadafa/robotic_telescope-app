import 'dart:math';

/// Calculates astronomical positions of Sun and Moon using ephemeris algorithms
class AstronomicalCalculator {
  /// Calculate Julian Date from DateTime
  static double calculateJulianDate(DateTime dateTime) {
    final utc = dateTime.toUtc();

    int year = utc.year;
    int month = utc.month;
    double day =
        utc.day + utc.hour / 24.0 + utc.minute / 1440.0 + utc.second / 86400.0;

    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();

    final jd =
        (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;

    return jd;
  }

  /// Calculate solar position (RA, Dec) using simplified algorithm
  static Map<String, double> calculateSunPosition(DateTime dateTime) {
    final jd = calculateJulianDate(dateTime);
    final n = jd - 2451545.0; // Days since J2000.0

    // Mean longitude of Sun (degrees)
    final l = (280.460 + 0.9856474 * n) % 360;

    // Mean anomaly (degrees)
    final g = (357.528 + 0.9856003 * n) % 360;
    final gRad = g * pi / 180.0;

    // Ecliptic longitude (degrees)
    final lambda = l + 1.915 * sin(gRad) + 0.020 * sin(2 * gRad);
    final lambdaRad = lambda * pi / 180.0;

    // Obliquity of ecliptic (degrees)
    final epsilon = 23.439 - 0.0000004 * n;
    final epsilonRad = epsilon * pi / 180.0;

    // Right Ascension and Declination
    final ra = atan2(cos(epsilonRad) * sin(lambdaRad), cos(lambdaRad));
    final dec = asin(sin(epsilonRad) * sin(lambdaRad));

    return {
      'ra': ra * 180.0 / pi, // degrees
      'dec': dec * 180.0 / pi, // degrees
    };
  }

  /// Calculate lunar position (RA, Dec) using simplified algorithm
  static Map<String, double> calculateMoonPosition(DateTime dateTime) {
    final jd = calculateJulianDate(dateTime);
    final t = (jd - 2451545.0) / 36525.0; // Julian centuries since J2000

    // Mean longitude of Moon (degrees)
    final l = (218.316 + 481267.881 * t) % 360;

    // Mean elongation (degrees)
    final d = (297.850 + 445267.112 * t) % 360;
    final dRad = d * pi / 180.0;

    // Sun's mean anomaly (degrees)
    final m = (357.529 + 35999.050 * t) % 360;
    final mRad = m * pi / 180.0;

    // Moon's mean anomaly (degrees)
    final mPrime = (134.963 + 477198.868 * t) % 360;
    final mPrimeRad = mPrime * pi / 180.0;

    // Longitude correction
    final lambda =
        l +
        6.289 * sin(mPrimeRad) +
        1.274 * sin(2 * dRad - mPrimeRad) +
        0.658 * sin(2 * dRad) +
        0.214 * sin(2 * mPrimeRad) -
        0.186 * sin(mRad);

    // Latitude
    final beta =
        5.128 * sin((93.272 + 483202.018 * t) * pi / 180.0) +
        0.280 * sin((228.235 + 960400.890 * t) * pi / 180.0);

    final lambdaRad = lambda * pi / 180.0;
    final betaRad = beta * pi / 180.0;

    // Obliquity of ecliptic
    final epsilon = 23.439 - 0.013 * t;
    final epsilonRad = epsilon * pi / 180.0;

    // Convert ecliptic to equatorial coordinates
    final ra = atan2(
      sin(lambdaRad) * cos(epsilonRad) - tan(betaRad) * sin(epsilonRad),
      cos(lambdaRad),
    );

    final dec = asin(
      sin(betaRad) * cos(epsilonRad) +
          cos(betaRad) * sin(epsilonRad) * sin(lambdaRad),
    );

    return {
      'ra': ra * 180.0 / pi, // degrees
      'dec': dec * 180.0 / pi, // degrees
    };
  }

  /// Convert RA/Dec to Altitude/Azimuth
  static Map<String, double> raDecToAltAz({
    required double ra,
    required double dec,
    required double latitude,
    required double longitude,
    required DateTime dateTime,
  }) {
    final jd = calculateJulianDate(dateTime);

    // Local Sidereal Time (degrees)
    final gmst = (280.46061837 + 360.98564736629 * (jd - 2451545.0)) % 360;
    final lst = (gmst + longitude) % 360;

    // Hour Angle (degrees)
    final ha = (lst - ra) % 360;
    final haRad = ha * pi / 180.0;
    final decRad = dec * pi / 180.0;
    final latRad = latitude * pi / 180.0;

    // Calculate Altitude
    final sinAlt =
        sin(latRad) * sin(decRad) + cos(latRad) * cos(decRad) * cos(haRad);
    final alt = asin(sinAlt) * 180.0 / pi;

    // Calculate Azimuth
    final cosAz =
        (sin(decRad) - sin(latRad) * sinAlt) /
        (cos(latRad) * cos(asin(sinAlt)));

    var az = acos(cosAz.clamp(-1.0, 1.0)) * 180.0 / pi;

    // Correct azimuth quadrant
    if (sin(haRad) > 0) {
      az = 360.0 - az;
    }

    return {'altitude': alt, 'azimuth': az};
  }

  /// Calculate Sun's current Altitude and Azimuth
  static Map<String, double> calculateSunAltAz({
    required double latitude,
    required double longitude,
    required DateTime dateTime,
  }) {
    final sunPos = calculateSunPosition(dateTime);
    return raDecToAltAz(
      ra: sunPos['ra']!,
      dec: sunPos['dec']!,
      latitude: latitude,
      longitude: longitude,
      dateTime: dateTime,
    );
  }

  /// Calculate Moon's current Altitude and Azimuth
  static Map<String, double> calculateMoonAltAz({
    required double latitude,
    required double longitude,
    required DateTime dateTime,
  }) {
    final moonPos = calculateMoonPosition(dateTime);
    return raDecToAltAz(
      ra: moonPos['ra']!,
      dec: moonPos['dec']!,
      latitude: latitude,
      longitude: longitude,
      dateTime: dateTime,
    );
  }

  /// Calculate angular distance between two points (in degrees)
  static double calculateAngularDistance({
    required double alt1,
    required double az1,
    required double alt2,
    required double az2,
  }) {
    final alt1Rad = alt1 * pi / 180.0;
    final az1Rad = az1 * pi / 180.0;
    final alt2Rad = alt2 * pi / 180.0;
    final az2Rad = az2 * pi / 180.0;

    // Haversine formula for angular distance on sphere
    final dAlt = alt2Rad - alt1Rad;
    final dAz = az2Rad - az1Rad;

    final a =
        pow(sin(dAlt / 2), 2) +
        cos(alt1Rad) * cos(alt2Rad) * pow(sin(dAz / 2), 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return c * 180.0 / pi; // degrees
  }
}
