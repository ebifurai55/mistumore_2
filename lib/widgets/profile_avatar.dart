import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';

class ProfileAvatar extends StatelessWidget {
  final UserModel? user;
  final String? imageUrl;
  final String? displayName;
  final double radius;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.user,
    this.imageUrl,
    this.displayName,
    this.radius = 20,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveImageUrl = imageUrl ?? user?.profileImageUrl;
    final effectiveName = displayName ?? user?.displayName ?? '';
    final effectiveBorderColor = borderColor ?? Theme.of(context).primaryColor;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surface,
      backgroundImage: effectiveImageUrl != null && effectiveImageUrl.isNotEmpty
          ? CachedNetworkImageProvider(effectiveImageUrl)
          : null,
      child: effectiveImageUrl == null || effectiveImageUrl.isEmpty
          ? Text(
              _getInitials(effectiveName),
              style: TextStyle(
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
          : null,
    );

    if (showBorder) {
      avatar = Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: effectiveBorderColor,
        ),
        child: avatar,
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
    }
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
                user: user,
                radius: radius,
                showBorder: true,
                borderColor: Theme.of(context).colorScheme.background,
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
                    color: Theme.of(context).colorScheme.background,
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
          user: user,
          radius: radius,
          showBorder: true,
        ),
        if (isLoading)
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.5),
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
                    color: Theme.of(context).colorScheme.background,
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
          user: user,
          radius: radius,
          showBorder: true,
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