# Provider State Management - Object Selection

## Overview

Implementasi Provider untuk state management pada ObjectSelectionScreen, mengelola pagination, search, dan selection objects dari database.

## ObjectSelectionProvider

**File:** `lib/core/providers/object_selection_provider.dart`

### Properties

- `_objects` - List of AstronomicalObject yang sudah diload
- `_isLoading` - Status loading state
- `_hasMore` - Flag untuk indicator masih ada data
- `_currentPage` - Current page untuk pagination
- `_searchQuery` - Search query string
- `_selectedObject` - Currently selected object
- `_pageSize` - Ukuran per halaman (30 items)
- `_isSearching` - Flag untuk debounce search

### Methods

#### `initialize()`

Inisialisasi provider dan load data awal. Dipanggil saat screen pertama kali dibuka.

#### `loadInitialData()`

Reset state dan load halaman pertama. Digunakan saat:

- First load
- Search query berubah
- Refresh data

#### `loadMoreObjects()`

Load halaman berikutnya untuk pagination. Features:

- Check `isLoading` dan `hasMore` untuk prevent duplicate load
- Fetch data via `Services.objectDao.getObjects()`
- Update pagination state (`currentPage`, `hasMore`)
- Append data ke existing list

#### `setSearchQuery(String query)`

Handle search dengan debounce 500ms:

- Update search query
- Debounce untuk menghindari terlalu banyak query
- Trigger `loadInitialData()` setelah debounce

#### `selectObject(AstronomicalObject? object)`

Set selected object dan trigger UI update.

#### `clearSearch()`

Clear search query dan reload data.

## Integration in ObjectSelectionScreen

### Setup Provider

```dart
// In main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ObjectSelectionProvider()),
  ],
  child: const HomeScreen(),
)
```

### Initialize on Screen Load

```dart
@override
void initState() {
  super.initState();
  _scrollController.addListener(_onScroll);

  // Initialize provider after frame is built
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<ObjectSelectionProvider>().initialize();
  });
}
```

### Scroll Listener for Pagination

```dart
void _onScroll() {
  if (_scrollController.position.pixels >=
      _scrollController.position.maxScrollExtent * 0.8) {
    context.read<ObjectSelectionProvider>().loadMoreObjects();
  }
}
```

### Consume Provider in UI

```dart
Consumer<ObjectSelectionProvider>(
  builder: (context, provider, child) {
    return CustomScrollView(
      slivers: [
        // Search bar
        ObjectSearchBar(
          onSearchChanged: (value) {
            provider.setSearchQuery(value);
          },
          searchQuery: provider.searchQuery,
        ),

        // Object list
        ObjectList(
          objects: provider.objects,
          selectedObject: provider.selectedObject,
          onObjectSelected: (obj) {
            provider.selectObject(obj);
          },
        ),

        // Loading indicator
        if (provider.isLoading && provider.objects.isNotEmpty)
          CircularProgressIndicator(),

        // End of list
        if (!provider.hasMore && provider.objects.isNotEmpty)
          Text('End of list'),
      ],
    );
  },
)
```

## State Flow

### Initial Load Flow

1. Screen mounted
2. `initState()` called
3. Post frame callback → `provider.initialize()`
4. Provider calls `loadInitialData()`
5. Clear state, fetch first page
6. Update UI dengan `notifyListeners()`

### Pagination Flow

1. User scrolls down
2. Scroll listener detects 80% threshold
3. Call `provider.loadMoreObjects()`
4. Check if already loading or no more data
5. Fetch next page from DAO
6. Append to objects list
7. Update `hasMore` flag
8. Notify listeners → UI updates

### Search Flow

1. User types in search bar
2. `provider.setSearchQuery(query)` called
3. Debounce 500ms
4. After delay → `loadInitialData()`
5. Reset pagination state
6. Fetch filtered results
7. Update UI

### Selection Flow

1. User taps object in list
2. `provider.selectObject(obj)` called
3. Update `_selectedObject`
4. `notifyListeners()` → UI shows selection

## Benefits of Provider Pattern

✅ **Separation of Concerns**

- Business logic terpisah dari UI
- Provider handles state, Widget handles display

✅ **Reactive UI**

- Automatic UI update via `notifyListeners()`
- No manual `setState()` in widgets

✅ **Centralized State**

- Single source of truth
- Easier to debug and test

✅ **Reusability**

- Provider bisa diakses dari multiple screens
- Shared state across app

✅ **Memory Management**

- Provider lifecycle managed by framework
- Automatic cleanup via `dispose()`

## Testing

### Test Provider Logic

```dart
test('loadMoreObjects should append new objects', () async {
  final provider = ObjectSelectionProvider();
  await provider.initialize();

  final initialCount = provider.objects.length;
  await provider.loadMoreObjects();

  expect(provider.objects.length, greaterThan(initialCount));
});

test('setSearchQuery should filter results', () async {
  final provider = ObjectSelectionProvider();
  await provider.initialize();

  provider.setSearchQuery('Sirius');
  await Future.delayed(Duration(milliseconds: 600));

  expect(provider.objects.isNotEmpty, true);
});
```

## Performance Optimization

- **Debounced Search**: Prevent excessive database queries
- **Lazy Loading**: Load data only when needed
- **Scroll Threshold**: Trigger load before reaching bottom
- **Conditional notifyListeners**: Only notify when state changes

## Future Enhancements

1. Add error handling with error state
2. Implement pull-to-refresh
3. Add loading skeleton screens
4. Cache search results
5. Persist selected object across sessions
6. Add filter options (magnitude, constellation)
