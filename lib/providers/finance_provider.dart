import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../models/note.dart';
import '../models/transaction.dart';
import '../models/market_item.dart';
import '../models/mess_member.dart';
import '../models/mess_meal.dart';
import '../models/mess_market_expense.dart';
import '../models/mess_action_log.dart';
import '../models/mess_meal_plan.dart';
import '../models/mess_info.dart';
import '../models/mess_history.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/savings_goal.dart';
import '../models/recurring_transaction.dart';
import '../models/planning_model.dart';

class FinanceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  List<Note> _notes = [];
  List<MarketItem> _marketItems = [];
  List<MessMember> _messMembers = [];
  List<MessMeal> _messMeals = [];
  List<MessMarketExpense> _messMarketExpenses = [];
  List<MessActionLog> _messLogs = [];
  List<MessMealPlan> _messMealPlans = [];
  List<MessHistory> _messHistories = [];
  MessInfo? _messInfo;
  
  List<Budget> _budgets = [];
  List<Debt> _debts = [];
  List<SavingsGoal> _savingsGoals = [];
  List<RecurringTransaction> _recurringTransactions = [];
  List<Planning> _plannings = [];
  Map<String, List<PlanningMember>> _planningMembers = {};

  bool _isLoading = false;
  String? _error;

  StreamSubscription? _accountsSub;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _notesSub;
  StreamSubscription? _marketSub;
  StreamSubscription? _messMembersSub;
  StreamSubscription? _messMealsSub;
  StreamSubscription? _planningsSub;
  StreamSubscription? _messMarketSub;
  StreamSubscription? _messLogsSub;
  StreamSubscription? _messMealPlanSub;
  StreamSubscription? _messHistorySub;
  StreamSubscription? _budgetSub;
  StreamSubscription? _debtSub;
  StreamSubscription? _savingsSub;
  StreamSubscription? _recurringSub;

  List<Account> get accounts => _accounts;
  List<Transaction> get transactions => _transactions;
  List<Note> get notes => _notes;
  List<Note> get pinnedNotes => _notes.where((note) => note.isPinned).toList();
  List<Note> get unpinnedNotes => _notes.where((note) => !note.isPinned).toList();
  List<MarketItem> get marketItems => _marketItems;
  List<MessMember> get messMembers => _messMembers;
  List<MessMeal> get messMeals => _messMeals;
  List<MessMarketExpense> get messMarketExpenses => _messMarketExpenses;
  List<MessActionLog> get messLogs => _messLogs;
  List<MessMealPlan> get messMealPlans => _messMealPlans;
  List<MessHistory> get messHistories => _messHistories;
  MessInfo? get messInfo => _messInfo;
  
  List<Budget> get budgets => _budgets;
  List<Debt> get debts => _debts;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  List<Planning> get plannings => _plannings;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<PlanningMember> getPlanningMembers(String planningId) => _planningMembers[planningId] ?? [];

  double get totalBalance => _accounts.fold(0, (sum, acc) => sum + acc.balance);
  double get totalIncome => _transactions.where((t) => t.type == TransactionType.income).fold(0, (sum, t) => sum + t.amount);
  double get totalExpense => _transactions.where((t) => t.type == TransactionType.expense).fold(0, (sum, t) => sum + t.amount);
  double get totalSavings => totalIncome - totalExpense;

  double get totalMessMeals => _messMembers.fold(0, (sum, m) => sum + m.totalMeals);
  double get totalMessMarketCost => _messMembers.fold(0, (sum, m) => sum + m.totalMarketCost);
  double get mealRate => totalMessMeals == 0 ? 0 : totalMessMarketCost / totalMessMeals;

  Future<void> loadUserData(String userId) async {
    _setLoading(true);
    _cancelSubscriptions();
    try {
      // প্রথমে ইউজারের নিজের প্রোফাইল থেকে মেস আইডি চেক করি
      final userDoc = await _firestore.collection('users').doc(userId).get();
      String messId = userId; // ডিফল্টভাবে নিজের আইডি
      if (userDoc.exists && userDoc.data()!.containsKey('joinedMessId')) {
        messId = userDoc.data()!['joinedMessId'];
      }

      _accountsSub = _firestore.collection('users').doc(userId).collection('accounts').snapshots().listen((snap) {
        _accounts = snap.docs.map((doc) => Account.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _transactionsSub = _firestore.collection('users').doc(userId).collection('transactions').orderBy('date', descending: true).snapshots().listen((snap) {
        _transactions = snap.docs.map((doc) => Transaction.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _notesSub = _firestore.collection('users').doc(userId).collection('notes').orderBy('updatedAt', descending: true).snapshots().listen((snap) {
        _notes = snap.docs.map((doc) => Note.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _marketSub = _firestore.collection('users').doc(userId).collection('market_items').orderBy('addedDate', descending: true).snapshots().listen((snap) {
        _marketItems = snap.docs.map((doc) => MarketItem.fromMap(doc.data())).toList();
        notifyListeners();
      });
      
      _initPlannings(userId);

      // মেস ডাটা লোড (নিজের অথবা জয়েন করা মেসের)
      _messMembersSub = _firestore.collection('users').doc(messId).collection('mess_members').snapshots().listen((snap) {
        _messMembers = snap.docs.map((doc) => MessMember.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _firestore.collection('users').doc(messId).collection('mess_info').doc('details').snapshots().listen((doc) {
        if (doc.exists) { _messInfo = MessInfo.fromMap(doc.data()!); notifyListeners(); }
      });
      _messMealsSub = _firestore.collection('users').doc(messId).collection('mess_meals').orderBy('date', descending: true).snapshots().listen((snap) {
        _messMeals = snap.docs.map((doc) => MessMeal.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _messMarketSub = _firestore.collection('users').doc(messId).collection('mess_market_expenses').orderBy('date', descending: true).snapshots().listen((snap) {
        _messMarketExpenses = snap.docs.map((doc) => MessMarketExpense.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _messLogsSub = _firestore.collection('users').doc(messId).collection('mess_logs').orderBy('timestamp', descending: true).snapshots().listen((snap) {
        _messLogs = snap.docs.map((doc) => MessActionLog.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _messMealPlanSub = _firestore.collection('users').doc(messId).collection('mess_meal_plans').snapshots().listen((snap) {
        _messMealPlans = snap.docs.map((doc) => MessMealPlan.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _messHistorySub = _firestore.collection('users').doc(messId).collection('mess_history').orderBy('date', descending: true).snapshots().listen((snap) {
        _messHistories = snap.docs.map((doc) => MessHistory.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _budgetSub = _firestore.collection('users').doc(userId).collection('budgets').snapshots().listen((snap) {
        _budgets = snap.docs.map((doc) => Budget.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _debtSub = _firestore.collection('users').doc(userId).collection('debts').snapshots().listen((snap) {
        _debts = snap.docs.map((doc) => Debt.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _savingsSub = _firestore.collection('users').doc(userId).collection('savings_goals').snapshots().listen((snap) {
        _savingsGoals = snap.docs.map((doc) => SavingsGoal.fromMap(doc.data())).toList();
        notifyListeners();
      });
      _recurringSub = _firestore.collection('users').doc(userId).collection('recurring_transactions').snapshots().listen((snap) {
        _recurringTransactions = snap.docs.map((doc) => RecurringTransaction.fromMap(doc.data())).toList();
        _checkAndProcessRecurring(userId);
        notifyListeners();
      });
    } catch (e) { _error = e.toString(); } finally { _setLoading(false); }
  }

  void _cancelSubscriptions() {
    _accountsSub?.cancel(); _transactionsSub?.cancel(); _notesSub?.cancel(); _marketSub?.cancel();
    _messMembersSub?.cancel(); _messMealsSub?.cancel(); _messMarketSub?.cancel(); _messLogsSub?.cancel();
    _messMealPlanSub?.cancel(); _messHistorySub?.cancel(); _budgetSub?.cancel(); _debtSub?.cancel();
    _savingsSub?.cancel(); _recurringSub?.cancel(); _planningsSub?.cancel();
  }

  // Account Methods
  Future<void> addAccount(Account account) async {
    await _firestore.collection('users').doc(account.userId).collection('accounts').doc(account.id).set(account.toMap());
  }
  Future<void> updateAccount(Account account) async {
    await _firestore.collection('users').doc(account.userId).collection('accounts').doc(account.id).update(account.toMap());
  }
  Future<void> deleteAccount(String userId, String accountId) async {
    await _firestore.collection('users').doc(userId).collection('accounts').doc(accountId).delete();
  }

  // Transaction Methods
  Future<void> addTransaction(Transaction t) async {
    await _firestore.collection('users').doc(t.userId).collection('transactions').doc(t.id).set(t.toMap());
    // Update linked account balance if applicable
    if (t.accountId != null) {
      final amt = t.type == TransactionType.income ? t.amount : -t.amount;
      await _firestore.collection('users').doc(t.userId).collection('accounts').doc(t.accountId).update({'balance': FieldValue.increment(amt)});
    }
  }

  // Note Methods
  Future<void> addNote(Note note) async {
    await _firestore.collection('users').doc(note.userId).collection('notes').doc(note.id).set(note.toMap());
  }
  Future<void> updateNote(Note note) async {
    await _firestore.collection('users').doc(note.userId).collection('notes').doc(note.id).update(note.toMap());
  }
  Future<void> deleteNote(String userId, String noteId) async {
    await _firestore.collection('users').doc(userId).collection('notes').doc(noteId).delete();
  }
  Future<void> togglePinNote(String userId, String noteId) async {
    final n = _notes.firstWhere((n) => n.id == noteId);
    await _firestore.collection('users').doc(userId).collection('notes').doc(noteId).update({'isPinned': !n.isPinned});
  }

  // Market Methods
  Future<void> addMarketItem(MarketItem item) async {
    await _firestore.collection('users').doc(item.userId).collection('market_items').doc(item.id).set(item.toMap());
  }
  Future<void> deleteMarketItem(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('market_items').doc(id).delete();
  }
  Future<void> togglePurchased(String userId, String itemId) async {
    final i = _marketItems.firstWhere((i) => i.id == itemId);
    await _firestore.collection('users').doc(userId).collection('market_items').doc(itemId).update({'isPurchased': !i.isPurchased, 'purchasedDate': !i.isPurchased ? DateTime.now().toIso8601String() : null});
  }

  // Mess Methods
  Future<void> addMessMember(String managerId, String name, double initialDeposit, {String? appUserId, String? email}) async {
    final id = const Uuid().v4();
    
    // সংশোধিত লজিক: 
    // ১. যদি মেম্বার লিস্ট খালি থাকে এবং যে অ্যাড করছে সে নিজেই মালিক হয়, তবে সে ম্যানেজার।
    // ২. অথবা যদি কোনো মেম্বার অ্যাড করা হয় যার আইডি ম্যানেজারের আইডির সমান (মালিক নিজে নিজেকে অ্যাড করলে)।
    final bool isFirstManager = _messMembers.isEmpty && appUserId == managerId;

    final member = MessMember(
      id: id, 
      userId: managerId, 
      messId: managerId, 
      name: name, 
      initialDeposit: initialDeposit,
      email: email, 
      appUserId: appUserId, 
      isManager: isFirstManager,
    );
    
    final batch = _firestore.batch();
    
    // ম্যানেজারের মেসে মেম্বার অ্যাড করা
    final memberRef = _firestore.collection('users').doc(managerId).collection('mess_members').doc(id);
    batch.set(memberRef, member.toMap());
    
    // যদি মেম্বারের অ্যাপ অ্যাকাউন্ট থাকে (appUserId), তবে তার প্রোফাইলে এই মেস আইডিটি সেভ করা
    if (appUserId != null) {
      final userRef = _firestore.collection('users').doc(appUserId);
      batch.update(userRef, {'joinedMessId': managerId});
    }
    
    await batch.commit();
  }

  Future<void> deleteMessMember(String managerId, String memberId, String? appUserId) async {
    final batch = _firestore.batch();
    
    // ১. ম্যানেজারের কালেকশন থেকে মেম্বার ডিলিট করা
    batch.delete(_firestore.collection('users').doc(managerId).collection('mess_members').doc(memberId));
    
    // ২. যদি মেম্বার অ্যাপ ইউজার হয়, তার প্রোফাইল থেকে মেস আইডি মুছে ফেলা
    if (appUserId != null) {
      batch.update(_firestore.collection('users').doc(appUserId), {
        'joinedMessId': FieldValue.delete(),
      });
    }
    
    await batch.commit();
  }

  Future<void> promoteToManager(String managerId, String targetMemberId, String? targetAppUserId) async {
    if (targetAppUserId == null) return;

    final batch = _firestore.batch();
    
    // ১. বর্তমান সকল ম্যানেজারকে সাধারণ মেম্বার বানানো
    for (var m in _messMembers) {
      if (m.isManager) {
        batch.update(
          _firestore.collection('users').doc(managerId).collection('mess_members').doc(m.id),
          {'isManager': false}
        );
      }
    }
    
    // ২. নতুন মেম্বারকে ম্যানেজার হিসেবে প্রমোট করা
    batch.update(
      _firestore.collection('users').doc(managerId).collection('mess_members').doc(targetMemberId),
      {'isManager': true}
    );
    
    await batch.commit();
  }

  Future<void> updateMemberBills(String userId, String memberId, double rent, double wifi, double elect) async {
    await _firestore.collection('users').doc(userId).collection('mess_members').doc(memberId).update({
      'monthlyRent': rent, 
      'wifiBill': wifi, 
      'electricityBill': elect,
    });
  }
  Future<void> addMeal(String userId, String memberId, double count) async {
    final id = const Uuid().v4();
    final meal = MessMeal(id: id, userId: userId, memberId: memberId, date: DateTime.now(), count: count);
    await _firestore.collection('users').doc(userId).collection('mess_meals').doc(id).set(meal.toMap());
    await _firestore.collection('users').doc(userId).collection('mess_members').doc(memberId).update({'totalMeals': FieldValue.increment(count)});
  }
  Future<void> updateMessInfo(String userId, String name, String address, String phone) async {
    await _firestore.collection('users').doc(userId).collection('mess_info').doc('details').set({
      'name': name, 
      'address': address,
      'ownerPhone': phone,
    });
  }
  Future<void> approveExpense(String userId, MessMarketExpense e) async {
    await _firestore.collection('users').doc(userId).collection('mess_market_expenses').doc(e.id).update({'status': 'approved'});
    await _firestore.collection('users').doc(userId).collection('mess_members').doc(e.memberId).update({'totalMarketCost': FieldValue.increment(e.amount)});
  }
  Future<void> rejectExpense(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('mess_market_expenses').doc(id).update({'status': 'rejected'});
  }
  Future<void> approveMealPlan(String userId, MessMealPlan p) async {
    await _firestore.collection('users').doc(userId).collection('mess_meal_plans').doc(p.id).update({'status': 'approved'});
    await addMeal(userId, p.memberId, p.isEnabled ? 1.0 : 0.0);
  }
  Future<void> rejectMealPlan(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('mess_meal_plans').doc(id).update({'status': 'rejected'});
  }
  Future<void> settleMonth(String userId) async {
    final mSnapshots = _messMembers.map((m) => MemberSnapshot(memberId: m.id, name: m.name, totalMeals: m.totalMeals, totalCost: m.totalMeals * mealRate, totalDue: (m.totalMeals * mealRate) - m.totalMarketCost)).toList();
    final history = MessHistory(id: const Uuid().v4(), userId: userId, date: DateTime.now(), totalMeals: totalMessMeals, totalMarketCost: totalMessMarketCost, mealRate: mealRate, members: mSnapshots);
    await _firestore.collection('users').doc(userId).collection('mess_history').doc(history.id).set(history.toMap());
    for (var m in _messMembers) {
      await _firestore.collection('users').doc(userId).collection('mess_members').doc(m.id).update({'totalMeals': 0, 'totalMarketCost': 0, 'previousDue': (m.totalMeals * mealRate) - m.totalMarketCost});
    }
    final meals = await _firestore.collection('users').doc(userId).collection('mess_meals').get();
    for (var doc in meals.docs) await doc.reference.delete();
    final exps = await _firestore.collection('users').doc(userId).collection('mess_market_expenses').get();
    for (var doc in exps.docs) await doc.reference.delete();
  }

  // Budget/Debt/Savings Methods
  Future<void> addBudget(Budget b) async { await _firestore.collection('users').doc(b.userId).collection('budgets').doc(b.id).set(b.toMap()); }
  Future<void> addDebt(Debt d) async { await _firestore.collection('users').doc(d.userId).collection('debts').doc(d.id).set(d.toMap()); }
  Future<void> settleDebt(String userId, String debtId) async { await _firestore.collection('users').doc(userId).collection('debts').doc(debtId).update({'isSettled': true}); }
  Future<void> addSavingsGoal(SavingsGoal g) async { await _firestore.collection('users').doc(g.userId).collection('savings_goals').doc(g.id).set(g.toMap()); }
  Future<void> updateSavingsProgress(String userId, String goalId, double amt) async { await _firestore.collection('users').doc(userId).collection('savings_goals').doc(goalId).update({'currentAmount': FieldValue.increment(amt)}); }
  
  // Recurring Methods
  Future<void> addRecurringTransaction(RecurringTransaction rt) async { await _firestore.collection('users').doc(rt.userId).collection('recurring_transactions').doc(rt.id).set(rt.toMap()); }
  Future<void> toggleRecurringActive(String userId, String id, bool active) async { await _firestore.collection('users').doc(userId).collection('recurring_transactions').doc(id).update({'isActive': active}); }
  Future<void> deleteRecurringTransaction(String userId, String id) async { await _firestore.collection('users').doc(userId).collection('recurring_transactions').doc(id).delete(); }
  Future<void> _checkAndProcessRecurring(String userId) async {
    final now = DateTime.now();
    for (var rt in _recurringTransactions) {
      if (rt.isActive && rt.nextDate.isBefore(now)) {
        final t = Transaction(id: const Uuid().v4(), userId: userId, title: rt.title, amount: rt.amount, type: TransactionType.expense, category: rt.category, date: rt.nextDate, note: 'Recurring');
        await addTransaction(t);
        DateTime next = rt.interval == RecurringInterval.daily ? rt.nextDate.add(const Duration(days: 1)) : rt.interval == RecurringInterval.weekly ? rt.nextDate.add(const Duration(days: 7)) : rt.interval == RecurringInterval.monthly ? DateTime(rt.nextDate.year, rt.nextDate.month + 1, rt.nextDate.day) : DateTime(rt.nextDate.year + 1, rt.nextDate.month, rt.nextDate.day);
        await _firestore.collection('users').doc(userId).collection('recurring_transactions').doc(rt.id).update({'nextDate': next.toIso8601String()});
      }
    }
  }

  // Common Methods (Graph/Reports)
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

  // Planning Methods
  Map<String, StreamSubscription> _planningMemberSubs = {};

  void _initPlannings(String userId) {
    _planningsSub?.cancel();
    _planningsSub = _firestore.collection('plannings').where('members', arrayContains: userId).snapshots().listen((snap) {
      _plannings = snap.docs.map((doc) => Planning.fromMap(doc.data())).toList();
      
      // Cancel subs for plans no longer in the list
      final currentPids = _plannings.map((p) => p.id).toSet();
      _planningMemberSubs.removeWhere((pid, sub) {
        if (!currentPids.contains(pid)) {
          sub.cancel();
          return true;
        }
        return false;
      });

      // Add new subs for members
      for (var plan in _plannings) {
        if (!_planningMemberSubs.containsKey(plan.id)) {
          _planningMemberSubs[plan.id] = _firestore.collection('plannings').doc(plan.id).collection('members').snapshots().listen((mSnap) {
            _planningMembers[plan.id] = mSnap.docs.map((m) => PlanningMember.fromMap(m.data())).toList();
            notifyListeners();
          });
        }
      }
      notifyListeners();
    });
  }

  Future<void> createPlanning(String title, String desc, double target, double periodic, String type, String cid, String cname) async {
    final id = const Uuid().v4();
    final p = Planning(
      id: id, 
      title: title, 
      description: desc, 
      creatorId: cid, 
      creatorName: cname, 
      targetAmount: target, 
      periodicAmount: periodic,
      collectionType: type,
      createdAt: DateTime.now()
    );
    
    final batch = _firestore.batch();
    
    final planRef = _firestore.collection('plannings').doc(id);
    Map<String, dynamic> planData = p.toMap();
    planData['members'] = [cid]; // Ensure members array is set immediately
    
    batch.set(planRef, planData);
    
    final memberRef = planRef.collection('members').doc(cid);
    final member = PlanningMember(userId: cid, name: cname, email: '');
    batch.set(memberRef, member.toMap());
    
    await batch.commit();
  }
  Future<void> addPlanningMember(String pid, String uid, String name, String email) async {
    final m = PlanningMember(userId: uid, name: name, email: email);
    final batch = _firestore.batch();
    
    final planRef = _firestore.collection('plannings').doc(pid);
    batch.update(planRef, {'members': FieldValue.arrayUnion([uid])});
    
    final memberRef = planRef.collection('members').doc(uid);
    batch.set(memberRef, m.toMap());
    
    await batch.commit();
  }
  Future<void> updateContributedAmount(String pid, String uid, double amt) async {
    await _firestore.collection('plannings').doc(pid).collection('members').doc(uid).update({'contributedAmount': FieldValue.increment(amt), 'hasPaid': true});
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  @override void dispose() { _cancelSubscriptions(); super.dispose(); }
}
