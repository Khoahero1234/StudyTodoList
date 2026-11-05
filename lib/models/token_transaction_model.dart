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
      id: json['id']?.toString() ?? '',
      walletId: json['walletId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'TRANSACTION',
      description: json['description']?.toString(),
      referenceId: json['referenceId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
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
