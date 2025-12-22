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
    return Column(
      children: List.generate(objects.length, (index) {
        final object = objects[index];
        final isSelected = selectedObject == object;

        return ObjectListItem(
          object: object,
          isSelected: isSelected,
          onTap: () => onObjectSelected(object),
        );
      }),
    );
  }
}
