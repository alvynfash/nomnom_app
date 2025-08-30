class MealSlot {
  final String id;
  final String name;
  final int order;
  final bool isDefault;

  MealSlot({
    required this.id,
    required this.name,
    required this.order,
    this.isDefault = false,
  });

  /// Create a meal slot with generated ID
  MealSlot.create({
    required this.name,
    required this.order,
    this.isDefault = false,
  }) : id = _generateUniqueId();

  static int _idCounter = 0;

  static String _generateUniqueId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final counter = _idCounter++;
    return 'slot_${timestamp}_$counter';
  }

  /// Default meal slots
  static List<MealSlot> getDefaultSlots() {
    return [
      MealSlot(id: 'breakfast', name: 'Breakfast', order: 1, isDefault: true),
      MealSlot(id: 'lunch', name: 'Lunch', order: 2, isDefault: true),
      MealSlot(id: 'dinner', name: 'Dinner', order: 3, isDefault: true),
      MealSlot(id: 'snacks', name: 'Snacks', order: 4, isDefault: true),
    ];
  }

  /// Serialization methods
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'order': order, 'isDefault': isDefault};
  }

  factory MealSlot.fromMap(Map<String, dynamic> map) {
    return MealSlot(
      id: map['id'],
      name: map['name'],
      order: map['order'],
      isDefault: map['isDefault'] ?? false,
    );
  }

  /// JSON serialization methods for compatibility
  Map<String, dynamic> toJson() => toMap();
  factory MealSlot.fromJson(Map<String, dynamic> json) =>
      MealSlot.fromMap(json);

  /// Create a copy with updated values
  MealSlot copyWith({String? id, String? name, int? order, bool? isDefault}) {
    return MealSlot(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Validation methods
  void validate() {
    if (name.trim().isEmpty) {
      throw MealSlotException('Meal slot name cannot be empty', 'INVALID_NAME');
    }
    if (name.length > 30) {
      throw MealSlotException(
        'Meal slot name cannot exceed 30 characters',
        'INVALID_NAME',
      );
    }
    if (order < 1) {
      throw MealSlotException(
        'Meal slot order must be at least 1',
        'INVALID_ORDER',
      );
    }
  }

  /// Returns true if the meal slot is valid
  bool get isValid {
    try {
      validate();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealSlot &&
        other.id == id &&
        other.name == name &&
        other.order == order &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ order.hashCode ^ isDefault.hashCode;

  @override
  String toString() =>
      'MealSlot(id: $id, name: $name, order: $order, isDefault: $isDefault)';
}

/// Exception for meal slot operations
class MealSlotException implements Exception {
  final String message;
  final String code;

  MealSlotException(this.message, this.code);

  @override
  String toString() => 'MealSlotException: $message (code: $code)';
}
