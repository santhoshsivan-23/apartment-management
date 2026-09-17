import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class VendorPaymentsScreen extends StatelessWidget {
  const VendorPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Vendor Payments',
      tableName: 'vendor_payments',
      titleField: 'description',
      subtitleField: 'date',
      fields: [
        FieldConfig(
          key: 'vendor_id',
          label: 'Vendor',
          type: FieldType.dropdown,
          required: true,
          optionsLoader: OptionLoaders.vendors,
        ),
        const FieldConfig(key: 'amount', label: 'Amount', type: FieldType.number, required: true),
        const FieldConfig(key: 'date', label: 'Date', type: FieldType.date, required: true),
        const FieldConfig(key: 'description', label: 'Description', type: FieldType.multiline),
      ],
    );
  }
}
