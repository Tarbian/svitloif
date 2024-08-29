class Range {
  final int id;
  final DateTime date;
  final String name;
  final List<String> orders;
  final List<List<int>> off;
  final List<List<int>> on;
  final List<List<int>> maybe;
  final DateTime createdAt;
  final DateTime updatedAt;

  Range({
    required this.id,
    required this.date,
    required this.name,
    required this.orders,
    required this.off,
    required this.on,
    required this.maybe,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Range.fromJson(Map<String, dynamic> json) {
    return Range(
      id: json['id'],
      date: DateTime.parse(json['date']),
      name: json['name'],
      orders: List<String>.from(json['orders']),
      off: List<List<int>>.from(json['off'].map((e) => List<int>.from(e))),
      on: List<List<int>>.from(json['on'].map((e) => List<int>.from(e))),
      maybe: List<List<int>>.from(json['maybe'].map((e) => List<int>.from(e))),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'name': name,
      'orders': orders,
      'off': off,
      'on': on,
      'maybe': maybe,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}