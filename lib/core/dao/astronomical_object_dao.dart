import 'package:sqflite/sqflite.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';
import 'package:robotic_telescope/core/services/database_helper.dart';

class AstronomicalObjectDao {
  final DatabaseHelper _databaseHelper;

  AstronomicalObjectDao(this._databaseHelper);

  // Fetch objects with pagination
  Future<List<AstronomicalObject>> getObjects({
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    double? minMagnitude,
    double? maxMagnitude,
    String? constellation,
  }) async {
    final db = await _databaseHelper.database;

    // Build WHERE clause
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    // Search by name (proper or bayer+con)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add(
        '(proper LIKE ? OR name LIKE ? OR (bayer || " " || con) LIKE ?)',
      );
      String searchPattern = '%$searchQuery%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
    }

    // Filter by magnitude range
    if (minMagnitude != null) {
      whereClauses.add('mag >= ?');
      whereArgs.add(minMagnitude);
    }
    if (maxMagnitude != null) {
      whereClauses.add('mag <= ?');
      whereArgs.add(maxMagnitude);
    }

    // Filter by constellation
    if (constellation != null && constellation.isNotEmpty) {
      whereClauses.add('con = ?');
      whereArgs.add(constellation);
    }

    String whereClause = whereClauses.isEmpty ? '' : whereClauses.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'stars',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'mag ASC', // Order by magnitude (brightest first)
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => AstronomicalObject.fromMap(map)).toList();
  }

  // Get total count of objects (for pagination info)
  Future<int> getTotalCount({
    String? searchQuery,
    double? minMagnitude,
    double? maxMagnitude,
    String? constellation,
  }) async {
    final db = await _databaseHelper.database;

    // Build WHERE clause (sama dengan getObjects)
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add(
        '(proper LIKE ? OR name LIKE ? OR (bayer || " " || con) LIKE ?)',
      );
      String searchPattern = '%$searchQuery%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
    }

    if (minMagnitude != null) {
      whereClauses.add('mag >= ?');
      whereArgs.add(minMagnitude);
    }
    if (maxMagnitude != null) {
      whereClauses.add('mag <= ?');
      whereArgs.add(maxMagnitude);
    }

    if (constellation != null && constellation.isNotEmpty) {
      whereClauses.add('con = ?');
      whereArgs.add(constellation);
    }

    String whereClause = whereClauses.isEmpty ? '' : whereClauses.join(' AND ');

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM stars ${whereClause.isEmpty ? "" : "WHERE $whereClause"}',
      whereArgs.isEmpty ? null : whereArgs,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get object by name
  Future<AstronomicalObject?> getObjectByName(String name) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'stars',
      where: 'proper = ? OR name = ?',
      whereArgs: [name, name],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return AstronomicalObject.fromMap(maps.first);
  }

  // Get brightest stars
  Future<List<AstronomicalObject>> getBrightestStars({int limit = 50}) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'stars',
      where: 'mag IS NOT NULL',
      orderBy: 'mag ASC',
      limit: limit,
    );

    return maps.map((map) => AstronomicalObject.fromMap(map)).toList();
  }

  // Get all unique constellations
  Future<List<String>> getConstellations() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT con FROM stars WHERE con IS NOT NULL ORDER BY con',
    );

    return maps.map((map) => map['con'] as String).toList();
  }

  // Get objects by constellation
  Future<List<AstronomicalObject>> getObjectsByConstellation(
    String constellation, {
    int limit = 20,
    int offset = 0,
  }) async {
    return getObjects(
      constellation: constellation,
      limit: limit,
      offset: offset,
    );
  }
}
