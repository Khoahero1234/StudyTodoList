// lib/core/auth/token_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';

/// Provides the JWT token stored in secure storage.
/// Returns null if no token is present.
final authTokenProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  // The token key used by the auth flow – adjust if different.
  return await storage.read('jwt');
});
