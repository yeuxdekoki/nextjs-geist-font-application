import 'package:flutter/material.dart';

/// Enhanced data model for cosmetic products with additional features
/// Supports image storage, categories, brands, and user notes
class CosmeticProduct {
  final int? id;
  final String name;
  final String? brand;
  final String? category;
  final DateTime openDate;
  final int paoDays; // Period After Opening in days
  final String? imagePath;
  final String? notes;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CosmeticProduct({
    this.id,
    required this.name,
    this.brand,
    this.category,
    required this.openDate,
    required this.paoDays,
    this.imagePath,
    this.notes,
    this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Calculate expiration date by adding PAO days to open date
  DateTime get expirationDate => openDate.add(Duration(days: paoDays));

  /// Calculate remaining days until expiration
  /// Returns negative value if already expired
  int daysUntilExpiration() {
    final now = DateTime.now();
    return expirationDate.difference(now).inDays;
  }

  /// Check if product is expired
  bool get isExpired => daysUntilExpiration() < 0;

  /// Check if product is expiring soon (within 14 days)
  bool get isExpiringSoon => daysUntilExpiration() <= 14 && !isExpired;

  /// Get expiration status for UI display
  ExpirationStatus get expirationStatus {
    final days = daysUntilExpiration();
    if (days < 0) return ExpirationStatus.expired;
    if (days <= 3) return ExpirationStatus.critical;
    if (days <= 7) return ExpirationStatus.warning;
    if (days <= 14) return ExpirationStatus.reminder;
    return ExpirationStatus.good;
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'openDate': openDate.toIso8601String(),
      'paoDays': paoDays,
      'imagePath': imagePath,
      'notes': notes,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from Map (database retrieval)
  factory CosmeticProduct.fromMap(Map<String, dynamic> map) {
    return CosmeticProduct(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      brand: map['brand'],
      category: map['category'],
      openDate: DateTime.parse(map['openDate']),
      paoDays: map['paoDays']?.toInt() ?? 0,
      imagePath: map['imagePath'],
      notes: map['notes'],
      userId: map['userId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  /// Create copy with updated fields
  CosmeticProduct copyWith({
    int? id,
    String? name,
    String? brand,
    String? category,
    DateTime? openDate,
    int? paoDays,
    String? imagePath,
    String? notes,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CosmeticProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      openDate: openDate ?? this.openDate,
      paoDays: paoDays ?? this.paoDays,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CosmeticProduct{id: $id, name: $name, brand: $brand, expirationDate: $expirationDate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CosmeticProduct && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Enumeration for product expiration status
enum ExpirationStatus {
  good,      // More than 14 days
  reminder,  // 8-14 days
  warning,   // 4-7 days
  critical,  // 1-3 days
  expired,   // Past expiration
}

/// Extension for ExpirationStatus UI helpers
extension ExpirationStatusExtension on ExpirationStatus {
  /// Get color for status indicator
  Color get color {
    switch (this) {
      case ExpirationStatus.good:
        return Colors.green;
      case ExpirationStatus.reminder:
        return Colors.blue;
      case ExpirationStatus.warning:
        return Colors.orange;
      case ExpirationStatus.critical:
        return Colors.red;
      case ExpirationStatus.expired:
        return Colors.grey;
    }
  }

  /// Get display text for status
  String get displayText {
    switch (this) {
      case ExpirationStatus.good:
        return 'Good';
      case ExpirationStatus.reminder:
        return 'Reminder';
      case ExpirationStatus.warning:
        return 'Warning';
      case ExpirationStatus.critical:
        return 'Critical';
      case ExpirationStatus.expired:
        return 'Expired';
    }
  }

  /// Get icon for status
  IconData get icon {
    switch (this) {
      case ExpirationStatus.good:
        return Icons.check_circle;
      case ExpirationStatus.reminder:
        return Icons.info;
      case ExpirationStatus.warning:
        return Icons.warning;
      case ExpirationStatus.critical:
        return Icons.error;
      case ExpirationStatus.expired:
        return Icons.cancel;
    }
  }
}

/// Predefined cosmetic categories
class CosmeticCategories {
  static const List<String> categories = [
    'Cleanser',
    'Toner',
    'Serum',
    'Moisturizer',
    'Sunscreen',
    'Foundation',
    'Concealer',
    'Powder',
    'Blush',
    'Eyeshadow',
    'Mascara',
    'Lipstick',
    'Lip Balm',
    'Eye Cream',
    'Face Mask',
    'Exfoliant',
    'Oil',
    'Primer',
    'Setting Spray',
    'Other',
  ];
}
