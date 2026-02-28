import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/note.dart';
import '../models/market_item.dart';

class FinanceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  List<Note> _notes = [];
  List<MarketItem> _marketItems = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _accountsSub;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _notesSub;
  StreamSubscription? _marketSub;

  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<Note> get notes => _notes;
  List<Note> get pinnedNotes => _notes.where((note) => note.isPinned).toList();
  List<Note> get unpinnedNotes => _notes.where((note) => !note.isPinned).toList();
  List<MarketItem> get marketItems => _marketItems;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalBalance => _accounts.fold(0, (sum, acc) => sum + acc.balance);
  double get totalIncome => _transactions.where((t) => t.type == TransactionType.income).fold(0, (sum, t) => sum + t.amount);
  double get totalExpense => _transactions.where((t) => t.type == TransactionType.expense).fold(0, (sum, t) => sum + t.amount);
  double get totalSavings => totalIncome - totalExpense;

  Future<void> loadUserData(String userId) async {
    _setLoading(true);
    _cancelSubscriptions();

    try {
      // Real-time Listeners
      _accountsSub = _firestore.collection('users').doc(userId).collection('accounts')
          .snapshots().listen((snap) {
        _accounts = snap.docs.map((doc) => Account.fromMap(doc.data())).toList();
        notifyListeners();
      });

      _transactionsSub = _firestore.collection('users').doc(userId).collection('transactions')
          .orderBy('date', descending: true).snapshots().listen((snap) {
        _transactions = snap.docs.map((doc) => Transaction.fromMap(doc.data())).toList();
        notifyListeners();
      });

      _notesSub = _firestore.collection('users').doc(userId).collection('notes')
          .orderBy('updatedAt', descending: true).snapshots().listen((snap) {
        _notes = snap.docs.map((doc) => Note.fromMap(doc.data())).toList();
        notifyListeners();
      });

      _marketSub = _firestore.collection('users').doc(userId).collection('market_items')
          .orderBy('addedDate', descending: true).snapshots().listen((snap) {
        _marketItems = snap.docs.map((doc) => MarketItem.fromMap(doc.data())).toList();
        notifyListeners();
      });

    } catch (e) {
      _error = e.toString();
      debugPrint('Sync Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _cancelSubscriptions() {
    _accountsSub?.cancel();
    _transactionsSub?.cancel();
    _notesSub?.cancel();
    _marketSub?.cancel();
  }

  // Optimized methods for atomic updates
  Future<void> addTransaction(Transaction t) async {
    final batch = _firestore.batch();
    final tRef = _firestore.collection('users').doc(t.userId).collection('transactions').doc(t.id);
    batch.set(tRef, t.toMap());

    if (t.accountId != null) {
      final accRef = _firestore.collection('users').doc(t.userId).collection('accounts').doc(t.accountId);
      double change = t.type == TransactionType.income ? t.amount : -t.amount;
      batch.update(accRef, {'balance': FieldValue.increment(change)});
    }
    await batch.commit();
  }

  Future<void> addAccount(Account account) async {
    await _firestore.collection('users').doc(account.userId).collection('accounts').doc(account.id).set(account.toMap());
  }

  Future<void> updateAccount(Account account) async {
    await _firestore.collection('users').doc(account.userId).collection('accounts').doc(account.id).update(account.toMap());
  }

  Future<void> deleteAccount(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('accounts').doc(id).delete();
  }

  Future<void> addNote(Note note) async {
    await _firestore.collection('users').doc(note.userId).collection('notes').doc(note.id).set(note.toMap());
  }

  Future<void> updateNote(Note note) async {
    await _firestore.collection('users').doc(note.userId).collection('notes').doc(note.id).update(note.toMap());
  }

  Future<void> togglePinNote(String userId, String id) async {
    final note = _notes.firstWhere((n) => n.id == id);
    await _firestore.collection('users').doc(userId).collection('notes').doc(id).update({'isPinned': !note.isPinned});
  }

  Future<void> deleteNote(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('notes').doc(id).delete();
  }

  Future<void> addMarketItem(MarketItem item) async {
    await _firestore.collection('users').doc(item.userId).collection('market_items').doc(item.id).set(item.toMap());
  }

  Future<void> updateMarketItem(MarketItem item) async {
    await _firestore.collection('users').doc(item.userId).collection('market_items').doc(item.id).update(item.toMap());
  }

  Future<void> togglePurchased(String userId, String id) async {
    final item = _marketItems.firstWhere((m) => m.id == id);
    await _firestore.collection('users').doc(userId).collection('market_items').doc(id)
        .update({'isPurchased': !item.isPurchased, 'purchasedDate': !item.isPurchased ? DateTime.now().toIso8601String() : null});
  }

  Future<void> deleteMarketItem(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('market_items').doc(id).delete();
  }

  Map<String, double> getCategoryWiseExpense() {
    Map<String, double> data = {};
    for (var t in _transactions.where((t) => t.type == TransactionType.expense)) {
      data[t.category] = (data[t.category] ?? 0) + t.amount;
    }
    return data;
  }

  List<Map<String, dynamic>> getMonthlyData(int year) {
    List<Map<String, dynamic>> data = [];
    for (int i = 1; i <= 12; i++) {
      double inc = _transactions.where((t) => t.date.year == year && t.date.month == i && t.type == TransactionType.income).fold(0, (sum, t) => sum + t.amount);
      double exp = _transactions.where((t) => t.date.year == year && t.date.month == i && t.type == TransactionType.expense).fold(0, (sum, t) => sum + t.amount);
      data.add({'month': i, 'income': inc, 'expense': exp});
    }
    return data;
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
