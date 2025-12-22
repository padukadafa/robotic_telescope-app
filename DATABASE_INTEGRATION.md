# Database Integration - HYG Stars Database

## Overview

Integrasi database SQLite (HYG Stars) dengan sistem paginasi untuk menampilkan objek astronomi dari database nyata.

## Struktur Database

File: `assets/hyg_stars.db`

Tabel: `stars`

- `proper` (TEXT) - Nama proper star
- `ra` (REAL) - Right Ascension
- `dec` (REAL) - Declination
- `dist` (REAL) - Jarak dalam parsec
- `pmra` (REAL) - Proper motion RA
- `pmdec` (REAL) - Proper motion Dec
- `rv` (REAL) - Radial velocity
- `mag` (REAL) - Magnitude
- `absmag` (REAL) - Absolute magnitude
- `spect` (TEXT) - Spektral type
- `ci` (REAL) - Color index
- `bayer` (TEXT) - Nama Bayer
- `con` (TEXT) - Konstelasi
- `lum` (REAL) - Luminositas
- `name` (TEXT) - Nama alternatif

## Komponen yang Dibuat

### 1. DatabaseHelper

**File:** `lib/core/services/database_helper.dart`

Service untuk mengelola koneksi database:

- Copy database dari assets ke local storage saat pertama kali
- Membuka koneksi database
- Singleton pattern via get_it

### 2. AstronomicalObjectDao

**File:** `lib/core/dao/astronomical_object_dao.dart`

DAO (Data Access Object) dengan fitur:

- `getObjects()` - Fetch dengan pagination dan filtering
- `getTotalCount()` - Hitung total data
- `getObjectByName()` - Cari by name
- `getBrightestStars()` - Dapatkan bintang paling terang
- `getConstellations()` - List konstelasi unik
- `getObjectsByConstellation()` - Filter by konstelasi

**Fitur Query:**

- Pagination (limit & offset)
- Search by name (proper/bayer)
- Filter by magnitude range
- Filter by constellation
- Sort by magnitude (brightest first)

### 3. Updated Model

**File:** `lib/core/models/astronomical_object.dart`

Model diupdate untuk match dengan DB schema:

- `fromMap()` factory constructor untuk parsing dari database
- Auto-generate display name (proper name atau bayer+constellation)
- Getter `description` untuk info singkat
- Getter `type` mengembalikan ObjectType enum

### 4. ObjectSelectionScreen with Pagination

**File:** `lib/features/object_selection/presentation/object_selection_screen.dart`

Fitur:

- Load data dari database via DAO
- Pagination dengan ScrollController
- Load more saat scroll ke 80% dari bottom
- Search dengan debounce (500ms)
- Loading indicators
- End of list indicator

**State Management:**

- `objects` - List yang sudah diload
- `isLoading` - Status loading
- `hasMore` - Masih ada data untuk load
- `currentPage` - Halaman saat ini
- `pageSize` - Ukuran per halaman (30 items)

### 5. Updated ObjectListItem

**File:** `lib/features/object_selection/presentation/widgets/object_list_item.dart`

Menampilkan:

- Nama star
- Description (spectral type, magnitude, constellation)
- RA & Dec coordinates
- Magnitude (jika ada)
- Distance dalam parsec (jika ada)

## Cara Penggunaan

### Basic Usage

```dart
// Get objects dengan pagination
final objects = await Services.objectDao.getObjects(
  limit: 30,
  offset: 0,
);

// Search objects
final results = await Services.objectDao.getObjects(
  searchQuery: 'Sirius',
  limit: 20,
);

// Filter by magnitude
final brightStars = await Services.objectDao.getObjects(
  minMagnitude: -2.0,
  maxMagnitude: 2.0,
  limit: 50,
);

// Filter by constellation
final orionStars = await Services.objectDao.getObjects(
  constellation: 'Ori',
  limit: 30,
);

// Get brightest stars
final brightest = await Services.objectDao.getBrightestStars(
  limit: 50,
);

// Get all constellations
final constellations = await Services.objectDao.getConstellations();
```

### Accessing via get_it

```dart
import 'package:robotic_telescope/core/di/service_locator.dart';

// Via Services helper class
final dao = Services.objectDao;
final objects = await dao.getObjects();

// Via getIt directly
final dao = getIt<AstronomicalObjectDao>();
```

## Dependencies Added

```yaml
sqflite: ^2.3.0 # SQLite database
path_provider: ^2.1.1 # Get app directory
path: ^1.8.3 # Path utilities
```

## Pagination Flow

1. Initial load: Load first 30 objects
2. User scrolls down
3. When reach 80% of scroll position → trigger load more
4. Load next 30 objects and append to list
5. Update `hasMore` flag based on result count
6. Show "End of list" when no more data

## Search Flow

1. User types in search bar
2. Debounce 500ms untuk avoid terlalu banyak query
3. Reset pagination (currentPage = 0, clear objects)
4. Load data dengan search query
5. Apply same pagination logic

## Performance Optimization

- Lazy loading dengan pagination (tidak load semua data sekaligus)
- Debounce pada search
- Scroll listener dengan threshold 80%
- Database read-only mode
- Singleton pattern untuk database connection

## Future Enhancements

1. Add filter UI (magnitude range, constellation picker)
2. Sort options (by name, magnitude, distance)
3. Favorite objects
4. Recent searches
5. Advanced filters (spectral type, color index)
6. Cache frequently accessed data

## Testing

- Test DAO methods dengan sample queries
- Verify pagination behavior
- Check search functionality
- Test scroll trigger threshold
- Validate model parsing from database

## Notes

- Database adalah read-only (data tidak bisa diubah)
- Database di-copy dari assets ke local storage saat first run
- Menggunakan singleton pattern untuk database connection
- Semua objek saat ini adalah deep sky objects (stars)
