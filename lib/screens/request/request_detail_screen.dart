import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request_model.dart';
import '../../models/quote_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_avatar.dart';
import '../quote/quote_detail_screen.dart';

// プロキシ画像表示用のウィジェット
class ProxiedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const ProxiedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

// クイック返信テンプレート
class QuickReplyTemplate {
  static const List<String> clientReplies = [
    'ありがとうございます',
    '検討します',
    '質問があります',
    '他の案も見たいです',
    '予算を相談したいです',
  ];

  static const List<String> professionalReplies = [
    'お疲れ様です',
    'ご確認ください',
    '修正いたします',
    'ご質問をお待ちしています',
    '追加で対応可能です',
  ];
}

// 見積もりソート種類
enum QuoteSortType {
  newest('新着順'),
  oldest('古い順'),
  priceAsc('価格：安い順'),
  priceDesc('価格：高い順'),
  daysAsc('期間：短い順'),
  daysDesc('期間：長い順'),
  rating('評価順');

  const QuoteSortType(this.displayName);
  final String displayName;
}

class RequestDetailScreen extends StatefulWidget {
  final RequestModel request;

  const RequestDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  UserModel? _clientUser;
  QuoteSortType _currentSortType = QuoteSortType.newest;
  QuoteStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _loadClientUser();
  }

  Future<void> _loadClientUser() async {
    try {
      final user = await _databaseService.getUser(widget.request.clientId);
      if (mounted) {
        setState(() {
          _clientUser = user;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  List<QuoteModel> _sortQuotes(List<QuoteModel> quotes) {
    final sortedQuotes = List<QuoteModel>.from(quotes);
    
    switch (_currentSortType) {
      case QuoteSortType.newest:
        sortedQuotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case QuoteSortType.oldest:
        sortedQuotes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case QuoteSortType.priceAsc:
        sortedQuotes.sort((a, b) => a.price.compareTo(b.price));
        break;
      case QuoteSortType.priceDesc:
        sortedQuotes.sort((a, b) => b.price.compareTo(a.price));
        break;
      case QuoteSortType.daysAsc:
        sortedQuotes.sort((a, b) => a.estimatedDays.compareTo(b.estimatedDays));
        break;
      case QuoteSortType.daysDesc:
        sortedQuotes.sort((a, b) => b.estimatedDays.compareTo(a.estimatedDays));
        break;
      case QuoteSortType.rating:
        // 評価順は専門家の評価を取得する必要があるため、別途実装
        break;
    }
    
    return sortedQuotes;
  }

  List<QuoteModel> _filterQuotes(List<QuoteModel> quotes) {
    if (_statusFilter == null) return quotes;
    return quotes.where((quote) => quote.status == _statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.request.title),
        actions: [
          // 取り消しボタン（依頼者のみ、募集中または見積もり受信中のみ）
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final canCancel = userProvider.currentUser?.uid == widget.request.clientId &&
                  (widget.request.status == RequestStatus.open || 
                   widget.request.status == RequestStatus.quoted);
              
              if (!canCancel) {
                return const SizedBox.shrink();
              }
              
              return IconButton(
                icon: const Icon(Icons.cancel_outlined),
                onPressed: () => _showCancelDialog(),
                tooltip: '依頼を取り消す',
              );
            },
          ),
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ProfileAvatar(
                  imageUrl: userProvider.currentUser?.profileImageUrl,
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
            // 依頼者情報
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ProfileAvatar(imageUrl: _clientUser?.profileImageUrl, radius: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _clientUser?.displayName ?? 'ユーザー',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '依頼者',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.request.status.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.request.status.displayName,
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

            // 依頼詳細
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '依頼詳細',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('カテゴリ', widget.request.category.displayName),
                    _buildDetailRow('説明', widget.request.description),
                    if (widget.request.budget != null)
                      _buildDetailRow('予算', '¥${widget.request.budget!.toStringAsFixed(0)}'),
                    if (widget.request.location != null)
                      _buildDetailRow('場所', widget.request.location!),
                    _buildDetailRow(
                      '希望完了日',
                      '${widget.request.deadline.year}/${widget.request.deadline.month}/${widget.request.deadline.day}',
                    ),
                    if (widget.request.requirements.isNotEmpty)
                      _buildDetailRow('要件', widget.request.requirements.join(', ')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 画像表示
            if (widget.request.imageUrls.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '参考画像',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.request.imageUrls.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  _showImageDialog(widget.request.imageUrls[index]);
                                },
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: ProxiedImage(
                                      imageUrl: widget.request.imageUrls[index],
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 見積もりリスト
            StreamBuilder<List<QuoteModel>>(
              stream: _databaseService.getQuotesByRequest(widget.request.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: Text('エラー: ${snapshot.error}')),
                    ),
                  );
                }

                final allQuotes = snapshot.data ?? [];
                final filteredQuotes = _filterQuotes(allQuotes);
                final quotes = _sortQuotes(filteredQuotes);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ヘッダー行
                        Row(
                          children: [
                            Text(
                              '受信した見積もり',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${quotes.length}件',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Consumer<UserProvider>(
                              builder: (context, userProvider, child) {
                                if (userProvider.currentUser?.uid != widget.request.clientId) {
                                  return const SizedBox.shrink();
                                }
                                final pendingQuotes = quotes.where((q) => q.status == QuoteStatus.pending).toList();
                                
                                if (pendingQuotes.length <= 1) {
                                  return const SizedBox.shrink();
                                }
                                
                                return Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showQuoteComparison(pendingQuotes),
                                      icon: const Icon(Icons.compare_arrows, size: 16),
                                      label: const Text('比較', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _showBestQuoteSelection(pendingQuotes),
                                      icon: const Icon(Icons.auto_awesome, size: 16),
                                      label: const Text('おすすめ', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ソート・フィルター行
                        if (allQuotes.isNotEmpty) ...[
                          Row(
                            children: [
                              // ソート
                              PopupMenuButton<QuoteSortType>(
                                onSelected: (sortType) {
                                  setState(() {
                                    _currentSortType = sortType;
                                  });
                                },
                                itemBuilder: (context) => QuoteSortType.values.map((sortType) {
                                  return PopupMenuItem(
                                    value: sortType,
                                    child: Row(
                                      children: [
                                        if (_currentSortType == sortType)
                                          const Icon(Icons.check, size: 16),
                                        if (_currentSortType != sortType)
                                          const SizedBox(width: 16),
                                        const SizedBox(width: 8),
                                        Text(sortType.displayName),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.sort, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _currentSortType.displayName,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const Icon(Icons.arrow_drop_down, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // フィルター
                              PopupMenuButton<QuoteStatus?>(
                                onSelected: (status) {
                                  setState(() {
                                    _statusFilter = status;
                                  });
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: null,
                                    child: Text('すべて'),
                                  ),
                                  ...QuoteStatus.values.map((status) {
                                    return PopupMenuItem(
                                      value: status,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: status.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(status.displayName),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.filter_list, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        _statusFilter?.displayName ?? 'すべて',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const Icon(Icons.arrow_drop_down, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (quotes.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('まだ見積もりが届いていません'),
                            ),
                          )
                        else ...[
                          if (quotes.length > 1) ...[
                            _buildQuoteSummary(quotes),
                            const SizedBox(height: 16),
                          ],
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: quotes.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final quote = quotes[index];
                              return _buildEnhancedQuoteCard(quote, showRanking: quotes.length > 1);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
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

  // 強化された見積もりカード
  Widget _buildEnhancedQuoteCard(QuoteModel quote, {bool showRanking = false}) {
    return FutureBuilder<UserModel?>(
      future: _databaseService.getUser(quote.professionalId),
      builder: (context, snapshot) {
        final professional = snapshot.data;
        
        return Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuoteDetailScreen(
                    quote: quote,
                    request: widget.request,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー行
                  Row(
                    children: [
                      ProfileAvatar(imageUrl: professional?.profileImageUrl, radius: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              professional?.displayName ?? '専門家',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (professional?.rating != null && professional!.rating > 0) ...[
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${professional.rating.toStringAsFixed(1)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _formatTimestamp(quote.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: quote.status.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          quote.status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 見積もりタイトル
                  Text(
                    quote.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 見積もり説明
                  Text(
                    quote.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // 価格と期間の大きな表示
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '見積もり価格',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '¥${quote.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '納期',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${quote.estimatedDays}日',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 成果物数と追加情報
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment, size: 12, color: Colors.purple.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '成果物 ${quote.deliverables.length}個',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (widget.request.budget != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: quote.price <= widget.request.budget! 
                                ? Colors.green.shade50 
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            quote.price <= widget.request.budget! 
                                ? '予算内' 
                                : '予算超過',
                            style: TextStyle(
                              fontSize: 11,
                              color: quote.price <= widget.request.budget! 
                                  ? Colors.green.shade700 
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // クイック返信ボタン（クライアントのみ）
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      if (userProvider.currentUser?.uid != widget.request.clientId) {
                        return const SizedBox.shrink();
                      }
                      
                      return Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: QuickReplyTemplate.clientReplies.take(3).map((reply) {
                          return SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              onPressed: () => _sendQuickReply(quote, reply),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: Size.zero,
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                reply,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('画像'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: ProxiedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendQuickReply(QuoteModel quote, String reply) {
    // TODO: メッセージング機能実装時に追加
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('「$reply」を送信しました')),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('依頼を取り消しますか？'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('この操作は取り消すことができません。'),
            SizedBox(height: 8),
            Text('• 受信済みの見積もりはすべてキャンセルされます'),
            Text('• 専門家に通知が送信されます'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('取り消す'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRequest() async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await _databaseService.cancelRequest(
        widget.request.id,
        'Client cancelled the request',
      );

      if (mounted) {
        Navigator.of(context).pop(); // ローディング閉じる
        Navigator.of(context).pop(); // 詳細画面を閉じる
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('依頼を取り消しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // ローディング閉じる
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 見積もりサマリー表示
  Widget _buildQuoteSummary(List<QuoteModel> quotes) {
    final pendingQuotes = quotes.where((q) => q.status == QuoteStatus.pending).toList();
    if (pendingQuotes.isEmpty) return const SizedBox.shrink();

    final prices = pendingQuotes.map((q) => q.price).toList();
    final days = pendingQuotes.map((q) => q.estimatedDays).toList();
    
    prices.sort();
    days.sort();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '見積もりサマリー (${pendingQuotes.length}件)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '価格範囲',
                  '¥${prices.first.toStringAsFixed(0)} - ¥${prices.last.toStringAsFixed(0)}',
                  Icons.attach_money,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  '期間範囲',
                  '${days.first} - ${days.last}日',
                  Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  // 見積もり比較画面表示
  void _showQuoteComparison(List<QuoteModel> quotes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Text(
                    '見積もり比較',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildComparisonTable(quotes),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 比較表作成
  Widget _buildComparisonTable(List<QuoteModel> quotes) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: [
          const DataColumn(label: Text('項目')),
          ...quotes.map((quote) => DataColumn(
            label: FutureBuilder<UserModel?>(
              future: _databaseService.getUser(quote.professionalId),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data?.displayName ?? '専門家',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              },
            ),
          )),
        ],
        rows: [
          DataRow(cells: [
            const DataCell(Text('価格')),
            ...quotes.map((quote) => DataCell(
              Text(
                '¥${quote.price.toStringAsFixed(0)}',
                style: TextStyle(
                  color: _isLowestPrice(quote, quotes) ? Colors.green : null,
                  fontWeight: _isLowestPrice(quote, quotes) ? FontWeight.bold : null,
                ),
              ),
            )),
          ]),
          DataRow(cells: [
            const DataCell(Text('期間')),
            ...quotes.map((quote) => DataCell(
              Text(
                '${quote.estimatedDays}日',
                style: TextStyle(
                  color: _isFastestDelivery(quote, quotes) ? Colors.blue : null,
                  fontWeight: _isFastestDelivery(quote, quotes) ? FontWeight.bold : null,
                ),
              ),
            )),
          ]),
          DataRow(cells: [
            const DataCell(Text('成果物数')),
            ...quotes.map((quote) => DataCell(
              Text('${quote.deliverables.length}個'),
            )),
          ]),
        ],
      ),
    );
  }

  // 最安価格判定
  bool _isLowestPrice(QuoteModel quote, List<QuoteModel> quotes) {
    final prices = quotes.map((q) => q.price).toList();
    return quote.price == prices.reduce((a, b) => a < b ? a : b);
  }

  // 最短納期判定
  bool _isFastestDelivery(QuoteModel quote, List<QuoteModel> quotes) {
    final days = quotes.map((q) => q.estimatedDays).toList();
    return quote.estimatedDays == days.reduce((a, b) => a < b ? a : b);
  }

  // おすすめ見積もり選択画面
  void _showBestQuoteSelection(List<QuoteModel> quotes) {
    // スコア順にソート
    final sortedQuotes = List<QuoteModel>.from(quotes);
    sortedQuotes.sort((a, b) => _calculateQuoteScore(b).compareTo(_calculateQuoteScore(a)));
    
    final bestQuote = sortedQuotes.first;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.orange),
            SizedBox(width: 8),
            Text('おすすめ見積もり'),
          ],
        ),
        content: FutureBuilder<UserModel?>(
          future: _databaseService.getUser(bestQuote.professionalId),
          builder: (context, snapshot) {
            final professional = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('総合的に最もバランスの取れた見積もりをご提案します。'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ProfileAvatar(
                            imageUrl: professional?.profileImageUrl,
                            radius: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            professional?.displayName ?? '専門家',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('価格: ¥${bestQuote.price.toStringAsFixed(0)}'),
                      Text('期間: ${bestQuote.estimatedDays}日'),
                      Text('スコア: ${(_calculateQuoteScore(bestQuote) * 100).toInt()}点'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuoteDetailScreen(
                    quote: bestQuote,
                    request: widget.request,
                  ),
                ),
              );
            },
            child: const Text('詳細を見る'),
          ),
        ],
      ),
    );
  }

  // 見積もりスコア計算
  double _calculateQuoteScore(QuoteModel quote) {
    double score = 0.0;
    
    // 価格スコア（予算との比較）
    if (widget.request.budget != null) {
      final budgetRatio = quote.price / widget.request.budget!;
      if (budgetRatio <= 1.0) {
        score += 0.3 * (1.0 - budgetRatio);
      }
    }
    
    // 期間スコア（短いほど高い）
    final dayScore = 1.0 - (quote.estimatedDays / 30.0).clamp(0.0, 1.0);
    score += 0.2 * dayScore;
    
    // レスポンス速度スコア（早いほど高い）
    final responseHours = DateTime.now().difference(widget.request.createdAt).inHours;
    final responseScore = 1.0 - (responseHours / 72.0).clamp(0.0, 1.0); // 72時間以内
    score += 0.2 * responseScore;
    
    // 成果物の充実度
    score += 0.1 * (quote.deliverables.length / 5.0).clamp(0.0, 1.0);
    
    // 説明の充実度
    score += 0.2 * (quote.description.length / 500.0).clamp(0.0, 1.0);
    
    return score.clamp(0.0, 1.0);
  }
}