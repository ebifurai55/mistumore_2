class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final UserType userType;
  final String? phoneNumber;
  final String? bio;
  final List<String> skills;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    required this.userType,
    this.phoneNumber,
    this.bio,
    this.skills = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      userType: UserType.values.firstWhere(
        (e) => e.toString() == 'UserType.${map['userType']}',
        orElse: () => UserType.client,
      ),
      phoneNumber: map['phoneNumber'],
      bio: map['bio'],
      skills: List<String>.from(map['skills'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'userType': userType.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'skills': skills,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? profileImageUrl,
    UserType? userType,
    String? phoneNumber,
    String? bio,
    List<String>? skills,
    double? rating,
    int? reviewCount,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      userType: userType ?? this.userType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum UserType {
  client,
  professional,
}

enum ServiceCategory {
  reform,
  it,
  photo,
  design,
  education,
  other,
}

extension ServiceCategoryExtension on ServiceCategory {
  String get displayName {
    switch (this) {
      case ServiceCategory.reform:
        return 'リフォーム';
      case ServiceCategory.it:
        return 'IT・システム';
      case ServiceCategory.photo:
        return '写真・動画';
      case ServiceCategory.design:
        return 'デザイン';
      case ServiceCategory.education:
        return '教育・レッスン';
      case ServiceCategory.other:
        return 'その他';
    }
  }

  String get description {
    switch (this) {
      case ServiceCategory.reform:
        return '住宅・店舗の改修';
      case ServiceCategory.it:
        return 'アプリ・Web開発';
      case ServiceCategory.photo:
        return '撮影・編集';
      case ServiceCategory.design:
        return 'ロゴ・チラシ制作';
      case ServiceCategory.education:
        return '各種指導・講座';
      case ServiceCategory.other:
        return '様々なサービス';
    }
  }
} 