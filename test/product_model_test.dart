import 'package:flutter_test/flutter_test.dart';
import 'package:studytodolist/models/product_model.dart';

void main() {
  test('reads premium flag from the admin API field', () {
    final product = ProductModel.fromJson({
      'id': 'product-1',
      'name': 'Premium item',
      'price': 20,
      'rarity': 'RARE',
      'stock': 3,
      'discountPct': 0,
      'isAvailable': true,
      'isPremiumOnly': true,
    });

    expect(product.premiumOnly, isTrue);
  });
}
