import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class StaffAttendanceScreen extends StatelessWidget {
  const StaffAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Staff Attendance',
      tableName: 'staff_attendance',
      titleField: 'date',
      subtitleField: 'status',
      fields: [
        FieldConfig(
          key: 'staff_id',
          label: 'Staff',
          type: FieldType.dropdown,
          required: true,
          optionsLoader: OptionLoaders.staff,
        ),
        const FieldConfig(key: 'date', label: 'Date', type: FieldType.date, required: true),
        const FieldConfig(
          key: 'status',
          label: 'Status',
          type: FieldType.dropdown,
          options: ['present', 'absent', 'half_day', 'on_leave'],
        ),
      ],
    );
  }
}
