import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class ResidentsScreen extends StatelessWidget {
  const ResidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Residents',
      tableName: 'residents',
      titleField: 'name',
      subtitleField: 'phone',
      fields: [
        FieldConfig(
          key: 'apartment_id',
          label: 'Apartment',
          type: FieldType.dropdown,
          required: true,
          optionsLoader: OptionLoaders.apartments,
        ),
        const FieldConfig(key: 'name', label: 'Full Name', required: true),
        const FieldConfig(key: 'phone', label: 'Phone'),
        const FieldConfig(key: 'email', label: 'Email'),
        const FieldConfig(
          key: 'type',
          label: 'Type',
          type: FieldType.dropdown,
          options: ['owner', 'tenant'],
        ),
        const FieldConfig(key: 'move_in_date', label: 'Move-in Date', type: FieldType.date),
      ],
    );
  }
}
