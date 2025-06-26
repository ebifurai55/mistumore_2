import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request_model.dart';
import '../../models/quote_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_avatar.dart';
import '../quote/quote_detail_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.request.title),
        actions: [
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '受信した見積もり',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<QuoteModel>>(
                      stream: _databaseService.getQuotesByRequest(widget.request.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('エラー: ${snapshot.error}'));
                        }

                        final quotes = snapshot.data ?? [];

                        if (quotes.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('まだ見積もりが届いていません'),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: quotes.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final quote = quotes[index];
                            return _buildQuoteCard(quote);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
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

  Widget _buildQuoteCard(QuoteModel quote) {
    return FutureBuilder<UserModel?>(
      future: _databaseService.getUser(quote.professionalId),
      builder: (context, snapshot) {
        final professional = snapshot.data;
        
        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProfileAvatar(imageUrl: professional?.profileImageUrl, radius: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              professional?.displayName ?? '専門家',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (professional?.rating != null && professional!.rating > 0)
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${professional.rating.toStringAsFixed(1)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: quote.status.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          quote.status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quote.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quote.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '¥${quote.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${quote.estimatedDays}日で完了',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // クイック返信ボタン（クライアントのみ）
                  Consumer<UserProvider>(
                    builder: (context, userProvider, child) {
                      if (userProvider.currentUser?.uid != widget.request.clientId) {
                        return const SizedBox.shrink();
                      }
                      
                      return Wrap(
                        spacing: 4,
                        children: QuickReplyTemplate.clientReplies.take(3).map((reply) {
                          return SizedBox(
                            height: 28,
                            child: OutlinedButton(
                              onPressed: () => _sendQuickReply(quote, reply),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                reply,
                                style: const TextStyle(fontSize: 10),
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
}