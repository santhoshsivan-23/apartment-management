import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Facility Bookings',
      tableName: 'facility_bookings',
      titleField: 'date',
      subtitleField: 'status',
      fields: [
        FieldConfig(
          key: 'amenity_id',
          label: 'Amenity',
          type: FieldType.dropdown,
          required: true,
          optionsLoader: OptionLoaders.amenities,
        ),
        FieldConfig(
          key: 'apartment_id',
          label: 'Booked by Apartment',
          type: FieldType.dropdown,
          optionsLoader: OptionLoaders.apartments,
        ),
        const FieldConfig(key: 'date', label: 'Date', type: FieldType.date, required: true),
        const FieldConfig(key: 'start_time', label: 'Start Time (e.g. 18:00)'),
        const FieldConfig(key: 'end_time', label: 'End Time (e.g. 20:00)'),
        const FieldConfig(
          key: 'status',
          label: 'Status',
          type: FieldType.dropdown,
          options: ['booked', 'cancelled', 'completed'],
        ),
      ],
    );
  }
}
