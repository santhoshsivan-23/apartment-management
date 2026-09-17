import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenericCrudScreen(
      title: 'Events',
      tableName: 'events',
      titleField: 'name',
      subtitleField: 'venue',
      fields: [
        FieldConfig(key: 'name', label: 'Event Name', required: true),
        FieldConfig(key: 'description', label: 'Description', type: FieldType.multiline),
        FieldConfig(key: 'date', label: 'Date', type: FieldType.date, required: true),
        FieldConfig(key: 'venue', label: 'Venue'),
      ],
    );
  }
}
