import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class ApartmentsScreen extends StatelessWidget {
  const ApartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Apartments',
      tableName: 'apartments',
      titleField: 'apartment_number',
      subtitleField: 'status',
      fields: [
        FieldConfig(
          key: 'building_id',
          label: 'Building',
          type: FieldType.dropdown,
          required: true,
          optionsLoader: OptionLoaders.buildings,
        ),
        FieldConfig(
          key: 'floor_id',
          label: 'Floor',
          type: FieldType.dropdown,
          optionsLoader: OptionLoaders.floors,
        ),
        const FieldConfig(key: 'apartment_number', label: 'Apartment Number', required: true),
        const FieldConfig(
          key: 'type',
          label: 'Type',
          type: FieldType.dropdown,
          options: ['1BHK', '2BHK', '3BHK', '4BHK', 'Studio', 'Penthouse'],
        ),
        const FieldConfig(key: 'area_sqft', label: 'Area (sqft)', type: FieldType.number),
        const FieldConfig(
          key: 'status',
          label: 'Status',
          type: FieldType.dropdown,
          options: ['occupied', 'vacant', 'rented'],
        ),
      ],
    );
  }
}
