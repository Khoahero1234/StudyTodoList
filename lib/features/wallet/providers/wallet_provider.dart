// lib/features/wallet/providers/wallet_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/token_transaction_model.dart';
import '../data/wallet_remote_datasource.dart';

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return WalletRemoteDataSource(dioClient);
});

class WalletState {
  final int balance;
  final List<TokenTransactionModel> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const WalletState({
    this.balance = 0,
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
  });

  WalletState copyWith({
    int? balance,
    List<TokenTransactionModel>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool clearError = false,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRemoteDataSource _remoteDataSource;
  final Ref _ref;

  WalletNotifier(this._remoteDataSource, this._ref) : super(const WalletState()) {
    loadWalletData();
  }

  Future<void> loadWalletData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (kUseMock) {
        await Future.delayed(const Duration(milliseconds: 200));
        final userState = _ref.read(authProvider);
        final balance = userState.user?.tokenBalance ?? 250;
        state = state.copyWith(
          balance: balance,
          transactions: state.transactions.isNotEmpty
              ? state.transactions
              : [
                  TokenTransactionModel(
                    id: 'tx-001',
                    walletId: 'wallet-001',
                    type: 'REWARD',
                    amount: balance,
                    description: 'Token tích lũy từ nhiệm vụ & điểm danh',
                    createdAt: DateTime.now(),
                  ),
                ],
          isLoading: false,
          hasMore: false,
        );
        return;
      }

      final walletData = await _remoteDataSource.getWalletInfo();
      final balance = (walletData['balance'] as num?)?.toInt() ?? 0;

      final txData = await _remoteDataSource.getTransactions(page: 1, limit: 20);
      final rawList = txData['transactions'] as List<dynamic>? ?? [];
      final transactions = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => TokenTransactionModel.fromJson(e))
          .toList();

      final pagination = txData['pagination'] as Map<String, dynamic>? ?? {};
      final currentPage = pagination['page'] as int? ?? 1;
      final totalPages = pagination['totalPages'] as int? ?? 1;

      state = state.copyWith(
        balance: balance,
        transactions: transactions,
        isLoading: false,
        currentPage: currentPage,
        totalPages: totalPages,
        hasMore: currentPage < totalPages,
      );

      // Đồng bộ số dư token sang authProvider để Home / Profile / Shop luôn nhất quán
      _ref.read(authProvider.notifier).setTokenBalance(balance);
    } catch (e) {
      final userState = _ref.read(authProvider);
      final fallbackBalance =
          state.balance > 0 ? state.balance : (userState.user?.tokenBalance ?? 0);
      state = state.copyWith(
        balance: fallbackBalance,
        isLoading: false,
      );
    }
  }

  Future<void> refreshWallet() async {
    await loadWalletData();
  }

  void addRewardTransaction(int amount, String taskTitle) {
    final newBalance = state.balance + amount;
    final newTx = TokenTransactionModel(
      id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
      walletId: 'wallet-001',
      type: 'REWARD',
      amount: amount,
      description: 'Hoàn thành nhiệm vụ: $taskTitle',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      balance: newBalance,
      transactions: [newTx, ...state.transactions],
    );
    _ref.read(authProvider.notifier).setTokenBalance(newBalance);
  }

  /// Trừ token ngay lập tức trên UI khi mua hàng trong Shop và thêm lịch sử giao dịch
  void recordPurchaseDeduction({
    required int deductedTokens,
    required String itemSummary,
    int? updatedServerBalance,
    TokenTransactionModel? serverTransaction,
  }) {
    final newBalance = updatedServerBalance ??
        (state.balance - deductedTokens).clamp(0, 999999999);
    final newTx = serverTransaction ??
        TokenTransactionModel(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          walletId: 'wallet-001',
          type: 'SPEND',
          amount: -deductedTokens,
          description: 'Mua vật phẩm Shop: $itemSummary',
          createdAt: DateTime.now(),
        );

    final updatedTransactions = [
      newTx,
      ...state.transactions.where((t) => t.id != newTx.id),
    ];

    state = state.copyWith(
      balance: newBalance,
      transactions: updatedTransactions,
    );
    _ref.read(authProvider.notifier).setTokenBalance(newBalance);
  }

  Future<void> loadMoreTransactions() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final txData =
          await _remoteDataSource.getTransactions(page: nextPage, limit: 20);
      final rawList = txData['transactions'] as List<dynamic>? ?? [];
      final newTransactions = rawList
          .map((e) => TokenTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = txData['pagination'] as Map<String, dynamic>? ?? {};
      final totalPages = pagination['totalPages'] as int? ?? state.totalPages;

      state = state.copyWith(
        transactions: [...state.transactions, ...newTransactions],
        isLoadingMore: false,
        currentPage: nextPage,
        totalPages: totalPages,
        hasMore: nextPage < totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final remoteDataSource = ref.watch(walletRemoteDataSourceProvider);
  return WalletNotifier(remoteDataSource, ref);
});
