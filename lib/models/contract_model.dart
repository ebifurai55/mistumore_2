import 'package:flutter/material.dart';

class ContractMessage {
  final String id;
  final String contractId;
  final String senderId;
  final String senderName;
  final String? senderProfileImageUrl;
  final String message;
  final DateTime createdAt;
  final ContractMessageType type;

  ContractMessage({
    required this.id,
    required this.contractId,
    required this.senderId,
    required this.senderName,
    this.senderProfileImageUrl,
    required this.message,
    required this.createdAt,
    required this.type,
  });

  factory ContractMessage.fromMap(Map<String, dynamic> map) {
    return ContractMessage(
      id: map['id']?.toString() ?? '',
      contractId: map['contractId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? 'Unknown User',
      senderProfileImageUrl: map['senderProfileImageUrl']?.toString(),
      message: map['message']?.toString() ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      type: _parseMessageType(map['type']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return DateTime.fromMillisecondsSinceEpoch(parsed);
    }
    return DateTime.now();
  }

  static ContractMessageType _parseMessageType(dynamic value) {
    if (value == null) return ContractMessageType.text;
    final typeString = value.toString();
    return ContractMessageType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => ContractMessageType.text,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractId': contractId,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileImageUrl': senderProfileImageUrl,
      'message': message,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'type': type.toString().split('.').last,
    };
  }
}

enum ContractMessageType {
  text,        // テキストメッセージ
  image,       // 画像
  file,        // ファイル
  system       // システムメッセージ
}

enum ContractStatus {
  active,      // 契約実行中
  completed,   // 完了
  cancelled,   // キャンセル
  disputed     // 紛争中
}

class ContractModel {
  final String id;
  final String requestId;
  final String quoteId;
  final String clientId;
  final String professionalId;
  final String title;
  final String description;
  final double price;
  final int estimatedDays;
  final DateTime startDate;
  final DateTime expectedEndDate;
  final DateTime? actualEndDate;
  final ContractStatus status;
  final List<String> deliverables;
  final List<ContractMilestone> milestones;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? clientRating;
  final String? clientReview;
  final double? professionalRating;
  final String? professionalReview;

  ContractModel({
    required this.id,
    required this.requestId,
    required this.quoteId,
    required this.clientId,
    required this.professionalId,
    required this.title,
    required this.description,
    required this.price,
    required this.estimatedDays,
    required this.startDate,
    required this.expectedEndDate,
    this.actualEndDate,
    this.status = ContractStatus.active,
    this.deliverables = const [],
    this.milestones = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.clientRating,
    this.clientReview,
    this.professionalRating,
    this.professionalReview,
  });

  factory ContractModel.fromMap(Map<String, dynamic> map) {
    return ContractModel(
      id: map['id'] ?? '',
      requestId: map['requestId'] ?? '',
      quoteId: map['quoteId'] ?? '',
      clientId: map['clientId'] ?? '',
      professionalId: map['professionalId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      estimatedDays: map['estimatedDays'] ?? 0,
      startDate: DateTime.parse(map['startDate']),
      expectedEndDate: DateTime.parse(map['expectedEndDate']),
      actualEndDate: map['actualEndDate'] != null 
          ? DateTime.parse(map['actualEndDate']) 
          : null,
      status: ContractStatus.values.firstWhere(
        (e) => e.toString() == 'ContractStatus.${map['status']}',
        orElse: () => ContractStatus.active,
      ),
      deliverables: List<String>.from(map['deliverables'] ?? []),
      milestones: (map['milestones'] as List<dynamic>?)
          ?.map((e) => ContractMilestone.fromMap(e))
          .toList() ?? [],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      clientRating: map['clientRating']?.toDouble(),
      clientReview: map['clientReview'],
      professionalRating: map['professionalRating']?.toDouble(),
      professionalReview: map['professionalReview'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'quoteId': quoteId,
      'clientId': clientId,
      'professionalId': professionalId,
      'title': title,
      'description': description,
      'price': price,
      'estimatedDays': estimatedDays,
      'startDate': startDate.toIso8601String(),
      'expectedEndDate': expectedEndDate.toIso8601String(),
      'actualEndDate': actualEndDate?.toIso8601String(),
      'status': status.toString().split('.').last,
      'deliverables': deliverables,
      'milestones': milestones.map((e) => e.toMap()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'clientRating': clientRating,
      'clientReview': clientReview,
      'professionalRating': professionalRating,
      'professionalReview': professionalReview,
    };
  }

  ContractModel copyWith({
    String? id,
    String? requestId,
    String? quoteId,
    String? clientId,
    String? professionalId,
    String? title,
    String? description,
    double? price,
    int? estimatedDays,
    DateTime? startDate,
    DateTime? expectedEndDate,
    DateTime? actualEndDate,
    ContractStatus? status,
    List<String>? deliverables,
    List<ContractMilestone>? milestones,
    String? notes,
    DateTime? updatedAt,
    double? clientRating,
    String? clientReview,
    double? professionalRating,
    String? professionalReview,
  }) {
    return ContractModel(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      quoteId: quoteId ?? this.quoteId,
      clientId: clientId ?? this.clientId,
      professionalId: professionalId ?? this.professionalId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      status: status ?? this.status,
      deliverables: deliverables ?? this.deliverables,
      milestones: milestones ?? this.milestones,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientRating: clientRating ?? this.clientRating,
      clientReview: clientReview ?? this.clientReview,
      professionalRating: professionalRating ?? this.professionalRating,
      professionalReview: professionalReview ?? this.professionalReview,
    );
  }
}

class ContractMilestone {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime? completedAt;

  ContractMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.completedAt,
  });

  factory ContractMilestone.fromMap(Map<String, dynamic> map) {
    return ContractMilestone(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

extension ContractStatusExtension on ContractStatus {
  String get displayName {
    switch (this) {
      case ContractStatus.active:
        return '進行中';
      // Note: paused status removed from enum
      case ContractStatus.completed:
        return '完了';
      case ContractStatus.cancelled:
        return 'キャンセル';
      case ContractStatus.disputed:
        return '紛争中';
    }
  }

  Color get color {
    switch (this) {
      case ContractStatus.active:
        return Colors.blue;
      // Note: paused status removed from enum
      case ContractStatus.completed:
        return Colors.green;
      case ContractStatus.cancelled:
        return Colors.red;
      case ContractStatus.disputed:
        return Colors.purple;
    }
  }
} 