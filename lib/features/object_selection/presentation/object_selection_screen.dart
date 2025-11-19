import 'package:flutter/material.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/object_search_bar.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/object_list.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/empty_object_state.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';

class ObjectSelectionScreen extends StatefulWidget {
  const ObjectSelectionScreen({super.key});

  @override
  State<ObjectSelectionScreen> createState() => _ObjectSelectionScreenState();
}

class _ObjectSelectionScreenState extends State<ObjectSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  AstronomicalObject? selectedObject;

  // Sample data
  final List<AstronomicalObject> objects = [
    AstronomicalObject(
      name: 'Mars',
      type: 'Planet',
      ra: 5.5,
      dec: 22.5,
      magnitude: -2.0,
      description: 'The Red Planet',
    ),
    AstronomicalObject(
      name: 'Jupiter',
      type: 'Planet',
      ra: 10.5,
      dec: 12.0,
      magnitude: -2.5,
      description: 'The largest planet',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredObjects = objects
        .where(
          (obj) =>
              obj.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              obj.type.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

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
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  searchQuery: _searchQuery,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Builder(
                    builder: (context) {
                      return filteredObjects.isEmpty
                          ? const EmptyObjectState()
                          : ObjectList(
                              objects: filteredObjects,
                              selectedObject: selectedObject,
                              onObjectSelected: (obj) {
                                setState(() {
                                  selectedObject = obj;
                                });
                              },
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
  }
}
