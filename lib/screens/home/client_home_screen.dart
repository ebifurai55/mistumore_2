import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/profile_avatar.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('依頼者ホーム'),
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return Row(
                children: [
                  ProfileAvatar(
                    user: userProvider.currentUser,
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => userProvider.signOut(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.currentUser;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          user: user,
                          radius: 30,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'ユーザー',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                user?.email ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'サービスカテゴリ',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _buildCategoryCard(context, 'リフォーム', Icons.home_repair_service, '住宅・店舗の改修'),
                  _buildCategoryCard(context, 'IT・システム', Icons.computer, 'アプリ・Web開発'),
                  _buildCategoryCard(context, '写真・動画', Icons.camera_alt, '撮影・編集'),
                  _buildCategoryCard(context, 'デザイン', Icons.palette, 'ロゴ・チラシ制作'),
                  _buildCategoryCard(context, '教育・レッスン', Icons.school, '各種指導・講座'),
                  _buildCategoryCard(context, 'その他', Icons.more_horiz, '様々なサービス'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create request screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('依頼作成画面を実装予定')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, String description) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$titleの依頼を作成')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 