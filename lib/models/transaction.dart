import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String userId;
  String title;
  double amount;
  TransactionType type;
  String category;
  DateTime date;
  String? accountId;
  String? note;
  String? imageUrl;
  List<String>? tags;

  Transaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    DateTime? date,
    this.accountId,
    this.note,
    this.imageUrl,
    this.tags,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'type': type.index,
      'category': category,
      'date': date.toIso8601String(),
      'accountId': accountId,
      'note': note,
      'imageUrl': imageUrl,
      'tags': tags,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      amount: map['amount'].toDouble(),
      type: TransactionType.values[map['type']],
      category: map['category'],
      date: DateTime.parse(map['date']),
      accountId: map['accountId'],
      note: map['note'],
      imageUrl: map['imageUrl'],
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
    );
  }
}

enum TransactionType {
  income,
  expense,
  transfer
}

extension TransactionTypeExtension on TransactionType {
  String getDisplayName(bool isBangla) {
    switch (this) {
      case TransactionType.income:
        return isBangla ? 'আয়' : 'Income';
      case TransactionType.expense:
        return isBangla ? 'ব্যয়' : 'Expense';
      case TransactionType.transfer:
        return isBangla ? 'ট্রান্সফার' : 'Transfer';
    }
  }

  Color getColor() {
    switch (this) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
    }
  }

  IconData getIcon() {
    switch (this) {
      case TransactionType.income:
        return Icons.trending_up;
      case TransactionType.expense:
        return Icons.trending_down;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }
}