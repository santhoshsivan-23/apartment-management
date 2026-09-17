import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericCrudScreen(
      title: 'Staff',
      tableName: 'staff',
      titleField: 'name',
      subtitleField: 'role',
      fields: [
        FieldConfig(key: 'name', label: 'Name', required: true),
        FieldConfig(
          key: 'role',
          label: 'Role',
          type: FieldType.dropdown,
          options: ['Security Guard', 'Housekeeping', 'Gardener', 'Plumber', 'Electrician', 'Manager', 'Other'],
        ),
        FieldConfig(key: 'phone', label: 'Phone'),
        FieldConfig(key: 'salary', label: 'Monthly Salary', type: FieldType.number),
        FieldConfig(key: 'join_date', label: 'Join Date', type: FieldType.date),
      ],
    );
  }
}
