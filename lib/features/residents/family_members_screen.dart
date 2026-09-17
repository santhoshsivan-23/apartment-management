import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class FamilyMembersScreen extends StatelessWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Family Members',
      tableName: 'family_members',
      titleField: 'name',
      subtitleField: 'relation',
      fields: [
        FieldConfig(
          key: 'resident_id',
          label: 'Resident',
          type: FieldType.dropdown,
          required: true,
          optionsLoader: OptionLoaders.residents,
        ),
        const FieldConfig(key: 'name', label: 'Name', required: true),
        const FieldConfig(key: 'relation', label: 'Relation'),
        const FieldConfig(key: 'age', label: 'Age', type: FieldType.number),
      ],
    );
  }
}
