import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ProfileAvatar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
            ? NetworkImage(imageUrl!)
            : null,
        child: imageUrl == null || imageUrl!.isEmpty
            ? Icon(
                Icons.person,
                size: radius,
                color: Colors.grey[600],
              )
            : null,
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
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
} 