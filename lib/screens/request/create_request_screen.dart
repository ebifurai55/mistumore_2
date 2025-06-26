import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/profile_avatar.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _requirementsController = TextEditingController();

  ServiceCategory _selectedCategory = ServiceCategory.other;
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 7));
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('依頼を作成'),
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
                                  '依頼を作成中',
                                  style: Theme.of(context).textTheme.bodySmall,
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

              // タイトル
              Text(
                '依頼タイトル',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '例：Webサイトのリニューアル',
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

              // カテゴリ選択
              Text(
                'カテゴリ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonFormField<ServiceCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ServiceCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 詳細説明
              Text(
                '詳細説明',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'プロジェクトの詳細、要望、注意点などを記入してください',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return '詳細説明を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 予算
              Text(
                '予算（円）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '例：100000',
                  border: OutlineInputBorder(),
                  prefixText: '¥ ',
                ),
              ),
              const SizedBox(height: 16),

              // 希望完了日
              Text(
                '希望完了日',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListTile(
                  title: Text(
                    '${_selectedDeadline.year}/${_selectedDeadline.month}/${_selectedDeadline.day}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDeadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        _selectedDeadline = selectedDate;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 場所
              Text(
                '場所・住所',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: '例：東京都渋谷区（対面作業が必要な場合）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 要件
              Text(
                '特別な要件',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _requirementsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '例：レスポンシブデザイン必須、SEO対策含む',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 画像添付
              Text(
                '参考画像',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_selectedImages.isEmpty)
                        InkWell(
                          onTap: _pickImages,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('画像を追加', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == _selectedImages.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: InkWell(
                                        onTap: _pickImages,
                                        child: Container(
                                          width: 100,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.add, color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: FileImage(_selectedImages[index] as dynamic),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _removeImage(index),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_selectedImages.length}枚の画像が選択されています',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 作成ボタン
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRequest,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('依頼を作成', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 画像をアップロード
      List<String> imageUrls = [];
      for (final image in _selectedImages) {
        final url = await _storageService.uploadImage(image, 'requests');
        imageUrls.add(url);
      }

      // 要件をリストに変換
      List<String> requirements = [];
      if (_requirementsController.text.isNotEmpty) {
        requirements = _requirementsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      // リクエストを作成
      final request = RequestModel(
        id: '',
        clientId: currentUser.uid,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        budget: double.tryParse(_budgetController.text),
        location: _locationController.text.isEmpty ? null : _locationController.text,
        deadline: _selectedDeadline,
        imageUrls: imageUrls,
        requirements: requirements,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.createRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('依頼を作成しました')),
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