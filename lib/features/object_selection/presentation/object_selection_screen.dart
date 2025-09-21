import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/object_provider.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/object_selection_header.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/object_search_bar.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/object_list.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/selected_object_summary.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/empty_object_state.dart';

class ObjectSelectionScreen extends StatefulWidget {
  const ObjectSelectionScreen({super.key});

  @override
  State<ObjectSelectionScreen> createState() => _ObjectSelectionScreenState();
}

class _ObjectSelectionScreenState extends State<ObjectSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ObjectProvider>(
      builder: (context, provider, child) {
        final filteredObjects = provider.objects
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
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: const ObjectSelectionHeader(),
                        ),
                      ),

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
                                      selectedObject: provider.selectedObject,
                                      onObjectSelected: provider.selectObject,
                                    );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Builder(
                      builder: (context) {
                        if (provider.selectedObject != null) {
                          return SelectedObjectSummary(
                            selectedObject: provider.selectedObject!,
                          );
                        }
                        return const SizedBox.shrink();
                      },
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
}
