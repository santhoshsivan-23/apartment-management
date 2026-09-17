import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericCrudScreen(
      title: 'Assets',
      tableName: 'assets',
      titleField: 'name',
      subtitleField: 'category',
      fields: [
        FieldConfig(key: 'name', label: 'Asset Name', required: true),
        FieldConfig(
          key: 'category',
          label: 'Category',
          type: FieldType.dropdown,
          options: ['Generator', 'Elevator', 'Water Pump', 'CCTV', 'Furniture', 'Gym Equipment', 'Other'],
        ),
        FieldConfig(key: 'purchase_date', label: 'Purchase Date', type: FieldType.date),
        FieldConfig(key: 'value', label: 'Value', type: FieldType.number),
        FieldConfig(key: 'location', label: 'Location'),
      ],
    );
  }
}
