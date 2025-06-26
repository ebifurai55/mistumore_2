import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';

/// プロフィール画像のプロキシ設定
class ProfileImageProxy {
  static const List<String> _proxyServices = [
    'https://api.allorigins.win/raw?url=',
    'https://cors-anywhere.herokuapp.com/',
    'https://thingproxy.freeboard.io/fetch/',
  ];

  static bool _useProxy = false; // デバッグのため一時的に無効化
  static int _currentProxyIndex = 0;

  static bool get useProxy => _useProxy;
  static set useProxy(bool value) => _useProxy = value;

  static String? getProxiedUrl(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty || !_useProxy) {
      return originalUrl;
    }

    // Firebase Storage URLの場合、そのまま使用
    if (originalUrl.contains('firebasestorage.googleapis.com')) {
      return originalUrl;
    }

    // HTTPSでない場合もそのまま使用
    if (!originalUrl.startsWith('http')) {
      return originalUrl;
    }

    try {
      final encodedUrl = Uri.encodeComponent(originalUrl);
      return '${_proxyServices[_currentProxyIndex]}$encodedUrl';
    } catch (e) {
      return originalUrl;
    }
  }

  static void switchToNextProxy() {
    _currentProxyIndex = (_currentProxyIndex + 1) % _proxyServices.length;
  }
}

class ProfileAvatar extends StatefulWidget {
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;

  const ProfileAvatar({
    Key? key,
    this.imageUrl,
    this.radius = 20,
    this.onTap,
  }) : super(key: key);

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    // デバッグ情報を出力
    if (kDebugMode) {
      print('ProfileAvatar: imageUrl = ${widget.imageUrl}');
      print('ProfileAvatar: hasError = $_hasError');
      print('ProfileAvatar: errorMessage = $_errorMessage');
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.grey[300],
        child: widget.imageUrl != null && !_hasError
            ? ClipOval(
                child: Image.network(
                  widget.imageUrl!,
                  width: widget.radius * 2,
                  height: widget.radius * 2,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _hasError = true;
                        _errorMessage = error.toString();
                      });
                    });
                    
                    if (kDebugMode) {
                      print('ProfileAvatar Error: $error');
                      print('ProfileAvatar StackTrace: $stackTrace');
                    }
                    
                    return Icon(
                      Icons.person,
                      size: widget.radius * 1.2,
                      color: Colors.grey[600],
                    );
                  },
                ),
              )
            : Icon(
                Icons.person,
                size: widget.radius * 1.2,
                color: Colors.grey[600],
              ),
      ),
    );
  }
}

class ProfileAvatarList extends StatelessWidget {
  final List<UserModel> users;
  final double radius;
  final double spacing;
  final int maxDisplay;
  final VoidCallback? onTap;

  const ProfileAvatarList({
    super.key,
    required this.users,
    this.radius = 16,
    this.spacing = -8,
    this.maxDisplay = 3,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayUsers = users.take(maxDisplay).toList();
    final remainingCount = users.length - maxDisplay;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...displayUsers.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            
            return Transform.translate(
              offset: Offset(spacing * index, 0),
              child: ProfileAvatar(
                imageUrl: user.profileImageUrl,
                radius: radius,
              ),
            );
          }),
          if (remainingCount > 0)
            Transform.translate(
              offset: Offset(spacing * displayUsers.length, 0),
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      fontSize: radius * 0.5,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EditableProfileAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;
  final VoidCallback? onEditPressed;
  final bool isLoading;

  const EditableProfileAvatar({
    super.key,
    this.user,
    this.radius = 40,
    this.onEditPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        ProfileAvatar(
          imageUrl: user?.profileImageUrl,
          radius: radius,
        ),
        if (isLoading)
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        if (onEditPressed != null && !isLoading)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEditPressed,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  size: radius * 0.4,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ProfileAvatarWithRating extends StatelessWidget {
  final UserModel user;
  final double radius;
  final bool showRating;

  const ProfileAvatarWithRating({
    super.key,
    required this.user,
    this.radius = 20,
    this.showRating = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProfileAvatar(
          imageUrl: user.profileImageUrl,
          radius: radius,
        ),
        if (showRating && user.rating > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: 12,
                color: Colors.amber,
              ),
              const SizedBox(width: 2),
              Text(
                user.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// プロキシを使用した画像表示用のウィジェット
class ProxiedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProxiedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<ProxiedImage> createState() => _ProxiedImageState();
}

class _ProxiedImageState extends State<ProxiedImage> {
  String get proxiedUrl {
    // Firebase StorageのURLはそのまま使用
    if (widget.imageUrl.contains('firebasestorage.googleapis.com')) {
      return widget.imageUrl;
    }
    // その他のURLはプロキシを通す
    return 'https://cors-anywhere.herokuapp.com/${widget.imageUrl}';
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('ProxiedImage: original = ${widget.imageUrl}');
      print('ProxiedImage: proxied = $proxiedUrl');
    }

    return Image.network(
      proxiedUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          print('ProxiedImage Error: $error');
        }
        return Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        );
      },
    );
  }
}

// デバッグ用のプロフィール画像情報表示ウィジェット
class ProfileImageDebugInfo extends StatelessWidget {
  final String? imageUrl;

  const ProfileImageDebugInfo({
    Key? key,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.yellow[100],
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debug: Profile Image Info',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('URL: ${imageUrl ?? "null"}'),
          Text('Has URL: ${imageUrl != null && imageUrl!.isNotEmpty}'),
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Text('Is Firebase URL: ${imageUrl!.contains('firebasestorage.googleapis.com')}'),
        ],
      ),
    );
  }
} 