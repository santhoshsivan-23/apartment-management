import 'package:flutter/material.dart';
import '../../core/widgets/generic_crud_screen.dart';
import '../../core/widgets/field_config.dart';
import '../../core/utils/option_loaders.dart';

class AssetMaintenanceScreen extends StatelessWidget {
  const AssetMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(
      title: 'Asset Maintenance Log',
      tableName: 'asset_maintenance',
      titleField: 'description',
      subtitleField: 'date',
      fields: [
        FieldConfig(
          key: 'asset_id',
          label: 'Asset',
          type: FieldType.dropdown,
          required: true,
          optionsLoader: OptionLoaders.assets,
        ),
        const FieldConfig(key: 'date', label: 'Date', type: FieldType.date, required: true),
        const FieldConfig(key: 'description', label: 'Description', type: FieldType.multiline),
        const FieldConfig(key: 'cost', label: 'Cost', type: FieldType.number),
      ],
    );
  }
}
