import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request_model.dart';
import '../../models/quote_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_avatar.dart';
import '../request/create_request_screen.dart';
import '../request/request_detail_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../auth/login_screen.dart';
import '../quote/quote_detail_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  @override
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  ServiceCategory? _selectedCategory;
  RequestStatus? _selectedRequestStatus;
  QuoteStatus? _selectedQuoteStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('マイページ'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ProfileAvatar(
                  imageUrl: user.profileImageUrl,
                  radius: 20,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.settings),
                              title: const Text('プロフィール編集'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileEditScreen(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.logout),
                              title: const Text('ログアウト'),
                              onTap: () async {
                                Navigator.pop(context);
                                final userProvider = context.read<UserProvider>();
                                await userProvider.signOut();
                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'あなたの依頼'),
                Tab(text: '受信した見積もり'),
              ],
            ),
          ),
          body: Column(
            children: [
              // デバッグ情報表示
              ProfileImageDebugInfo(imageUrl: user.profileImageUrl),
              // フィルター部分
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'こんにちは、${user.displayName}さん',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'フィルター',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // カテゴリフィルター
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('すべて', null),
                          ...ServiceCategory.values.map(
                            (category) => _buildCategoryChip(
                              category.displayName,
                              category,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ステータスフィルター
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _tabController.index == 0
                            ? _buildRequestStatusFilters()
                            : _buildQuoteStatusFilters(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 依頼タブ
                    _buildRequestsTab(user),
                    // 見積もりタブ
                    _buildQuotesTab(user),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _tabController.index == 0
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateRequestScreen(),
                      ),
                    );
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, ServiceCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  List<Widget> _buildRequestStatusFilters() {
    return [
      _buildRequestStatusChip('すべて', null),
      _buildRequestStatusChip('募集中', RequestStatus.open),
      _buildRequestStatusChip('見積もり受信', RequestStatus.quoted),
      _buildRequestStatusChip('決定済み', RequestStatus.accepted),
      _buildRequestStatusChip('完了', RequestStatus.completed),
      _buildRequestStatusChip('キャンセル', RequestStatus.cancelled),
    ];
  }

  List<Widget> _buildQuoteStatusFilters() {
    return [
      _buildQuoteStatusChip('すべて', null),
      _buildQuoteStatusChip('審査中', QuoteStatus.pending),
      _buildQuoteStatusChip('承認済み', QuoteStatus.accepted),
      _buildQuoteStatusChip('却下', QuoteStatus.rejected),
      _buildQuoteStatusChip('完了', QuoteStatus.completed),
    ];
  }

  Widget _buildRequestStatusChip(String label, RequestStatus? status) {
    final isSelected = _selectedRequestStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedRequestStatus = selected ? status : null;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: _getRequestStatusColor(status).withOpacity(0.2),
        checkmarkColor: _getRequestStatusColor(status),
      ),
    );
  }

  Widget _buildQuoteStatusChip(String label, QuoteStatus? status) {
    final isSelected = _selectedQuoteStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedQuoteStatus = selected ? status : null;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: _getQuoteStatusColor(status).withOpacity(0.2),
        checkmarkColor: _getQuoteStatusColor(status),
      ),
    );
  }

  Widget _buildRequestsTab(UserModel user) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    return StreamBuilder<List<RequestModel>>(
      stream: databaseService.getRequestsByClient(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'まだ依頼がありません',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '右下のボタンから最初の依頼を作成しましょう',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            // フィルタリング
            List<RequestModel> filteredRequests = snapshot.data!;
            
            if (_selectedCategory != null) {
              filteredRequests = filteredRequests
                  .where((request) => request.category == _selectedCategory)
                  .toList();
            }
            
            if (_selectedRequestStatus != null) {
              filteredRequests = filteredRequests
                  .where((request) => request.status == _selectedRequestStatus)
                  .toList();
            }

            if (filteredRequests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.filter_list_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'フィルター条件に一致する依頼がありません',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final request = filteredRequests[index];
                return _buildRequestCard(request, user);
              },
            );
          },
        );
  }

  Widget _buildQuotesTab(UserModel user) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    return StreamBuilder<List<QuoteModel>>(
      stream: databaseService.getQuotesForClient(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.request_quote_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'まだ見積もりがありません',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '依頼を投稿すると見積もりが届きます',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            // フィルタリング
            List<QuoteModel> filteredQuotes = snapshot.data!;
            
            if (_selectedQuoteStatus != null) {
              filteredQuotes = filteredQuotes
                  .where((quote) => quote.status == _selectedQuoteStatus)
                  .toList();
            }

            if (filteredQuotes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.filter_list_off,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'フィルター条件に一致する見積もりがありません',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredQuotes.length,
              itemBuilder: (context, index) {
                final quote = filteredQuotes[index];
                return _buildQuoteCard(quote, user, databaseService);
              },
            );
          },
        );
  }

  Widget _buildRequestCard(RequestModel request, UserModel user) {
    final daysUntilDeadline = request.deadline.difference(DateTime.now()).inDays;
    final isUrgent = daysUntilDeadline <= 3;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestDetailScreen(request: request),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileAvatar(
                    imageUrl: user.profileImageUrl,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(request.category).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                request.category.displayName,
                                style: TextStyle(
                                  color: _getCategoryColor(request.category),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRequestStatusColor(request.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getRequestStatusText(request.status),
                                style: TextStyle(
                                  color: _getRequestStatusColor(request.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isUrgent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '急募',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.attach_money, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '予算: ¥${(request.budget ?? 0).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: isUrgent ? Colors.red : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '締切: ${request.deadline.month}/${request.deadline.day} (${daysUntilDeadline}日後)',
                              style: TextStyle(
                                color: isUrgent ? Colors.red : Colors.grey[600],
                                fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 取り消しボタン（募集中または見積もり受信中のみ）
                  if (request.status == RequestStatus.open || 
                      request.status == RequestStatus.quoted)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'cancel') {
                          _showCancelRequestDialog(request);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(Icons.cancel_outlined, color: Colors.red),
                              SizedBox(width: 8),
                              Text('依頼を取り消す'),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteCard(QuoteModel quote, UserModel user, DatabaseService databaseService) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // RequestDetailScreenには依頼情報も必要なので取得
          final request = await databaseService.getRequest(quote.requestId);
          if (request != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuoteDetailScreen(
                  quote: quote,
                  request: request,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FutureBuilder<UserModel?>(
                    future: databaseService.getUser(quote.professionalId),
                    builder: (context, userSnapshot) {
                      return ProfileAvatar(
                        imageUrl: userSnapshot.data?.profileImageUrl,
                        radius: 20,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getQuoteStatusColor(quote.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getQuoteStatusText(quote.status),
                            style: TextStyle(
                              color: _getQuoteStatusColor(quote.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          quote.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                quote.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '見積もり額: ¥${quote.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.reform:
        return Colors.orange;
      case ServiceCategory.it:
        return Colors.blue;
      case ServiceCategory.photo:
        return Colors.purple;
      case ServiceCategory.design:
        return Colors.pink;
      case ServiceCategory.education:
        return Colors.green;
      case ServiceCategory.other:
        return Colors.grey;
    }
  }

  Color _getRequestStatusColor(RequestStatus? status) {
    switch (status) {
      case RequestStatus.open:
        return Colors.blue;
      case RequestStatus.quoted:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.green;
      case RequestStatus.completed:
        return Colors.purple;
      case RequestStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRequestStatusText(RequestStatus status) {
    switch (status) {
      case RequestStatus.open:
        return '募集中';
      case RequestStatus.quoted:
        return '見積もり受信';
      case RequestStatus.accepted:
        return '決定済み';
      case RequestStatus.completed:
        return '完了';
      case RequestStatus.cancelled:
        return 'キャンセル';
    }
  }

  Color _getQuoteStatusColor(QuoteStatus? status) {
    switch (status) {
      case QuoteStatus.pending:
        return Colors.orange;
      case QuoteStatus.accepted:
        return Colors.green;
      case QuoteStatus.rejected:
        return Colors.red;
      case QuoteStatus.completed:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getQuoteStatusText(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.pending:
        return '審査中';
      case QuoteStatus.accepted:
        return '承認済み';
      case QuoteStatus.rejected:
        return '却下';
      case QuoteStatus.completed:
        return '完了';
      case QuoteStatus.cancelled:
        return 'キャンセル';
    }
  }

  void _showCancelRequestDialog(RequestModel request) {
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
              _cancelRequest(request);
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

  Future<void> _cancelRequest(RequestModel request) async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      await databaseService.cancelRequest(
        request.id,
        'Client cancelled the request',
      );

      if (mounted) {
        Navigator.of(context).pop(); // ローディング閉じる
        
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
} 