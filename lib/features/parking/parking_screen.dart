import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class ParkingScreen extends StatelessWidget {
  const ParkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Parking',
      tableName: 'parking_slots',
      titleField: 'slot_number',
      subtitleField: 'type',
      fields: [
        const FieldConfig(key: 'slot_number', label: 'Slot Number', required: true),
        const FieldConfig(
          key: 'type',
          label: 'Type',
          type: FieldType.dropdown,
          options: ['Car', 'Bike', 'Visitor', 'Reserved'],
        ),
        FieldConfig(
          key: 'apartment_id',
          label: 'Assigned Apartment',
          type: FieldType.dropdown,
          optionsLoader: OptionLoaders.apartments,
        ),
      ],
    );
  }
}
