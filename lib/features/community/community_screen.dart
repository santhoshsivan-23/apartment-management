import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericCrudScreen(
      title: 'Community',
      tableName: 'communities',
      titleField: 'name',
      subtitleField: 'city',
      fields: [
        FieldConfig(key: 'name', label: 'Community Name', required: true),
        FieldConfig(key: 'address', label: 'Address', type: FieldType.multiline),
        FieldConfig(key: 'city', label: 'City'),
        FieldConfig(key: 'state', label: 'State'),
        FieldConfig(key: 'pincode', label: 'Pincode'),
        FieldConfig(key: 'contact_number', label: 'Contact Number'),
        FieldConfig(key: 'email', label: 'Email'),
      ],
    );
  }
}
