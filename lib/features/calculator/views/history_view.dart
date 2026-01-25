import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/calculation_history.dart';
import '../services/history_service.dart';

class HistoryView extends StatelessWidget {
  final HistoryService historyService;

  const HistoryView({
    super.key,
    required this.historyService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app.history'.tr()),
      ),
      body: Consumer<HistoryService>(
        builder: (context, historyService, _) {
          final history = historyService.getHistory();
          if (history.isEmpty) {
            return Center(
              child: Text('history.empty'.tr()),
            );
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _HistoryItem(item: item);
            },
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final CalculationHistory item;

  const _HistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.expression),
      subtitle: Text(
        '${item.result} • ${_formatDate(item.timestamp)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () {
          context.read<HistoryService>().removeFromHistory(item);
        },
      ),
      onTap: () {
        Navigator.pop(context, item);
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
