import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Expenses',
      tableName: 'expenses',
      titleField: 'description',
      subtitleField: 'date',
      fields: [
        const FieldConfig(key: 'description', label: 'Description', required: true),
        const FieldConfig(key: 'amount', label: 'Amount', type: FieldType.number, required: true),
        const FieldConfig(key: 'date', label: 'Date', type: FieldType.date, required: true),
        FieldConfig(
          key: 'category_id',
          label: 'Category',
          type: FieldType.dropdown,
          optionsLoader: OptionLoaders.expenseCategories,
        ),
        FieldConfig(
          key: 'vendor_id',
          label: 'Vendor',
          type: FieldType.dropdown,
          optionsLoader: OptionLoaders.vendors,
        ),
      ],
    );
  }
}
