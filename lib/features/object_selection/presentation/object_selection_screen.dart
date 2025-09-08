import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/object_provider.dart';

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
        final filteredObjects = provider.objects.where((obj) =>
          obj.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          obj.type.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.search,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Astronomical Objects',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select celestial objects to observe',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search objects...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Objects List
                  Expanded(
                    child: filteredObjects.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No objects found',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your search terms',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredObjects.length,
                          itemBuilder: (context, index) {
                            final object = filteredObjects[index];
                            final isSelected = provider.selectedObject == object;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                              ),
                              child: InkWell(
                                onTap: () => provider.selectObject(object),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _getObjectColor(object.type).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getObjectIcon(object.type),
                                          color: _getObjectColor(object.type),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              object.name,
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              object.type,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                _buildInfoChip(
                                                  context,
                                                  'RA: ${object.ra.toStringAsFixed(2)}°',
                                                  Icons.explore,
                                                ),
                                                const SizedBox(width: 8),
                                                _buildInfoChip(
                                                  context,
                                                  'Dec: ${object.dec.toStringAsFixed(2)}°',
                                                  Icons.north,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ),

                  // Selected Object Summary
                  if (provider.selectedObject != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.star,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selected Object',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onBackground,
                                  ),
                                ),
                                Text(
                                  provider.selectedObject!.name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getObjectColor(String type) {
    switch (type.toLowerCase()) {
      case 'star':
        return Colors.yellow;
      case 'galaxy':
        return Colors.blue;
      case 'nebula':
        return Colors.purple;
      case 'planet':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getObjectIcon(String type) {
    switch (type.toLowerCase()) {
      case 'star':
        return Icons.star;
      case 'galaxy':
        return Icons.blur_circular;
      case 'nebula':
        return Icons.cloud;
      case 'planet':
        return Icons.public;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}