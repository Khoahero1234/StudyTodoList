// lib/models/token_transaction_model.dart

class TokenTransactionModel {
  final String id;
  final String walletId;
  final int amount;
  final String type;
  final String? description;
  final String? referenceId;
  final DateTime createdAt;

  const TokenTransactionModel({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    this.description,
    this.referenceId,
    required this.createdAt,
  });

  factory TokenTransactionModel.fromJson(Map<String, dynamic> json) {
    return TokenTransactionModel(
      id: json['id'] as String? ?? '',
      walletId: json['walletId'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      type: json['type'] as String? ?? 'TRANSACTION',
      description: json['description'] as String?,
      referenceId: json['referenceId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'walletId': walletId,
        'amount': amount,
        'type': type,
        'description': description,
        'referenceId': referenceId,
        'createdAt': createdAt.toIso8601String(),
      };
}
