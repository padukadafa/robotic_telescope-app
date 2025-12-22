import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/object_search_bar.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/object_list.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/empty_object_state.dart';
import 'package:robotic_telescope/features/object_selection/provider/object_selection_provider.dart';

class ObjectSelectionScreen extends StatefulWidget {
  const ObjectSelectionScreen({super.key});

  @override
  State<ObjectSelectionScreen> createState() => _ObjectSelectionScreenState();
}

class _ObjectSelectionScreenState extends State<ObjectSelectionScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initialize provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObjectSelectionProvider>().initialize();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ObjectSelectionProvider>(
      builder: (context, provider, child) {
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
                      padding: const EdgeInsets.only(top: 24),
                      child: Builder(
                        builder: (context) {
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
                              ObjectList(
                                objects: provider.objects,
                                selectedObject: provider.selectedObject,
                                onObjectSelected: (obj) {
                                  provider.selectObject(obj);
                                },
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
}
