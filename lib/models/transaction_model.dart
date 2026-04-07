import 'package:flutter/material.dart';

/// Core transaction entity — represents any financial movement.
/// Supports both income and expense types with full categorization.
class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final String categoryIcon;
  final String categoryColor;
  final DateTime date;
  final String? note;
  final TransactionType type;

  const TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.categoryIcon,
    required this.categoryColor,
    required this.date,
    this.note,
    required this.type,
  });

  /// Parse from SQLite map row
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      categoryIcon: map['category_icon'] as String? ?? 'attach_money',
      categoryColor: map['category_color'] as String? ?? '#1A56DB',
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      type: _typeFromString(map['type'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'category_icon': categoryIcon,
      'category_color': categoryColor,
      'date': date.toIso8601String(),
      'note': note,
      'type': type == TransactionType.income ? 'income' : 'expense',
    };
  }

  static TransactionType _typeFromString(String v) {
    switch (v) {
      case 'income':
        return TransactionType.income;
      default:
        return TransactionType.expense;
    }
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    String? categoryIcon,
    String? categoryColor,
    DateTime? date,
    String? note,
    TransactionType? type,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      date: date ?? this.date,
      note: note ?? this.note,
      type: type ?? this.type,
    );
  }
}

enum TransactionType { income, expense }

/// Category model for icon + color metadata
class CategoryModel {
  final int? id;
  final String name;
  final IconData icon;
  final Color color;
  final String iconName;
  final String colorHex;

  const CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.iconName,
    required this.colorHex,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: _iconFromString(map['icon'] as String),
      color: _colorFromHex(map['color'] as String),
      iconName: map['icon'] as String,
      colorHex: map['color'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'icon': iconName,
      'color': colorHex,
    };
  }

  static IconData _iconFromString(String name) {
    const iconMap = {
      'restaurant': Icons.restaurant_rounded,
      'directions_car': Icons.directions_car_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'receipt': Icons.receipt_rounded,
      'favorite': Icons.favorite_rounded,
      'school': Icons.school_rounded,
      'movie': Icons.movie_rounded,
      'more_horiz': Icons.more_horiz_rounded,
      'attach_money': Icons.attach_money_rounded,
      'home': Icons.home_rounded,
    };
    return iconMap[name] ?? Icons.category_rounded;
  }

  static Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Budget model for monthly spending limit tracking
class BudgetModel {
  final int? id;
  final double monthlyLimit;
  final int month;
  final int year;

  const BudgetModel({
    this.id,
    required this.monthlyLimit,
    required this.month,
    required this.year,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      monthlyLimit: (map['monthly_limit'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'monthly_limit': monthlyLimit,
      'month': month,
      'year': year,
    };
  }
}
