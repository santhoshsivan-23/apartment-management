import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';
import 'floors_screen.dart';

class BuildingsScreen extends StatelessWidget {
  const BuildingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Buildings',
      tableName: 'buildings',
      titleField: 'name',
      subtitleField: 'total_apartments',
      actions: [
        IconButton(
          icon: const Icon(Icons.layers_rounded),
          tooltip: 'All Floors',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FloorsScreen()),
            );
          },
        ),
      ],
      trailingBuilder: (row) {
        return IconButton(
          icon: const Icon(Icons.layers_outlined),
          tooltip: 'Manage Floors for ${row['name']}',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FloorsScreen(
                  buildingId: row['id'] as int?,
                  buildingName: row['name'] as String?,
                ),
              ),
            );
          },
        );
      },
      fields: [
        FieldConfig(
          key: 'community_id',
          label: 'Community',
          type: FieldType.dropdown,
          required: true,
          optionsLoader: OptionLoaders.communities,
        ),
        const FieldConfig(key: 'name', label: 'Building Name', required: true),
        const FieldConfig(key: 'total_floors', label: 'Total Floors', type: FieldType.number),
        const FieldConfig(key: 'total_apartments', label: 'Total Apartments', type: FieldType.number),
      ],
    );
  }
}
