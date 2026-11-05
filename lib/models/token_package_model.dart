// lib/models/token_package_model.dart

class TokenPackageModel {
  final String id;
  final int amount;
  final int tokens;
  final String label;
  final int bonusPercent;

  const TokenPackageModel({
    required this.id,
    required this.amount,
    required this.tokens,
    required this.label,
    this.bonusPercent = 0,
  });

  factory TokenPackageModel.fromJson(Map<String, dynamic> json) {
    return TokenPackageModel(
      id: json['id'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      tokens: json['tokens'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      bonusPercent: json['bonusPercent'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'tokens': tokens,
      'label': label,
      'bonusPercent': bonusPercent,
    };
  }
}
