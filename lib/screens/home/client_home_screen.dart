import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_avatar.dart';
import '../request/create_request_screen.dart';
import '../request/request_detail_screen.dart';
import '../profile/profile_edit_screen.dart';
import '../auth/login_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  @override
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
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
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // デバッグ情報表示
                ProfileImageDebugInfo(imageUrl: user.profileImageUrl),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'こんにちは、${user.displayName}さん',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'あなたの依頼',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Consumer<DatabaseService>(
                        builder: (context, databaseService, child) {
                          return StreamBuilder<List<RequestModel>>(
                            stream: databaseService.getRequestsByClient(user.uid),
                            builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
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
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final request = snapshot.data![index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ProfileAvatar(
                                        imageUrl: user.profileImageUrl,
                                        radius: 20,
                                      ),
                                      const SizedBox(width: 8),
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
                                    ],
                                  ),
                                  title: Text(
                                    request.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '予算: ¥${(request.budget ?? 0).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateRequestScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
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
} 