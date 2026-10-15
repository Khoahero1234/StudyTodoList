// lib/core/mock/mock_auth_repository.dart
// ─── Repository giả thay thế AuthRepository khi kUseMock = true ───
import 'dart:async';
import '../../models/user_model.dart';
import 'mock_data.dart';

class MockAuthRepository {
  // Trạng thái đăng nhập trong bộ nhớ (không lưu vào storage)
  UserModel? _currentUser;

  /// Đăng nhập với bất kỳ email + password nào.
  /// Nếu muốn kiểm tra chặt hơn, uncomment đoạn bên dưới.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Giả lập độ trễ mạng
    await Future.delayed(const Duration(milliseconds: 800));

    // Chấp nhận bất kỳ thông tin nào (hoặc chỉ demo account)
    // if (email != mockAcceptedEmail || password != mockAcceptedPassword) {
    //   throw Exception('Email hoặc mật khẩu không đúng');
    // }

    _currentUser = mockUser.copyWith(email: email);
    return _currentUser!;
  }

  /// Đăng ký tài khoản mới — luôn thành công trong mock mode.
  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = mockUser.copyWith(email: email, username: username);
    return _currentUser!;
  }

  /// Đăng xuất — xóa user khỏi bộ nhớ.
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  /// Thử tự đăng nhập (auto-login) — luôn trả về null để buộc login lại.
  /// Có thể trả về mockUser nếu muốn bỏ qua màn hình login.
  Future<UserModel?> tryAutoLogin() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Trả về null → luôn hiện màn hình Login
    // Trả về mockUser → bỏ qua màn hình Login (tự động vào Home)
    return null;
  }

  /// Quên mật khẩu — luôn thành công, không làm gì.
  Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Không làm gì trong mock mode
  }

  /// Lấy thông tin user hiện tại.
  Future<UserModel> getMe() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _currentUser ?? mockUser;
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Không làm gì trong mock mode
  }

  Future<bool> hasValidSession() async => _currentUser != null;
}
