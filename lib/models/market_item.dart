
class MarketItem {
  final String id;
  final String userId;
  String name;
  double quantity;
  String unit;
  double price;
  bool isPurchased;
  String? category;
  String? note;
  DateTime addedDate;
  DateTime? purchasedDate;

  MarketItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    this.isPurchased = false,
    this.category,
    this.note,
    DateTime? addedDate,
    this.purchasedDate,
  }) : addedDate = addedDate ?? DateTime.now();

  double get totalPrice => quantity * price;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'isPurchased': isPurchased,
      'category': category,
      'note': note,
      'addedDate': addedDate.toIso8601String(),
      'purchasedDate': purchasedDate?.toIso8601String(),
    };
  }

  factory MarketItem.fromMap(Map<String, dynamic> map) {
    return MarketItem(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      quantity: map['quantity'].toDouble(),
      unit: map['unit'],
      price: map['price'].toDouble(),
      isPurchased: map['isPurchased'] ?? false,
      category: map['category'],
      note: map['note'],
      addedDate: DateTime.parse(map['addedDate']),
      purchasedDate: map['purchasedDate'] != null
          ? DateTime.parse(map['purchasedDate'])
          : null,
    );
  }

  MarketItem copyWith({
    String? name,
    double? quantity,
    String? unit,
    double? price,
    bool? isPurchased,
    String? category,
    String? note,
    DateTime? purchasedDate,
  }) {
    return MarketItem(
      id: id,
      userId: userId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      isPurchased: isPurchased ?? this.isPurchased,
      category: category ?? this.category,
      note: note ?? this.note,
      addedDate: addedDate,
      purchasedDate: purchasedDate ?? this.purchasedDate,
    );
  }
}