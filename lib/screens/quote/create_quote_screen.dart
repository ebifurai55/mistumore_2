import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/request_model.dart';
import '../../models/quote_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../widgets/profile_avatar.dart';

class CreateQuoteScreen extends StatefulWidget {
  final RequestModel request;

  const CreateQuoteScreen({
    super.key,
    required this.request,
  });

  @override
  State<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends State<CreateQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _estimatedDaysController = TextEditingController();
  final _deliverablesController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  UserModel? _clientUser;

  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadClientUser();
    // 初期値設定
    _titleController.text = '${widget.request.title}の見積もり';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _estimatedDaysController.dispose();
    _deliverablesController.dispose();
    _notesController.dispose();
    super.dispose();
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
        title: const Text('見積もりを作成'),
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // プロフィール表示
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.currentUser;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ProfileAvatar(imageUrl: user?.profileImageUrl, radius: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.displayName ?? 'ユーザー',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  '見積もりを作成中',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (user?.rating != null && user!.rating > 0)
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${user.rating.toStringAsFixed(1)} (${user.reviewCount}件)',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
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
              const SizedBox(height: 16),

              // 依頼情報表示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ProfileAvatar(imageUrl: _clientUser?.profileImageUrl, radius: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.request.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  _clientUser?.displayName ?? '依頼者',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.request.category.displayName == 'IT・システム' 
                                  ? Colors.blue : Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.request.category.displayName,
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
                        widget.request.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.request.budget != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '予算: ¥${widget.request.budget!.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 見積もりタイトル
              Text(
                '見積もりタイトル',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '例：Webサイトリニューアルの見積もり',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 詳細説明・提案内容
              Text(
                '提案内容・詳細説明',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'どのような作業を行うか、どんな価値を提供できるかを具体的に記載してください',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return '提案内容を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 料金
              Text(
                '料金（円）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '例：150000',
                  border: OutlineInputBorder(),
                  prefixText: '¥ ',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return '料金を入力してください';
                  }
                  final price = double.tryParse(value!);
                  if (price == null || price <= 0) {
                    return '正しい金額を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 完了予定日数
              Text(
                '完了予定日数',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _estimatedDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '例：14',
                  border: OutlineInputBorder(),
                  suffixText: '日',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return '完了予定日数を入力してください';
                  }
                  final days = int.tryParse(value!);
                  if (days == null || days <= 0) {
                    return '正しい日数を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 成果物・納品物
              Text(
                '成果物・納品物',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deliverablesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '例：レスポンシブWebサイト, ソースコード, 操作マニュアル',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 備考・特記事項
              Text(
                '備考・特記事項',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '支払い条件、修正回数の制限、その他特記事項があれば記載',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // 注意事項
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
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '見積もり送信時の注意',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• 見積もりは送信後に修正できません\n• クライアントが承認するまで仕事は開始されません\n• 具体的で分かりやすい提案を心がけましょう',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 送信ボタン
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createQuote,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('見積もりを送信', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createQuote() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 成果物をリストに変換
      List<String> deliverables = [];
      if (_deliverablesController.text.isNotEmpty) {
        deliverables = _deliverablesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      // 見積もりを作成
      final quote = QuoteModel(
        id: '',
        requestId: widget.request.id,
        professionalId: currentUser.uid,
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        estimatedDays: int.parse(_estimatedDaysController.text),
        deliverables: deliverables,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.createQuote(quote);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('見積もりを送信しました')),
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