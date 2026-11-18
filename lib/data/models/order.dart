/// Model representing a customer order (Social Media Boosting or Examination E-Pins).
class Order {
  final String id;
  final String productName;
  final String category;
  final DateTime date;
  final double amount;
  final OrderPaymentStatus paymentStatus;
  final OrderFulfilmentStatus fulfilmentStatus;
  final String? details;
  final int quantity;
  final String recipientEmail;
  final String? targetUrl;
  final List<String>? pins;

  // Bigisub provider tracking & live receipt fields
  final String? bigisubTranId;
  final String? bigisubReference;
  final String? platform;
  final double? unitPrice;
  final int? startCount;
  final int? remains;
  final int? deliveredCount;
  final int? deliveryPercentage;
  final String? statusNote;
  final bool canCancel;
  final bool canRefill;
  final bool canRefresh;

  const Order({
    required this.id,
    required this.productName,
    required this.category,
    required this.date,
    required this.amount,
    required this.paymentStatus,
    required this.fulfilmentStatus,
    this.details,
    this.quantity = 1,
    this.recipientEmail = 'customer@resolva.ng',
    this.targetUrl,
    this.pins,
    this.bigisubTranId,
    this.bigisubReference,
    this.platform,
    this.unitPrice,
    this.startCount,
    this.remains,
    this.deliveredCount,
    this.deliveryPercentage,
    this.statusNote,
    this.canCancel = false,
    this.canRefill = false,
    this.canRefresh = true,
  });

  DateTime get createdAt => date;

  Order copyWith({
    String? id,
    String? productName,
    String? category,
    DateTime? date,
    double? amount,
    OrderPaymentStatus? paymentStatus,
    OrderFulfilmentStatus? fulfilmentStatus,
    String? details,
    int? quantity,
    String? recipientEmail,
    String? targetUrl,
    List<String>? pins,
    String? bigisubTranId,
    String? bigisubReference,
    String? platform,
    double? unitPrice,
    int? startCount,
    int? remains,
    int? deliveredCount,
    int? deliveryPercentage,
    String? statusNote,
    bool? canCancel,
    bool? canRefill,
    bool? canRefresh,
  }) {
    return Order(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      fulfilmentStatus: fulfilmentStatus ?? this.fulfilmentStatus,
      details: details ?? this.details,
      quantity: quantity ?? this.quantity,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      targetUrl: targetUrl ?? this.targetUrl,
      pins: pins ?? this.pins,
      bigisubTranId: bigisubTranId ?? this.bigisubTranId,
      bigisubReference: bigisubReference ?? this.bigisubReference,
      platform: platform ?? this.platform,
      unitPrice: unitPrice ?? this.unitPrice,
      startCount: startCount ?? this.startCount,
      remains: remains ?? this.remains,
      deliveredCount: deliveredCount ?? this.deliveredCount,
      deliveryPercentage: deliveryPercentage ?? this.deliveryPercentage,
      statusNote: statusNote ?? this.statusNote,
      canCancel: canCancel ?? this.canCancel,
      canRefill: canRefill ?? this.canRefill,
      canRefresh: canRefresh ?? this.canRefresh,
    );
  }
}

enum OrderPaymentStatus { paid, pending, failed }

enum OrderFulfilmentStatus { pending, processing, completed, cancelled }

/// Model representing a financial transaction record.
class Transaction {
  final String reference;
  final String description;
  final DateTime date;
  final double amount;
  final String paymentMethod;
  final TransactionStatus status;

  const Transaction({
    required this.reference,
    required this.description,
    required this.date,
    required this.amount,
    required this.paymentMethod,
    required this.status,
  });
}

enum TransactionStatus { successful, pending, failed }

/// Model representing an in-app notification.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
  });
}

enum NotificationType {
  orderConfirmed,
  orderProcessing,
  orderCompleted,
  payment,
  support,
}

/// Model for FAQ items.
class FaqItem {
  final String question;
  final String answer;
  final String category;

  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}
