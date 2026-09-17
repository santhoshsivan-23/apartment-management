import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';

class AmenitiesScreen extends StatelessWidget {
  const AmenitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericCrudScreen(
      title: 'Amenities',
      tableName: 'amenities',
      titleField: 'name',
      subtitleField: 'capacity',
      fields: [
        FieldConfig(key: 'name', label: 'Amenity Name', required: true),
        FieldConfig(key: 'description', label: 'Description', type: FieldType.multiline),
        FieldConfig(key: 'capacity', label: 'Capacity', type: FieldType.number),
      ],
    );
  }
}
