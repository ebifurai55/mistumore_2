import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request_model.dart';
import '../../models/quote_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_avatar.dart';
import '../contract/contract_screen.dart';

class QuoteDetailScreen extends StatefulWidget {
  final QuoteModel quote;
  final RequestModel request;

  const QuoteDetailScreen({
    super.key,
    required this.quote,
    required this.request,
  });

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  UserModel? _professionalUser;
  UserModel? _clientUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final professional = await _databaseService.getUser(widget.quote.professionalId);
      final client = await _databaseService.getUser(widget.request.clientId);
      if (mounted) {
        setState(() {
          _professionalUser = professional;
          _clientUser = client;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quote.title),
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ProfileAvatar(
                  imageUrl: userProvider.user?.profileImageUrl,
                  radius: 16,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 専門家情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ProfileAvatar(imageUrl: _professionalUser?.profileImageUrl, radius: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _professionalUser?.displayName ?? '専門家',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '専門家',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_professionalUser?.rating != null && _professionalUser!.rating > 0)
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${_professionalUser!.rating.toStringAsFixed(1)} (${_professionalUser!.reviewCount}件)',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.quote.status.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.quote.status.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 対象依頼情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '対象依頼',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ProfileAvatar(imageUrl: _clientUser?.profileImageUrl, radius: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.request.title,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _clientUser?.displayName ?? '依頼者',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 見積もり詳細
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '見積もり詳細',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('提案内容', widget.quote.description),
                    _buildDetailRow('料金', '¥${widget.quote.price.toStringAsFixed(0)}'),
                    _buildDetailRow('完了予定', '${widget.quote.estimatedDays}日'),
                    if (widget.quote.deliverables.isNotEmpty)
                      _buildDetailRow('成果物', widget.quote.deliverables.join(', ')),
                    if (widget.quote.notes != null)
                      _buildDetailRow('備考', widget.quote.notes!),
                    _buildDetailRow(
                      '提出日',
                      '${widget.quote.createdAt.year}/${widget.quote.createdAt.month}/${widget.quote.createdAt.day}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // アクションボタン（クライアントのみ）
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                if (userProvider.user?.uid != widget.request.clientId) {
                  return const SizedBox.shrink();
                }

                if (widget.quote.status != QuoteStatus.pending) {
                  return const SizedBox.shrink();
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'アクション',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : () => _rejectQuote(),
                                icon: const Icon(Icons.close, color: Colors.red),
                                label: const Text('却下', style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : () => _acceptQuote(),
                                icon: const Icon(Icons.check),
                                label: const Text('承認'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // メッセージ機能は将来実装予定
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _acceptQuote() async {
    final shouldAccept = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('見積もりを承認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('この見積もりを承認しますか？'),
            const SizedBox(height: 8),
            Text(
              '料金: ¥${widget.quote.price.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '完了予定: ${widget.quote.estimatedDays}日',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '承認後は専門家との作業が開始されます。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('承認'),
          ),
        ],
      ),
    );

    if (shouldAccept == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final contractId = await _databaseService.acceptQuote(widget.quote.id, widget.request.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('見積もりを承認し、契約を作成しました')),
          );
          
          // 契約画面に遷移
          final contract = await _databaseService.getContract(contractId);
          if (contract != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ContractScreen(contract: contract),
              ),
            );
          } else {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _rejectQuote() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        String selectedReason = '予算が合いません';
        return AlertDialog(
          title: const Text('見積もりを却下'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('却下理由を選択してください：'),
              const SizedBox(height: 12),
              ...['予算が合いません', '期間が長すぎます', '提案内容が希望と異なります', 'その他'].map((reason) {
                return RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    if (value != null) {
                      selectedReason = value;
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedReason),
              child: const Text('却下'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedQuote = widget.quote.copyWith(
          status: QuoteStatus.rejected,
          rejectedAt: DateTime.now(),
          rejectionReason: reason,
        );
        await _databaseService.updateQuote(updatedQuote);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('見積もりを却下しました')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }


}