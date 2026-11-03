import 'package:flutter_test/flutter_test.dart';
import 'package:studytodolist/models/user_model.dart';

void main() {
  test('normalizes API admin role and recognizes administrators', () {
    final user = UserModel.fromJson({
      'id': 'admin-1',
      'email': 'admin@example.com',
      'username': 'admin',
      'role': 'ADMIN',
    });

    expect(user.role, 'admin');
    expect(user.isAdmin, isTrue);
  });

  test('keeps customer accounts non-admin', () {
    final user = UserModel.fromJson({
      'id': 'customer-1',
      'email': 'customer@example.com',
      'username': 'customer',
      'role': 'CUSTOMER',
    });

    expect(user.role, 'customer');
    expect(user.isAdmin, isFalse);
  });
}
