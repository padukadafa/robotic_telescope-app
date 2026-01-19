import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/helper/astronomy.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/object_search_bar.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/object_list.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/empty_object_state.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/selected_object_summary.dart';
import 'package:robotic_telescope/features/object_selection/provider/object_selection_provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';

class ObjectSelectionScreen extends StatefulWidget {
  const ObjectSelectionScreen({super.key});

  @override
  State<ObjectSelectionScreen> createState() => _ObjectSelectionScreenState();
}

class _ObjectSelectionScreenState extends State<ObjectSelectionScreen> {
  final ScrollController _scrollController = ScrollController();
  double? _latitude;
  double? _longitude;
  bool _visibleOnly = false;
  ObjectType _selectedCategory = ObjectType.star;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObjectSelectionProvider>().initialize();
      _loadLocation();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Handle scroll for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      context.read<ObjectSelectionProvider>().loadMoreObjects();
    }
  }

  Future<void> _loadLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ObjectSelectionProvider>(
      builder: (context, provider, child) {
        final locationAvailable = _latitude != null && _longitude != null;
        final objectsToShow = _visibleOnly && locationAvailable
            ? provider.objects.where((obj) => _isAboveHorizon(obj)).toList()
            : provider.objects;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    surfaceTintColor: Colors.transparent,
                    foregroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    snap: true,
                    floating: true,
                    flexibleSpace: ObjectSearchBar(
                      onSearchChanged: (value) {
                        provider.setSearchQuery(value);
                      },
                      searchQuery: provider.searchQuery,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          // Category tabs
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Deep Sky')),
                                  selected:
                                      _selectedCategory == ObjectType.star,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedCategory = ObjectType.star;
                                      provider.selectObject(null);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(
                                    child: Text('Solar System'),
                                  ),
                                  selected: _isSolarSystemCategory(),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedCategory = ObjectType.planet;
                                      provider.selectObject(null);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Builder(
                        builder: (context) {
                          // Show solar system objects
                          if (_isSolarSystemCategory()) {
                            return _buildSolarSystemObjects(provider);
                          }

                          // Show loading for initial load
                          if (provider.objects.isEmpty && provider.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          // Show empty state
                          if (provider.objects.isEmpty && !provider.isLoading) {
                            return const EmptyObjectState();
                          }

                          // Show list
                          return Column(
                            children: [
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('Semua'),
                                    selected: !_visibleOnly,
                                    onSelected: (_) {
                                      setState(() {
                                        _visibleOnly = false;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Di atas horizon'),
                                    selected: _visibleOnly,
                                    onSelected: (_) {
                                      setState(() {
                                        _visibleOnly = true;
                                      });
                                    },
                                  ),
                                  if (_visibleOnly && !locationAvailable)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Text(
                                        'Aktifkan lokasi untuk filter horizon',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ObjectList(
                                objects: objectsToShow,
                                selectedObject: provider.selectedObject,
                                observerLatitude: _latitude,
                                observerLongitude: _longitude,
                                onObjectSelected: (obj) {
                                  provider.selectObject(obj);
                                },
                              ),
                              if (provider.selectedObject != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Consumer<TelescopeProvider>(
                                    builder: (context, telescope, _) {
                                      return SelectedObjectSummary(
                                        selectedObject:
                                            provider.selectedObject!,
                                        onGoToPressed: telescope.isConnected
                                            ? () async {}
                                            : null,
                                      );
                                    },
                                  ),
                                ),
                              // Loading indicator at bottom
                              if (provider.isLoading &&
                                  provider.objects.isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              // End of list indicator
                              if (!provider.hasMore &&
                                  provider.objects.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'End of list',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isAboveHorizon(AstronomicalObject object) {
    if (_latitude == null || _longitude == null) {
      return true;
    }

    return Astronomy.isAboveHorizon(
      raDeg: object.ra,
      decDeg: object.dec,
      latitudeDeg: _latitude!,
      longitudeDeg: _longitude!,
      dateTime: DateTime.now(),
    );
  }

  Widget _buildSolarSystemObjects(ObjectSelectionProvider provider) {
    final planets = [
      {'name': 'Merkurius', 'index': 0, 'icon': '☿'},
      {'name': 'Venus', 'index': 1, 'icon': '♀'},
      {'name': 'Bumi', 'index': 2, 'icon': '🌍'},
      {'name': 'Mars', 'index': 3, 'icon': '♂'},
      {'name': 'Jupiter', 'index': 4, 'icon': '♃'},
      {'name': 'Saturnus', 'index': 5, 'icon': '♄'},
      {'name': 'Uranus', 'index': 6, 'icon': '♅'},
      {'name': 'Neptunus', 'index': 7, 'icon': '♆'},
      {'name': 'Pluto', 'index': 8, 'icon': '♇'},
    ];

    final specialObjects = [
      {'name': 'Matahari', 'index': 9, 'icon': '☀️'},
      {'name': 'Bulan', 'index': 10, 'icon': '🌙'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            'Planet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...planets.map(
          (planet) => _buildSolarSystemTile(
            name: planet['name'] as String,
            index: planet['index'] as int,
            icon: planet['icon'] as String,
            provider: provider,
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            'Objek Khusus',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...specialObjects.map(
          (obj) => _buildSolarSystemTile(
            name: obj['name'] as String,
            index: obj['index'] as int,
            icon: obj['icon'] as String,
            provider: provider,
          ),
        ),
        if (provider.selectedObject != null &&
            _isSolarSystemObject(provider.selectedObject!))
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Consumer<TelescopeProvider>(
              builder: (context, telescope, _) {
                return SelectedObjectSummary(
                  selectedObject: provider.selectedObject!,
                  onGoToPressed: telescope.isConnected ? () async {} : null,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSolarSystemTile({
    required String name,
    required int index,
    required String icon,
    required ObjectSelectionProvider provider,
  }) {
    final isSelected =
        provider.selectedObject != null &&
        provider.selectedObject!.name == name &&
        _isSolarSystemObject(provider.selectedObject!);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 0,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () {
          final AstronomicalObject solarObject;
          if (index == 9) {
            solarObject = AstronomicalObject.sun(
              name: name,
              solarSystemIndex: index,
            );
          } else if (index == 10) {
            solarObject = AstronomicalObject.moon(
              name: name,
              solarSystemIndex: index,
            );
          } else {
            solarObject = AstronomicalObject.planet(
              name: name,
              solarSystemIndex: index,
            );
          }
          provider.selectObject(solarObject);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Index: $index',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.7)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to check if current category is solar system
  bool _isSolarSystemCategory() {
    return _selectedCategory == ObjectType.planet ||
        _selectedCategory == ObjectType.sun ||
        _selectedCategory == ObjectType.moon;
  }

  // Helper to check if an object is solar system object
  bool _isSolarSystemObject(AstronomicalObject object) {
    return object.type == ObjectType.planet ||
        object.type == ObjectType.sun ||
        object.type == ObjectType.moon;
  }
}
