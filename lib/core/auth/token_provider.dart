// lib/core/auth/token_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/storage_keys.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Provides the JWT token stored in secure storage.
/// Returns null if no token is present.
final authTokenProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return await storage.read(StorageKeys.accessToken);
});

/// Provides the current user ID stored in secure storage or authProvider.
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authProvider).user;
  if (user != null && user.id.isNotEmpty) return user.id;
  final storage = ref.watch(secureStorageProvider);
  return await storage.read(StorageKeys.userId);
});
