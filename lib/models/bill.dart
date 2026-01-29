class Bill {
  Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.dateMillis,
    this.notes,
  });

  final String id;
  final String title;
  final double amount;
  final int dateMillis;
  final String? notes;

  Bill copyWith({
    String? id,
    String? title,
    double? amount,
    int? dateMillis,
    String? notes,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dateMillis: dateMillis ?? this.dateMillis,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'dateMillis': dateMillis,
        'notes': notes,
      };

  static Bill fromJson(Map<String, dynamic> json) => Bill(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        dateMillis: (json['dateMillis'] as num).toInt(),
        notes: json['notes'] as String?,
      );
}

