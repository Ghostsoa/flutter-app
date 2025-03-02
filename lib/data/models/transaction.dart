import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

enum TransactionType {
  @JsonValue('deduction')
  deduction,
  @JsonValue('deduct')
  deduct,
  @JsonValue('recharge')
  recharge,
  @JsonValue('reward')
  reward,
  @JsonValue('gift')
  gift,
}

@JsonSerializable()
class Transaction {
  final int id;
  @JsonKey(name: 'transaction_type')
  final TransactionType type;
  final double amount;
  final String description;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'balance_after')
  final double balanceAfter;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    required this.balanceAfter,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  String get typeText {
    switch (type) {
      case TransactionType.deduction:
      case TransactionType.deduct:
        return '扣费';
      case TransactionType.recharge:
        return '充值';
      case TransactionType.reward:
        return '奖励';
      case TransactionType.gift:
        return '赠送';
    }
  }
}
