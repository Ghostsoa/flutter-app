// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: (json['id'] as num).toInt(),
      type: $enumDecode(_$TransactionTypeEnumMap, json['transaction_type']),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      balanceAfter: (json['balance_after'] as num).toDouble(),
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transaction_type': _$TransactionTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'description': instance.description,
      'created_at': instance.createdAt.toIso8601String(),
      'balance_after': instance.balanceAfter,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.deduction: 'deduction',
  TransactionType.deduct: 'deduct',
  TransactionType.recharge: 'recharge',
  TransactionType.reward: 'reward',
  TransactionType.gift: 'gift',
};
