import 'dart:convert';

/// Domain model representing a scanned or analyzed food item.
class FoodItem {
  final String id;
  final String barcode;
  final String name;
  final String brand;
  final String? imageUrl;
  final String servingSize;
  final double calories; // kcal
  final double protein; // grams
  final double carbohydrates; // grams
  final double fat; // grams
  final double sugar; // grams
  final double fiber; // grams
  final String? nutriScore; // 'A', 'B', 'C', 'D', 'E'
  final DateTime scannedAt;
  final List<String> ingredients;
  final String source; // 'barcode_scan', 'ai_vision', 'manual'
  final bool isFavorite;
  final bool isSynced;

  const FoodItem({
    required this.id,
    this.barcode = '',
    required this.name,
    this.brand = '',
    this.imageUrl,
    this.servingSize = '100g',
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    this.sugar = 0.0,
    this.fiber = 0.0,
    this.nutriScore,
    required this.scannedAt,
    this.ingredients = const [],
    this.source = 'barcode_scan',
    this.isFavorite = false,
    this.isSynced = true,
  });

  FoodItem copyWith({
    String? id,
    String? barcode,
    String? name,
    String? brand,
    String? imageUrl,
    String? servingSize,
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat,
    double? sugar,
    double? fiber,
    String? nutriScore,
    DateTime? scannedAt,
    List<String>? ingredients,
    String? source,
    bool? isFavorite,
    bool? isSynced,
  }) {
    return FoodItem(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      servingSize: servingSize ?? this.servingSize,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fat: fat ?? this.fat,
      sugar: sugar ?? this.sugar,
      fiber: fiber ?? this.fiber,
      nutriScore: nutriScore ?? this.nutriScore,
      scannedAt: scannedAt ?? this.scannedAt,
      ingredients: ingredients ?? this.ingredients,
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'servingSize': servingSize,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'sugar': sugar,
      'fiber': fiber,
      'nutriScore': nutriScore,
      'scannedAt': scannedAt.toIso8601String(),
      'ingredients': ingredients,
      'source': source,
      'isFavorite': isFavorite,
      'isSynced': isSynced,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      name: map['name']?.toString() ?? 'ไม่ระบุชื่ออาหาร',
      brand: map['brand']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString(),
      servingSize: map['servingSize']?.toString() ?? '100g',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (map['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      sugar: (map['sugar'] as num?)?.toDouble() ?? 0.0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0.0,
      nutriScore: map['nutriScore']?.toString(),
      scannedAt: map['scannedAt'] != null
          ? DateTime.tryParse(map['scannedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      ingredients: (map['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      source: map['source']?.toString() ?? 'barcode_scan',
      isFavorite: map['isFavorite'] == true,
      isSynced: map['isSynced'] != false,
    );
  }

  String toJson() => json.encode(toMap());

  factory FoodItem.fromJson(String source) =>
      FoodItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FoodItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
