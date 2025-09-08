import 'package:flutter/material.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/object_list_item.dart';

class ObjectList extends StatelessWidget {
  final List<AstronomicalObject> objects;
  final AstronomicalObject? selectedObject;
  final Function(AstronomicalObject) onObjectSelected;
  final ScrollController? scrollController;

  const ObjectList({
    super.key,
    required this.objects,
    this.selectedObject,
    required this.onObjectSelected,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(objects.length, (index) {
              final object = objects[index];
              final isSelected = selectedObject == object;

              return Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: ObjectListItem(
                  object: object,
                  isSelected: isSelected,
                  onTap: () => onObjectSelected(object),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
