import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';

class VendorsScreen extends StatelessWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericCrudScreen(
      title: 'Vendors',
      tableName: 'vendors',
      titleField: 'name',
      subtitleField: 'category',
      fields: [
        FieldConfig(key: 'name', label: 'Vendor Name', required: true),
        FieldConfig(
          key: 'category',
          label: 'Category',
          type: FieldType.dropdown,
          options: ['Plumbing', 'Electrical', 'Cleaning', 'Security', 'Landscaping', 'Pest Control', 'Other'],
        ),
        FieldConfig(key: 'phone', label: 'Phone'),
        FieldConfig(key: 'email', label: 'Email'),
      ],
    );
  }
}
