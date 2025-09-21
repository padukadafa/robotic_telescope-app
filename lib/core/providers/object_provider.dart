import 'package:flutter/foundation.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';

class ObjectProvider extends ChangeNotifier {
  AstronomicalObject? _selectedObject;
  String _searchQuery = '';

  AstronomicalObject? get selectedObject => _selectedObject;
  String get searchQuery => _searchQuery;

  final List<AstronomicalObject> _objects = [
    AstronomicalObject(
      name: 'Sirius',
      type: 'Star',
      ra: 6.75,
      dec: -16.72,
      magnitude: -1.46,
      description: 'Brightest star in the night sky',
    ),
    AstronomicalObject(
      name: 'Vega',
      type: 'Star',
      ra: 18.62,
      dec: 38.78,
      magnitude: 0.03,
      description: 'Second brightest star in northern hemisphere',
    ),
    AstronomicalObject(
      name: 'Betelgeuse',
      type: 'Star',
      ra: 5.92,
      dec: 7.41,
      magnitude: 0.42,
      description: 'Red supergiant star in Orion',
    ),
    AstronomicalObject(
      name: 'Andromeda Galaxy',
      type: 'Galaxy',
      ra: 10.68,
      dec: 41.27,
      magnitude: 3.44,
      description: 'Nearest major galaxy to the Milky Way',
    ),
    AstronomicalObject(
      name: 'Orion Nebula',
      type: 'Nebula',
      ra: 5.59,
      dec: -5.45,
      magnitude: 4.0,
      description: 'Famous emission nebula in Orion',
    ),
    AstronomicalObject(
      name: 'Jupiter',
      type: 'Planet',
      ra: 0.0, // Will be updated with current position
      dec: 0.0,
      magnitude: -2.0,
      description: 'Largest planet in our solar system',
    ),
    AstronomicalObject(
      name: 'Saturn',
      type: 'Planet',
      ra: 0.0,
      dec: 0.0,
      magnitude: 0.5,
      description: 'Planet with prominent ring system',
    ),
    AstronomicalObject(
      name: 'Moon',
      type: 'Moon',
      ra: 0.0,
      dec: 0.0,
      magnitude: -12.6,
      description: 'Earth\'s natural satellite',
    ),
  ];

  List<AstronomicalObject> get objects {
    if (_searchQuery.isEmpty) {
      return _objects;
    }
    return _objects
        .where(
          (obj) =>
              obj.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              obj.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              obj.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  void selectObject(AstronomicalObject object) {
    if (_selectedObject == object) {
      _selectedObject = null;
    } else {
      _selectedObject = object;
    }

    notifyListeners();
  }

  void clearSelection() {
    _selectedObject = null;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
