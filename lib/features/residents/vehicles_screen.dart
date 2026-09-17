import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Vehicles',
      tableName: 'vehicles',
      titleField: 'vehicle_number',
      subtitleField: 'type',
      fields: [
        FieldConfig(
          key: 'resident_id',
          label: 'Resident',
          type: FieldType.dropdown,
          required: true,
          optionsLoader: OptionLoaders.residents,
        ),
        const FieldConfig(key: 'vehicle_number', label: 'Vehicle Number', required: true),
        const FieldConfig(
          key: 'type',
          label: 'Type',
          type: FieldType.dropdown,
          options: ['Car', 'Bike', 'Scooter', 'Other'],
        ),
        const FieldConfig(key: 'model', label: 'Model'),
      ],
    );
  }
}
