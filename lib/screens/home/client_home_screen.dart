import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request_model.dart';
import '../../models/quote_model.dart';
import '../../models/user_model.dart';
import '../../models/contract_model.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_avatar.dart';
import '../request/create_request_screen.dart';
import '../request/request_detail_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../auth/login_screen.dart';
import '../quote/quote_detail_screen.dart';
import '../contract/contract_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  @override
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
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
        return Scaffold(
          appBar: AppBar(
            title: Text('ホーム'),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEditScreen(),
                      ),
                    );
                  },
                  child: ProfileAvatar(
                    imageUrl: userProvider.user?.profileImageUrl,
                    radius: 18,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileEditScreen(),
                      ),
                    );
                  } else if (value == 'logout') {
                    await userProvider.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('プロフィール編集'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('ログアウト'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: '依頼'),
                Tab(text: '見積もり'),
                Tab(text: '契約'),
              ],
            ),
          ),
          body: Consumer<DatabaseService>(
            builder: (context, databaseService, child) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildRequestsTab(databaseService),
                  _buildQuotesTab(databaseService),
                  _buildContractsTab(databaseService),
                ],
              );
            },
          ),
          floatingActionButton: _currentIndex == 0
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateRequestScreen(),
                      ),
                    );
                  },
                  child: Icon(Icons.add),
                  tooltip: '新しい依頼を作成',
                )
              : null,
        );
      },
    );
  }

  Widget _buildRequestsTab(DatabaseService databaseService) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final userId = userProvider.user?.uid;
        if (userId == null) {
          return Center(child: Text('ユーザー情報を読み込み中...'));
        }

        return StreamBuilder<List<RequestModel>>(
          stream: databaseService.getRequestsByClient(userId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('エラーが発生しました'),
                    SizedBox(height: 8),
                    Text('${snapshot.error}'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {}); // 再読み込み
                      },
                      child: Text('再試行'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('まだ依頼がありません'),
                    SizedBox(height: 8),
                    Text('新しい依頼を作成してみましょう'),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: ProfileAvatar(
                      imageUrl: userProvider.user?.profileImageUrl,
                      radius: 24,
                    ),
                    title: Text(request.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'カテゴリ: ${request.category.displayName}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '予算: ¥${(request.budget ?? 0).toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(request.status.displayName),
                      backgroundColor: _getStatusColor(request.status.displayName),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestDetailScreen(request: request),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildQuotesTab(DatabaseService databaseService) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final userId = userProvider.user?.uid;
        if (userId == null) {
          return Center(child: Text('ユーザー情報を読み込み中...'));
        }

        return StreamBuilder<List<QuoteModel>>(
          stream: databaseService.getQuotesForClient(userId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('エラーが発生しました'),
                    SizedBox(height: 8),
                    Text('${snapshot.error}'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {}); // 再読み込み
                      },
                      child: Text('再試行'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final quotes = snapshot.data ?? [];
            if (quotes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('まだ見積もりがありません'),
                    SizedBox(height: 8),
                    Text('依頼を作成すると見積もりが届きます'),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: quotes.length,
              itemBuilder: (context, index) {
                final quote = quotes[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: FutureBuilder<UserModel?>(
                    future: databaseService.getUser(quote.professionalId),
                    builder: (context, userSnapshot) {
                      final professional = userSnapshot.data;
                      
                      return ListTile(
                        leading: ProfileAvatar(
                          imageUrl: professional?.profileImageUrl,
                          radius: 24,
                        ),
                        title: Text(quote.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (professional != null)
                              Text(
                                '専門家: ${professional.displayName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[700],
                                ),
                              ),
                            SizedBox(height: 4),
                            Text('価格: ¥${quote.price.toStringAsFixed(0)}'),
                            Text('期間: ${quote.estimatedDays}日'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(quote.status.displayName),
                          backgroundColor: _getStatusColor(quote.status.displayName),
                        ),
                        onTap: () async {
                          // QuoteDetailScreenには依頼情報も必要
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
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildContractsTab(DatabaseService databaseService) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final userId = userProvider.user?.uid;
        if (userId == null) {
          return Center(child: Text('ユーザー情報を読み込み中...'));
        }

        return StreamBuilder<List<ContractModel>>(
          stream: databaseService.getContractsByUser(userId, UserType.client),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('エラーが発生しました'),
                    SizedBox(height: 8),
                    Text('${snapshot.error}'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {}); // 再読み込み
                      },
                      child: Text('再試行'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final contracts = snapshot.data ?? [];
            if (contracts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('まだ契約がありません'),
                    SizedBox(height: 8),
                    Text('見積もりを承認すると契約が作成されます'),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: contracts.length,
              itemBuilder: (context, index) {
                final contract = contracts[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: FutureBuilder<UserModel?>(
                    future: databaseService.getUser(contract.professionalId),
                    builder: (context, userSnapshot) {
                      final professional = userSnapshot.data;
                      
                      return ListTile(
                        leading: ProfileAvatar(
                          imageUrl: professional?.profileImageUrl,
                          radius: 24,
                        ),
                        title: Text(contract.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (professional != null)
                              Text(
                                '専門家: ${professional.displayName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[700],
                                ),
                              ),
                            SizedBox(height: 4),
                            Text('価格: ¥${contract.price.toStringAsFixed(0)}'),
                            Text('期間: ${contract.estimatedDays}日'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(_getContractStatusText(contract.status)),
                          backgroundColor: _getContractStatusColor(contract.status),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContractScreen(contract: contract),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade100;
      case 'accepted':
        return Colors.green.shade100;
      case 'rejected':
        return Colors.red.shade100;
      case 'completed':
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  String _getContractStatusText(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
        return '進行中';
      case ContractStatus.completed:
        return '完了';
      case ContractStatus.cancelled:
        return 'キャンセル';
      default:
        return '不明';
    }
  }

  Color _getContractStatusColor(ContractStatus status) {
    switch (status) {
      case ContractStatus.active:
        return Colors.orange;
      case ContractStatus.completed:
        return Colors.green;
      case ContractStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.reform:
        return Icons.home_repair_service;
      case ServiceCategory.it:
        return Icons.computer;
      case ServiceCategory.photo:
        return Icons.camera_alt;
      case ServiceCategory.design:
        return Icons.design_services;
      case ServiceCategory.education:
        return Icons.school;
      case ServiceCategory.other:
        return Icons.category;
      default:
        return Icons.work;
    }
  }
} 