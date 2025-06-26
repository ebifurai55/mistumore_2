import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/profile_avatar.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isImageUploading = false;
  UserModel? _currentUser;
  List<String> _selectedSkills = [];

  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  // 利用可能なスキル一覧
  final List<String> _availableSkills = [
    'Webデザイン', 'アプリ開発', 'システム開発', 'データベース',
    'UI/UX', 'グラフィックデザイン', 'ロゴデザイン', 'イラスト',
    '写真撮影', '動画編集', '動画制作', 'アニメーション',
    'リフォーム', '内装工事', '外装工事', '電気工事',
    '英語', '中国語', '韓国語', 'プログラミング指導',
    'マーケティング', 'SEO', 'SNS運用', 'コンテンツ制作',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _currentUser = userProvider.currentUser;
    if (_currentUser != null) {
      _displayNameController.text = _currentUser!.displayName;
      _bioController.text = _currentUser!.bio ?? '';
      _phoneController.text = _currentUser!.phoneNumber ?? '';
      _selectedSkills = List.from(_currentUser!.skills);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // プロフィール画像
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        EditableProfileAvatar(
                          user: _currentUser,
                          radius: 60,
                          isLoading: _isImageUploading,
                        ),
                        if (!_isImageUploading)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'プロフィール画像をタップして変更',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 基本情報
              Text(
                '基本情報',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // 表示名
              Text(
                '表示名',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  hintText: '例：田中太郎',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return '表示名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 自己紹介
              Text(
                '自己紹介',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '経歴、得意分野、実績などを記載してください',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 電話番号
              Text(
                '電話番号',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '例：090-1234-5678',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // スキル・専門分野（専門家のみ）
              if (_currentUser?.userType == UserType.professional) ...[
                Text(
                  'スキル・専門分野',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '選択済みスキル (${_selectedSkills.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_selectedSkills.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedSkills.map((skill) {
                            return Chip(
                              label: Text(skill),
                              onDeleted: () {
                                setState(() {
                                  _selectedSkills.remove(skill);
                                });
                              },
                              deleteIcon: const Icon(Icons.close, size: 16),
                            );
                          }).toList(),
                        )
                      else
                        const Text(
                          'スキルが選択されていません',
                          style: TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        '利用可能なスキル',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSkills
                            .where((skill) => !_selectedSkills.contains(skill))
                            .map((skill) {
                          return ActionChip(
                            label: Text(skill),
                            onPressed: () {
                              setState(() {
                                _selectedSkills.add(skill);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // アカウント情報
              Text(
                'アカウント情報',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('メールアドレス', _currentUser?.email ?? ''),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'ユーザータイプ',
                      _currentUser?.userType == UserType.client ? '依頼者' : '専門家',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      '登録日',
                      _currentUser != null
                          ? '${_currentUser!.createdAt.year}/${_currentUser!.createdAt.month}/${_currentUser!.createdAt.day}'
                          : '',
                    ),
                    if (_currentUser?.userType == UserType.professional && _currentUser!.rating > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            '評価: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text('${_currentUser!.rating.toStringAsFixed(1)} (${_currentUser!.reviewCount}件)'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 保存ボタン
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('プロフィールを保存', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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
    );
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _isImageUploading = true;
      });

      try {
        final imageUrl = await _storageService.uploadImage(image, 'profiles');
        
        // ユーザー情報を更新
        if (_currentUser != null) {
          final updatedUser = _currentUser!.copyWith(
            profileImageUrl: imageUrl,
            updatedAt: DateTime.now(),
          );
          
          await _databaseService.updateUser(updatedUser);
          
          // UserProviderも更新
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.updateUser(updatedUser);
          
          setState(() {
            _currentUser = updatedUser;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('プロフィール画像を更新しました')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('画像のアップロードに失敗しました: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isImageUploading = false;
          });
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = _currentUser!.copyWith(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        skills: _selectedSkills,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateUser(updatedUser);

      // UserProviderも更新
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.updateUser(updatedUser);

      setState(() {
        _currentUser = updatedUser;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを保存しました')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
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