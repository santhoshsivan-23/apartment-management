import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Complaints',
      tableName: 'complaints',
      titleField: 'title',
      subtitleField: 'status',
      fields: [
        const FieldConfig(key: 'title', label: 'Title', required: true),
        const FieldConfig(key: 'description', label: 'Description', type: FieldType.multiline),
        FieldConfig(
          key: 'apartment_id',
          label: 'Apartment',
          type: FieldType.dropdown,
          optionsLoader: OptionLoaders.apartments,
        ),
        const FieldConfig(
          key: 'priority',
          label: 'Priority',
          type: FieldType.dropdown,
          options: ['low', 'normal', 'high', 'urgent'],
        ),
        const FieldConfig(
          key: 'status',
          label: 'Status',
          type: FieldType.dropdown,
          options: ['open', 'in_progress', 'resolved', 'closed'],
        ),
      ],
    );
  }
}
