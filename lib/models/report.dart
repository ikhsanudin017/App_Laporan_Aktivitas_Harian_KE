class Report {
  const Report({
    required this.id,
    required this.date,
    required this.reportData,
    required this.createdAt,
    required this.updatedAt,
    this.owner,
  });

  final String id;
  final DateTime date;
  final Map<String, dynamic> reportData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReportOwner? owner;

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: (json['id'] ?? '').toString(),
      date: _parseDate(json['date']),
      reportData:
          Map<String, dynamic>.from(json['reportData'] as Map? ?? const {}),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      owner: json['user'] == null
          ? null
          : ReportOwner.fromJson(
              Map<String, dynamic>.from(json['user'] as Map)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'reportData': reportData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (owner != null) 'user': owner!.toJson(),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }
}

class ReportOwner {
  const ReportOwner({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  factory ReportOwner.fromJson(Map<String, dynamic> json) {
    return ReportOwner(
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
