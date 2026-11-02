// lib/models/product_model.dart

class ProductCategoryModel {
  final String id;
  final String name;

  const ProductCategoryModel({
    required this.id,
    required this.name,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int price;
  final String rarity; // common, rare, epic, legendary
  final int stock;
  final int discountPct;
  final bool isAvailable;
  final bool premiumOnly;
  final String? categoryId;
  final ProductCategoryModel? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.price,
    required this.rarity,
    required this.stock,
    required this.discountPct,
    required this.isAvailable,
    required this.premiumOnly,
    this.categoryId,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  int get discountedPrice {
    if (discountPct <= 0) return price;
    return (price * (100 - discountPct) ~/ 100);
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      price: json['price'] as int? ?? 0,
      rarity: json['rarity'] as String? ?? 'common',
      stock: json['stock'] as int? ?? 0,
      discountPct: json['discountPct'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      premiumOnly: json['premiumOnly'] as bool? ?? false,
      categoryId: json['categoryId'] as String?,
      category: json['category'] != null
          ? ProductCategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'price': price,
        'rarity': rarity,
        'stock': stock,
        'discountPct': discountPct,
        'isAvailable': isAvailable,
        'premiumOnly': premiumOnly,
        'categoryId': categoryId,
        'category': category?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
