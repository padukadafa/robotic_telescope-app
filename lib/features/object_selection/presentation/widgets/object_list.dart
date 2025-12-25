import 'package:flutter/material.dart';
import 'package:robotic_telescope/core/helper/astronomy.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';
import 'package:robotic_telescope/features/object_selection/presentation/widgets/object_list_item.dart';

class ObjectList extends StatelessWidget {
  final List<AstronomicalObject> objects;
  final AstronomicalObject? selectedObject;
  final Function(AstronomicalObject) onObjectSelected;
  final ScrollController? scrollController;
  final double? observerLatitude;
  final double? observerLongitude;

  const ObjectList({
    super.key,
    required this.objects,
    this.selectedObject,
    required this.onObjectSelected,
    this.scrollController,
    this.observerLatitude,
    this.observerLongitude,
  });

  @override
  Widget build(BuildContext context) {
    final observationTime = DateTime.now();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: objects.length,
      itemBuilder: (context, index) {
        final object = objects[index];
        final isSelected = selectedObject == object;
        double? altitudeDeg;
        bool isAboveHorizon = true;

        if (observerLatitude != null && observerLongitude != null) {
          final normalizedRaDeg = object.ra <= 24 ? object.ra * 15 : object.ra;
          final coords = Astronomy.equatorialToHorizontal(
            raDeg: normalizedRaDeg,
            decDeg: object.dec,
            latitudeDeg: observerLatitude!,
            longitudeDeg: observerLongitude!,
            dateTime: observationTime,
          );
          altitudeDeg = coords.altitude;
          isAboveHorizon = altitudeDeg >= 0;
        }

        return ObjectListItem(
          object: object,
          isSelected: isSelected,
          observerLatitude: observerLatitude,
          observerLongitude: observerLongitude,
          isAboveHorizon: isAboveHorizon,
          altitudeDeg: altitudeDeg,
          onTap: () => onObjectSelected(object),
        );
      },
    );
  }
}
