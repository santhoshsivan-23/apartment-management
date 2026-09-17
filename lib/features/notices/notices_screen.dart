import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericCrudScreen(
      title: 'Notices',
      tableName: 'notices',
      titleField: 'title',
      subtitleField: 'priority',
      fields: [
        FieldConfig(key: 'title', label: 'Title', required: true),
        FieldConfig(key: 'content', label: 'Content', type: FieldType.multiline, required: true),
        FieldConfig(
          key: 'priority',
          label: 'Priority',
          type: FieldType.dropdown,
          options: ['normal', 'important', 'urgent'],
        ),
      ],
    );
  }
}
