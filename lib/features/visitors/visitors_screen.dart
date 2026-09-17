import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class VisitorsScreen extends StatelessWidget {
  const VisitorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Visitors',
      tableName: 'visitors',
      titleField: 'name',
      subtitleField: 'purpose',
      fields: [
        const FieldConfig(key: 'name', label: 'Visitor Name', required: true),
        const FieldConfig(key: 'phone', label: 'Phone'),
        const FieldConfig(key: 'purpose', label: 'Purpose of Visit'),
        FieldConfig(
          key: 'apartment_id',
          label: 'Visiting Apartment',
          type: FieldType.dropdown,
          optionsLoader: OptionLoaders.apartments,
        ),
      ],
    );
  }
}
