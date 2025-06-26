import 'package:flutter/material.dart';
import 'user_model.dart';

class RequestModel {
  final String id;
  final String clientId;
  final String title;
  final String description;
  final ServiceCategory category;
  final double? budget;
  final String? location;
  final DateTime deadline;
  final RequestStatus status;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? selectedQuoteId;
  final List<String> requirements;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  RequestModel({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.category,
    this.budget,
    this.location,
    required this.deadline,
    this.status = RequestStatus.open,
    this.imageUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.selectedQuoteId,
    this.requirements = const [],
    this.cancelledAt,
    this.cancellationReason,
  });

  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: ServiceCategory.values.firstWhere(
        (e) => e.toString() == 'ServiceCategory.${map['category']}',
        orElse: () => ServiceCategory.other,
      ),
      budget: map['budget']?.toDouble(),
      location: map['location'],
      deadline: DateTime.parse(map['deadline']),
      status: RequestStatus.values.firstWhere(
        (e) => e.toString() == 'RequestStatus.${map['status']}',
        orElse: () => RequestStatus.open,
      ),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      selectedQuoteId: map['selectedQuoteId'],
      requirements: List<String>.from(map['requirements'] ?? []),
      cancelledAt: map['cancelledAt'] != null ? DateTime.parse(map['cancelledAt']) : null,
      cancellationReason: map['cancellationReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'budget': budget,
      'location': location,
      'deadline': deadline.toIso8601String(),
      'status': status.toString().split('.').last,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'selectedQuoteId': selectedQuoteId,
      'requirements': requirements,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
    };
  }

  RequestModel copyWith({
    String? id,
    String? clientId,
    String? title,
    String? description,
    ServiceCategory? category,
    double? budget,
    String? location,
    DateTime? deadline,
    RequestStatus? status,
    List<String>? imageUrls,
    DateTime? updatedAt,
    String? selectedQuoteId,
    List<String>? requirements,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return RequestModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      budget: budget ?? this.budget,
      location: location ?? this.location,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      selectedQuoteId: selectedQuoteId ?? this.selectedQuoteId,
      requirements: requirements ?? this.requirements,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

enum RequestStatus {
  open,     // 募集中
  quoted,   // 見積もり受信
  accepted, // 決定済み
  completed,// 完了
  cancelled,// キャンセル
}

extension RequestStatusExtension on RequestStatus {
  String get displayName {
    switch (this) {
      case RequestStatus.open:
        return '募集中';
      case RequestStatus.quoted:
        return '見積もり受信';
      case RequestStatus.accepted:
        return '決定済み';
      case RequestStatus.completed:
        return '完了';
      case RequestStatus.cancelled:
        return 'キャンセル';
    }
  }

  Color get color {
    switch (this) {
      case RequestStatus.open:
        return Colors.blue;
      case RequestStatus.quoted:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.green;
      case RequestStatus.completed:
        return Colors.grey;
      case RequestStatus.cancelled:
        return Colors.red;
    }
  }
} 