import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request_model.dart';
import '../../models/quote_model.dart';
import '../../models/user_model.dart';
import '../../models/contract_model.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_avatar.dart';

import '../quote/quote_detail_screen.dart';
import '../quote/create_quote_screen.dart';
import '../request/request_detail_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../auth/login_screen.dart';
import '../contract/contract_screen.dart';

class ProfessionalHomeScreen extends StatefulWidget {
  @override
  _ProfessionalHomeScreenState createState() => _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends State<ProfessionalHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  ServiceCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
            title: const Text('専門家ホーム'),
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
                Tab(text: 'すべての依頼'),
                Tab(text: '新着案件'),
                Tab(text: '提出済み'),
                Tab(text: '契約'),
              ],
            ),
          ),
          body: Column(
            children: [
              // デバッグ情報表示（削除）
              // カテゴリフィルター
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'カテゴリフィルター',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // すべての依頼タブ
                    _buildAllRequestsTab(user),
                    // 新着案件タブ
                    _buildNewRequestsTab(user),
                    // 提出済み見積もりタブ
                    _buildSubmittedQuotesTab(user),
                    // 契約タブ
                    _buildContractsTab(user),
                  ],
                ),
              ),
            ],
          ),
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

  Widget _buildAllRequestsTab(UserModel user) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    return StreamBuilder<List<RequestModel>>(
      stream: databaseService.getAllRequests(category: _selectedCategory),
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
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedCategory == null 
                      ? '依頼がありません'
                      : '${_selectedCategory!.displayName}の依頼がありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                    child: const Text('すべてのカテゴリを表示'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final request = snapshot.data![index];
            return _buildRequestCard(request, user, showStatus: true);
          },
        );
      },
    );
  }

  Widget _buildNewRequestsTab(UserModel user) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    return StreamBuilder<List<RequestModel>>(
      stream: databaseService.getOpenRequests(category: _selectedCategory),
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
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedCategory == null 
                      ? '新着案件がありません'
                      : '${_selectedCategory!.displayName}の案件がありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                    child: const Text('すべてのカテゴリを表示'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final request = snapshot.data![index];
            return _buildRequestCard(request, user);
          },
        );
          },
        );
  }

  Widget _buildRequestCard(RequestModel request, UserModel user, {bool showStatus = false}) {
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
              // ヘッダー部分
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<UserModel?>(
                    future: Provider.of<DatabaseService>(context, listen: false).getUser(request.clientId),
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
                            if (showStatus) ...[
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
              
              // 依頼内容
              Text(
                request.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // 詳細情報
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
                  // 見積もり作成ボタン
                  if (request.status == RequestStatus.open) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateQuoteScreen(request: request),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description, size: 16),
                      label: const Text('見積もり作成'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '詳細を確認',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmittedQuotesTab(UserModel user) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    return StreamBuilder<List<QuoteModel>>(
      stream: databaseService.getQuotesByProfessional(user.uid),
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
                  'まだ見積もりを提出していません',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '新着案件から見積もりを提出してみましょう',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final quote = snapshot.data![index];
            return _buildQuoteCard(quote, user, databaseService);
          },
        );
          },
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

  Color _getStatusColor(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.pending:
        return Colors.orange;
      case QuoteStatus.accepted:
        return Colors.green;
      case QuoteStatus.rejected:
        return Colors.red;
      case QuoteStatus.completed:
        return Colors.blue;
      case QuoteStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(QuoteStatus status) {
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

  Color _getRequestStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.open:
        return Colors.green;
      case RequestStatus.quoted:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.blue;
      case RequestStatus.completed:
        return Colors.purple;
      case RequestStatus.cancelled:
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

  Widget _buildContractsTab(UserModel user) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    return StreamBuilder<List<ContractModel>>(
      stream: databaseService.getContractsByUser(user.uid, UserType.professional),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '契約がありません',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '見積もりが承認されると契約が作成されます',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final contracts = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            return _buildContractCard(contract);
          },
        );
      },
    );
  }

  Widget _buildContractCard(ContractModel contract) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContractScreen(contract: contract),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: contract.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      contract.status.displayName,
                      style: TextStyle(
                        color: contract.status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${contract.createdAt.month}/${contract.createdAt.day}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                contract.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                contract.description,
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
                  Icon(Icons.attach_money, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '契約金額: ¥${contract.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.schedule, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '${contract.estimatedDays}日',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (contract.status == ContractStatus.active) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _calculateProgress(contract),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(contract.status.color),
                ),
                const SizedBox(height: 4),
                Text(
                  '進捗: ${(_calculateProgress(contract) * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
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
          // QuoteDetailScreenにはrequestも必要なので取得
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
              // ヘッダー部分
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
                        Text(
                          quote.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(quote.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(quote.status),
                            style: TextStyle(
                              color: _getStatusColor(quote.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 見積もり内容
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
              
              // 価格と期間
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
                              '見積もり額: ¥${quote.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '作業期間: ${quote.estimatedDays}日',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 契約作成は将来画面で行う
                  if (quote.status == QuoteStatus.accepted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '承認済み',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateProgress(ContractModel contract) {
    if (contract.milestones.isEmpty) {
      final totalDays = contract.expectedEndDate.difference(contract.startDate).inDays;
      final elapsedDays = DateTime.now().difference(contract.startDate).inDays;
      return (elapsedDays / totalDays).clamp(0.0, 1.0);
    }
    
    final completedMilestones = contract.milestones.where((m) => m.isCompleted).length;
    return completedMilestones / contract.milestones.length;
  }
} 