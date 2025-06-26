import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../services/storage_service.dart';
import '../../screens/home/client_home_screen.dart';
import '../../screens/home/professional_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  UserType _selectedUserType = UserType.client;
  
  // プロフィール画像関連
  XFile? _selectedProfileImage;
  bool _isImageUploading = false;
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B46C1),
              Color(0xFF9333EA),
              Color(0xFFD946EF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Card(
                    elevation: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 32),
                            _buildForm(),
                            const SizedBox(height: 24),
                            _buildActionButton(),
                            const SizedBox(height: 16),
                            _buildToggleButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.handshake_outlined,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ミツモア',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B46C1),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '依頼と見積もりのマッチングサービス',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLogin) ...[
            // プロフィール画像選択
            _buildProfileImagePicker(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '表示名',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '表示名を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildUserTypeSelector(),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'メールアドレス',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'メールアドレスを入力してください';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return '有効なメールアドレスを入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'パスワード',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'パスワードを入力してください';
              }
              if (!_isLogin && value.length < 6) {
                return 'パスワードは6文字以上で入力してください';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              child: _isImageUploading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _selectedProfileImage != null
                      ? ClipOval(
                          child: FutureBuilder<Uint8List>(
                            future: _selectedProfileImage!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const Center(child: CircularProgressIndicator());
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey,
                        ),
            ),
            if (!_isImageUploading)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'プロフィール画像を選択（任意）',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'アカウントタイプ',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<UserType>(
                value: UserType.client,
                groupValue: _selectedUserType,
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value!;
                  });
                },
                title: const Text('依頼者'),
                subtitle: const Text('サービスを依頼したい'),
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<UserType>(
                value: UserType.professional,
                groupValue: _selectedUserType,
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value!;
                  });
                },
                title: const Text('専門家'),
                subtitle: const Text('サービスを提供したい'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final isLoading = userProvider.isLoading || _isImageUploading;
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B46C1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isImageUploading 
                            ? '画像をアップロード中...'
                            : (_isLogin ? 'ログイン中...' : 'アカウント作成中...'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    _isLogin ? 'ログイン' : '新規登録',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isLogin = !_isLogin;
        });
      },
      child: Text(
        _isLogin 
            ? 'アカウントをお持ちでない方はこちら' 
            : '既にアカウントをお持ちの方はこちら',
        style: TextStyle(
          color: const Color(0xFF6B46C1),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    bool success = false;

    try {
      if (_isLogin) {
        // ログイン処理にタイムアウトを設定（30秒）
        success = await userProvider.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ログインがタイムアウトしました。ネットワーク接続を確認してください。'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          },
        );
      } else {
      // サインアップ時にプロフィール画像をアップロード
      String? profileImageUrl;
      if (_selectedProfileImage != null) {
        setState(() {
          _isImageUploading = true;
        });
        try {
          profileImageUrl = await _storageService.uploadImage(
            _selectedProfileImage!,
            'profile_images',
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('プロフィール画像のアップロードに失敗しました'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } finally {
          setState(() {
            _isImageUploading = false;
          });
        }
      }

      // 登録処理にもタイムアウトを設定（30秒）
      success = await userProvider.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        userType: _selectedUserType,
        profileImageUrl: profileImageUrl,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('登録がタイムアウトしました。ネットワーク接続を確認してください。'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return false;
        },
      );
    }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      if (success) {
        // 成功時のメッセージ表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isLogin ? 'ログインしました' : 'アカウントを作成しました'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // 少し遅延してから適切なホーム画面に遷移
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          final currentUser = userProvider.currentUser;
          if (currentUser != null) {
            Widget homeScreen;
            if (currentUser.userType == UserType.client) {
              homeScreen = ClientHomeScreen();
            } else {
              homeScreen = ProfessionalHomeScreen();
            }
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => homeScreen),
            );
          }
        }
      } else if (userProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedProfileImage = pickedFile;
      });
    }
  }
} 