enum FieldType { text, number, date, dropdown, multiline }

/// Describes one column/field for a module: how to show it in the list,
/// and how to edit it in the add/edit form. This is what lets a single
/// generic screen widget serve every feature in the app.
class FieldConfig {
  final String key; // DB column name
  final String label; // Display label
  final FieldType type;
  final bool required;
  final List<String>? options; // for dropdown (static)
  final Future<Map<int, String>> Function()? optionsLoader; // for dropdown backed by another table (id -> label)

  const FieldConfig({
    required this.key,
    required this.label,
    this.type = FieldType.text,
    this.required = false,
    this.options,
    this.optionsLoader,
  });
}
