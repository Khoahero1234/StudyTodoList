// lib/models/product_model.dart

class ProductCategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;

  const ProductCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconUrl': iconUrl,
      };
}

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int price;
  final String rarity; // COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
  final int stock; // -1 = unlimited
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

  bool get isUnlimitedStock => stock < 0;

  bool get isOutOfStock => !isAvailable || stock == 0;

  bool get canPurchase => isAvailable && (stock < 0 || stock > 0);

  String get stockLabel {
    if (!isAvailable || stock == 0) return 'Hết hàng';
    if (stock < 0) return 'Không giới hạn';
    return '$stock';
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? price,
    String? rarity,
    int? stock,
    int? discountPct,
    bool? isAvailable,
    bool? premiumOnly,
    String? categoryId,
    ProductCategoryModel? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      rarity: rarity ?? this.rarity,
      stock: stock ?? this.stock,
      discountPct: discountPct ?? this.discountPct,
      isAvailable: isAvailable ?? this.isAvailable,
      premiumOnly: premiumOnly ?? this.premiumOnly,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    ProductCategoryModel? parsedCategory;
    if (json['category'] is Map) {
      parsedCategory = ProductCategoryModel.fromJson(
        Map<String, dynamic>.from(json['category'] as Map),
      );
    }

    return ProductModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      rarity: json['rarity'] as String? ?? 'COMMON',
      stock: (json['stock'] as num?)?.toInt() ?? -1,
      discountPct: (json['discountPct'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      premiumOnly: json['premiumOnly'] as bool? ??
          json['isPremiumOnly'] as bool? ??
          false,
      categoryId: json['categoryId'] as String?,
      category: parsedCategory,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
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

class InventoryItemModel {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final bool isEquipped;
  final DateTime acquiredAt;
  final ProductModel? product;

  const InventoryItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.isEquipped,
    required this.acquiredAt,
    this.product,
  });

  InventoryItemModel copyWith({
    int? quantity,
    bool? isEquipped,
    ProductModel? product,
  }) {
    return InventoryItemModel(
      id: id,
      userId: userId,
      productId: productId,
      quantity: quantity ?? this.quantity,
      isEquipped: isEquipped ?? this.isEquipped,
      acquiredAt: acquiredAt,
      product: product ?? this.product,
    );
  }

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    ProductModel? parsedProduct;
    if (json['product'] is Map) {
      parsedProduct = ProductModel.fromJson(
        Map<String, dynamic>.from(json['product'] as Map),
      );
    }

    return InventoryItemModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isEquipped: json['isEquipped'] as bool? ?? false,
      acquiredAt: json['acquiredAt'] != null
          ? DateTime.tryParse(json['acquiredAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      product: parsedProduct,
    );
  }
}

class OrderItemModel {
  final String id;
  final String productId;
  final int quantity;
  final int priceAtSale;
  final ProductModel? product;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.priceAtSale,
    this.product,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    ProductModel? parsedProduct;
    if (json['product'] is Map) {
      parsedProduct = ProductModel.fromJson(
        Map<String, dynamic>.from(json['product'] as Map),
      );
    }

    return OrderItemModel(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      priceAtSale: (json['priceAtSale'] as num?)?.toInt() ??
          (json['price'] as num?)?.toInt() ??
          0,
      product: parsedProduct,
    );
  }
}

class OrderModel {
  final String id;
  final String userId;
  final int totalTokens;
  final String status;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.totalTokens,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      totalTokens: (json['totalTokens'] as num?)?.toInt() ??
          (json['totalAmount'] as num?)?.toInt() ??
          0,
      status: json['status'] as String? ?? 'COMPLETED',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: rawItems
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
