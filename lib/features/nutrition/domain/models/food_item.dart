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
  final double saturatedFat; // grams
  final double sodium; // mg
  final String? nutriScore; // 'A', 'B', 'C', 'D', 'E'
  final DateTime scannedAt;
  final List<String> ingredients;
  final String source; // 'barcode_scan', 'ai_vision', 'manual'
  final bool isFavorite;

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
    this.saturatedFat = 0.0,
    this.sodium = 0.0,
    this.nutriScore,
    required this.scannedAt,
    this.ingredients = const [],
    this.source = 'barcode_scan',
    this.isFavorite = false,
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
    double? saturatedFat,
    double? sodium,
    String? nutriScore,
    DateTime? scannedAt,
    List<String>? ingredients,
    String? source,
    bool? isFavorite,
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
      saturatedFat: saturatedFat ?? this.saturatedFat,
      sodium: sodium ?? this.sodium,
      nutriScore: nutriScore ?? this.nutriScore,
      scannedAt: scannedAt ?? this.scannedAt,
      ingredients: ingredients ?? this.ingredients,
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
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
      'saturatedFat': saturatedFat,
      'sodium': sodium,
      'nutriScore': nutriScore,
      'scannedAt': scannedAt.toIso8601String(),
      'ingredients': ingredients,
      'source': source,
      'isFavorite': isFavorite,
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
      saturatedFat: (map['saturatedFat'] as num?)?.toDouble() ?? 0.0,
      sodium: (map['sodium'] as num?)?.toDouble() ?? 0.0,
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
    );
  }

  // --- Nutrition Calculation Helpers ---

  /// Calculates percentage of daily calorie target (default 2,000 kcal according to Thai RDI)
  double caloriePercentage([double dailyTarget = 2000.0]) {
    if (dailyTarget <= 0) return 0.0;
    return (calories / dailyTarget) * 100.0;
  }

  /// Calculates percentage of Thai Daily Value for Protein (Recommended 50g)
  double proteinRdiPercentage([double rdi = 50.0]) {
    if (rdi <= 0) return 0.0;
    return (protein / rdi) * 100.0;
  }

  /// Calculates percentage of Thai Daily Value for Carbohydrates (Recommended 300g)
  double carbsRdiPercentage([double rdi = 300.0]) {
    if (rdi <= 0) return 0.0;
    return (carbohydrates / rdi) * 100.0;
  }

  /// Calculates percentage of Thai Daily Value for Total Fat (Recommended 65g)
  double fatRdiPercentage([double rdi = 65.0]) {
    if (rdi <= 0) return 0.0;
    return (fat / rdi) * 100.0;
  }

  /// Calculates percentage of Daily Limit for Added/Free Sugar (WHO / Thai Health limit max 24g / 6 tsp)
  double sugarRdiPercentage([double limit = 24.0]) {
    if (limit <= 0) return 0.0;
    return (sugar / limit) * 100.0;
  }

  /// Calories derived from Protein (4 kcal/g)
  double get proteinKcal => protein * 4.0;

  /// Calories derived from Carbohydrates (4 kcal/g)
  double get carbsKcal => carbohydrates * 4.0;

  /// Calories derived from Total Fat (9 kcal/g)
  double get fatKcal => fat * 9.0;

  /// Total calculated macronutrient calories
  double get totalMacroKcal => proteinKcal + carbsKcal + fatKcal;

  /// Protein energy ratio (0.0 to 1.0)
  double get proteinRatio => totalMacroKcal > 0 ? (proteinKcal / totalMacroKcal) : 0.0;

  /// Carbohydrate energy ratio (0.0 to 1.0)
  double get carbsRatio => totalMacroKcal > 0 ? (carbsKcal / totalMacroKcal) : 0.0;

  /// Fat energy ratio (0.0 to 1.0)
  double get fatRatio => totalMacroKcal > 0 ? (fatKcal / totalMacroKcal) : 0.0;

  String toJson() => json.encode(toMap());

  factory FoodItem.fromJson(String source) =>
      FoodItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FoodItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
