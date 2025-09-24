enum FormFieldType {
  text,
  number,
  textarea,
  date,
  dropdownNumber,
}

extension FormFieldTypeParser on FormFieldType {
  static FormFieldType fromString(String value) {
    switch (value) {
      case 'text':
        return FormFieldType.text;
      case 'number':
        return FormFieldType.number;
      case 'textarea':
        return FormFieldType.textarea;
      case 'date':
        return FormFieldType.date;
      case 'dropdown-number':
        return FormFieldType.dropdownNumber;
      default:
        return FormFieldType.text;
    }
  }

  String get asString {
    switch (this) {
      case FormFieldType.text:
        return 'text';
      case FormFieldType.number:
        return 'number';
      case FormFieldType.textarea:
        return 'textarea';
      case FormFieldType.date:
        return 'date';
      case FormFieldType.dropdownNumber:
        return 'dropdown-number';
    }
  }
}

class FormFieldConfig {
  const FormFieldConfig({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.placeholder,
    this.category,
  });

  final String name;
  final String label;
  final FormFieldType type;
  final bool required;
  final String? placeholder;
  final String? category;

  bool get isNumericField =>
      type == FormFieldType.number || type == FormFieldType.dropdownNumber;

  factory FormFieldConfig.fromJson(Map<String, dynamic> json) {
    return FormFieldConfig(
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? json['name'] as String? ?? '',
      type: FormFieldTypeParser.fromString(json['type'] as String? ?? 'text'),
      required: json['required'] as bool? ?? false,
      placeholder: json['placeholder'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'type': type.asString,
      'required': required,
      'placeholder': placeholder,
      'category': category,
    };
  }
}

class FormConfig {
  const FormConfig({
    required this.role,
    required this.title,
    required this.fields,
  });

  final String role;
  final String title;
  final List<FormFieldConfig> fields;

  factory FormConfig.fromJson(Map<String, dynamic> json) {
    final fieldsJson = json['fields'] as List? ?? const [];
    return FormConfig(
      role: json['role'] as String? ?? 'USER',
      title: json['title'] as String? ?? 'Form Laporan Harian',
      fields: fieldsJson
          .map((field) =>
              FormFieldConfig.fromJson(Map<String, dynamic>.from(field as Map)))
          .toList(),
    );
  }
}
