import 'package:flutter/foundation.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';
import 'package:robotic_telescope/core/di/service_locator.dart';

class ObjectSelectionProvider extends ChangeNotifier {
  List<AstronomicalObject> _objects = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String _searchQuery = '';
  AstronomicalObject? _selectedObject;
  static const int _pageSize = 30;
  bool _isSearching = false;

  // Getters
  List<AstronomicalObject> get objects => _objects;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  AstronomicalObject? get selectedObject => _selectedObject;

  // Initialize and load initial data
  Future<void> initialize() async {
    await loadInitialData();
  }

  // Load initial data
  Future<void> loadInitialData() async {
    _currentPage = 0;
    _objects.clear();
    _hasMore = true;
    _isLoading = true;
    notifyListeners();

    try {
      final newObjects = await Services.objectDao.getObjects(
        limit: _pageSize,
        offset: 0,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      _objects = newObjects;
      _currentPage = 1;
      _hasMore = newObjects.length == _pageSize;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Load more objects for pagination
  Future<void> loadMoreObjects() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newObjects = await Services.objectDao.getObjects(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      );

      _objects.addAll(newObjects);
      _currentPage++;
      _hasMore = newObjects.length == _pageSize;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Handle search with debounce
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();

    // Debounce search
    if (_isSearching) return;
    _isSearching = true;

    Future.delayed(const Duration(milliseconds: 500), () {
      _isSearching = false;
      loadInitialData();
    });
  }

  // Select an object
  void selectObject(AstronomicalObject? object) {
    _selectedObject = object;
    notifyListeners();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    loadInitialData();
  }

  @override
  void dispose() {
    _objects.clear();
    super.dispose();
  }
}
