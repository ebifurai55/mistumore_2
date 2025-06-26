import 'package:flutter/material.dart';

class QuoteModel {
  final String id;
  final String requestId;
  final String professionalId;
  final String title;
  final String description;
  final double price;
  final int estimatedDays;
  final QuoteStatus status;
  final List<String> deliverables;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  QuoteModel({
    required this.id,
    required this.requestId,
    required this.professionalId,
    required this.title,
    required this.description,
    required this.price,
    required this.estimatedDays,
    this.status = QuoteStatus.pending,
    this.deliverables = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory QuoteModel.fromMap(Map<String, dynamic> map) {
    return QuoteModel(
      id: map['id'] ?? '',
      requestId: map['requestId'] ?? '',
      professionalId: map['professionalId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      estimatedDays: map['estimatedDays'] ?? 0,
      status: QuoteStatus.values.firstWhere(
        (e) => e.toString() == 'QuoteStatus.${map['status']}',
        orElse: () => QuoteStatus.pending,
      ),
      deliverables: List<String>.from(map['deliverables'] ?? []),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      acceptedAt: map['acceptedAt'] != null ? DateTime.parse(map['acceptedAt']) : null,
      rejectedAt: map['rejectedAt'] != null ? DateTime.parse(map['rejectedAt']) : null,
      rejectionReason: map['rejectionReason'],
      cancelledAt: map['cancelledAt'] != null ? DateTime.parse(map['cancelledAt']) : null,
      cancellationReason: map['cancellationReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'professionalId': professionalId,
      'title': title,
      'description': description,
      'price': price,
      'estimatedDays': estimatedDays,
      'status': status.toString().split('.').last,
      'deliverables': deliverables,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
    };
  }

  QuoteModel copyWith({
    String? id,
    String? requestId,
    String? professionalId,
    String? title,
    String? description,
    double? price,
    int? estimatedDays,
    QuoteStatus? status,
    List<String>? deliverables,
    String? notes,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return QuoteModel(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      professionalId: professionalId ?? this.professionalId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      status: status ?? this.status,
      deliverables: deliverables ?? this.deliverables,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

enum QuoteStatus {
  pending,   // 提出済み
  accepted,  // 承認済み
  rejected,  // 却下
  completed, // 完了
  cancelled, // キャンセル
}

extension QuoteStatusExtension on QuoteStatus {
  String get displayName {
    switch (this) {
      case QuoteStatus.pending:
        return '提出済み';
      case QuoteStatus.accepted:
        return '承認済み';
      case QuoteStatus.rejected:
        return '却下';
      case QuoteStatus.completed:
        return '完了';
      case QuoteStatus.cancelled:
        return 'キャンセル';
    }
  }

  Color get color {
    switch (this) {
      case QuoteStatus.pending:
        return Colors.orange;
      case QuoteStatus.accepted:
        return Colors.green;
      case QuoteStatus.rejected:
        return Colors.red;
      case QuoteStatus.completed:
        return Colors.blue;
      case QuoteStatus.cancelled:
        return Colors.grey;
    }
  }
}

// 簡単な返信テンプレート
class QuickReplyTemplate {
  static const List<String> clientReplies = [
    '詳しい見積もりをお願いします',
    'いつから開始可能ですか？',
    '料金についてご相談があります',
    '他の案もご提案いただけますか？',
    '承認いたします',
    '検討させていただきます',
  ];

  static const List<String> professionalReplies = [
    '詳細をお聞かせください',
    '対応可能です',
    '別のプランをご提案します',
    '追加料金が発生する可能性があります',
    'ありがとうございます',
    '修正いたします',
  ];
} 