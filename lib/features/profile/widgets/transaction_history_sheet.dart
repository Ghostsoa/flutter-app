import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api/wallet_api.dart';
import '../../../data/models/transaction.dart';
import '../../../core/utils/logger.dart';

class TransactionHistorySheet extends StatefulWidget {
  final WalletApi walletApi;

  const TransactionHistorySheet({
    super.key,
    required this.walletApi,
  });

  @override
  State<TransactionHistorySheet> createState() =>
      _TransactionHistorySheetState();
}

class _TransactionHistorySheetState extends State<TransactionHistorySheet> {
  final List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      Logger.info('加载最近交易记录');
      final result = await widget.walletApi.getTransactions(
        page: 1,
        pageSize: 10, // 一次性加载较多记录
      );

      if (mounted) {
        setState(() {
          _transactions.addAll(result.items);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      Logger.error(
        '加载交易记录失败',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '消耗记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _transactions.isEmpty
                    ? Center(
                        child: Text(
                          '暂无消费记录',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          final formattedTime = DateFormat('MM-dd HH:mm')
                              .format(transaction.createdAt);

                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    transaction.description,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  '小懿币: ${transaction.balanceAfter.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              formattedTime,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                            trailing: Text(
                              '${transaction.amount >= 0 ? "+" : ""}${transaction.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: transaction.amount >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
