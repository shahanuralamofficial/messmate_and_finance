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
import '../models/budget.dart';
import '../models/debt.dart';
import '../models/savings_goal.dart';
import '../models/recurring_transaction.dart';

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
  MessInfo? _messInfo;
  
  // New Lists
  List<Budget> _budgets = [];
  List<Debt> _debts = [];
  List<SavingsGoal> _savingsGoals = [];
  List<RecurringTransaction> _recurringTransactions = [];

  bool _isLoading = false;
  String? _error;

  StreamSubscription? _accountsSub;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _notesSub;
  StreamSubscription? _marketSub;
  StreamSubscription? _messMembersSub;
  StreamSubscription? _messMealsSub;
  StreamSubscription? _messMarketSub;
  StreamSubscription? _messLogsSub;
  StreamSubscription? _messMealPlanSub;
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
  MessInfo? get messInfo => _messInfo;
  
  List<Budget> get budgets => _budgets;
  List<Debt> get debts => _debts;
  List<SavingsGoal> get savingsGoals => _savingsGoals;
  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalBalance => _accounts.fold(0, (sum, acc) => sum + acc.balance);
  double get totalIncome => _transactions.where((t) => t.type == TransactionType.income).fold(0, (sum, t) => sum + t.amount);
  double get totalExpense => _transactions.where((t) => t.type == TransactionType.expense).fold(0, (sum, t) => sum + t.amount);
  double get totalSavings => totalIncome - totalExpense;

  // Mess Calculations
  double get totalMessMeals => _messMembers.fold(0, (sum, m) => sum + m.totalMeals);
  double get totalMessMarketCost => _messMembers.fold(0, (sum, m) => sum + m.totalMarketCost);
  double get mealRate => totalMessMeals == 0 ? 0 : totalMessMarketCost / totalMessMeals;

  // Daily Calculations
  double getDailyMealRate(DateTime date) {
    final dayExpenses = _messMarketExpenses
        .where((e) => e.status == ExpenseStatus.approved && 
                      e.date.day == date.day && 
                      e.date.month == date.month && 
                      e.date.year == date.year)
        .fold(0.0, (sum, e) => sum + e.amount);

    final dayMeals = _messMeals
        .where((m) => m.date.day == date.day && 
                      m.date.month == date.month && 
                      m.date.year == date.year)
        .fold(0.0, (sum, m) => sum + m.count);

    return dayMeals == 0 ? 0 : dayExpenses / dayMeals;
  }

  double getMemberDailyCost(String memberId, DateTime date) {
    final dayMealCount = _messMeals
        .where((m) => m.memberId == memberId && 
                      m.date.day == date.day && 
                      m.date.month == date.month && 
                      m.date.year == date.year)
        .fold(0.0, (sum, m) => sum + m.count);
    
    // Using overall meal rate for consistency, or daily if requested. 
    // Usually daily rate fluctuates too much, but per user request:
    return dayMealCount * getDailyMealRate(date);
  }

  Future<void> loadUserData(String userId) async {
    _setLoading(true);
    _cancelSubscriptions();

    try {
      // ... existing listeners ...
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

      _messMembersSub = _firestore.collection('users').doc(userId).collection('mess_members')
          .snapshots().listen((snap) {
        _messMembers = snap.docs.map((doc) => MessMember.fromMap(doc.data())).toList();
        notifyListeners();
      });

      _firestore.collection('users').doc(userId).collection('mess_info').doc('details').snapshots().listen((doc) {
        if (doc.exists) {
          _messInfo = MessInfo.fromMap(doc.data()!);
          notifyListeners();
        }
      });

      _messMealsSub = _firestore.collection('users').doc(userId).collection('mess_meals')
          .orderBy('date', descending: true).snapshots().listen((snap) {
        _messMeals = snap.docs.map((doc) => MessMeal.fromMap(doc.data())).toList();
        notifyListeners();
      });

      _messMarketSub = _firestore.collection('users').doc(userId).collection('mess_market_expenses')
          .orderBy('date', descending: true).snapshots().listen((snap) {
        _messMarketExpenses = snap.docs.map((doc) => MessMarketExpense.fromMap(doc.data())).toList();
        notifyListeners();
      });

      _messLogsSub = _firestore.collection('users').doc(userId).collection('mess_logs')
          .orderBy('timestamp', descending: true).snapshots().listen((snap) {
        _messLogs = snap.docs.map((doc) => MessActionLog.fromMap(doc.data())).toList();
        notifyListeners();
      });

      _messMealPlanSub = _firestore.collection('users').doc(userId).collection('mess_meal_plans')
          .snapshots().listen((snap) {
        _messMealPlans = snap.docs.map((doc) => MessMealPlan.fromMap(doc.data())).toList();
        notifyListeners();
      });

      _budgetSub = _firestore.collection('users').doc(userId).collection('budgets')
          .snapshots().listen((snap) {
        _budgets = snap.docs.map((doc) => Budget.fromMap(doc.data())).toList();
        notifyListeners();
      });

      _debtSub = _firestore.collection('users').doc(userId).collection('debts')
          .snapshots().listen((snap) {
        _debts = snap.docs.map((doc) => Debt.fromMap(doc.data())).toList();
        notifyListeners();
      });

      _savingsSub = _firestore.collection('users').doc(userId).collection('savings_goals')
          .snapshots().listen((snap) {
        _savingsGoals = snap.docs.map((doc) => SavingsGoal.fromMap(doc.data())).toList();
        notifyListeners();
      });

      _recurringSub = _firestore.collection('users').doc(userId).collection('recurring_transactions')
          .snapshots().listen((snap) {
        _recurringTransactions = snap.docs.map((doc) => RecurringTransaction.fromMap(doc.data())).toList();
        _checkAndProcessRecurring(userId);
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
    _messMembersSub?.cancel();
    _messMealsSub?.cancel();
    _messMarketSub?.cancel();
    _messLogsSub?.cancel();
    _messMealPlanSub?.cancel();
    _budgetSub?.cancel();
    _debtSub?.cancel();
    _savingsSub?.cancel();
    _recurringSub?.cancel();
  }

  // Recurring Transaction Methods
  Future<void> addRecurringTransaction(RecurringTransaction rt) async {
    await _firestore.collection('users').doc(rt.userId).collection('recurring_transactions').doc(rt.id).set(rt.toMap());
  }

  Future<void> toggleRecurringActive(String userId, String id, bool isActive) async {
    await _firestore.collection('users').doc(userId).collection('recurring_transactions').doc(id).update({'isActive': isActive});
  }

  Future<void> deleteRecurringTransaction(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('recurring_transactions').doc(id).delete();
  }

  Future<void> _checkAndProcessRecurring(String userId) async {
    final now = DateTime.now();
    for (var rt in _recurringTransactions) {
      if (rt.isActive && rt.nextDate.isBefore(now)) {
        // Create actual transaction
        final tId = const Uuid().v4();
        final transaction = Transaction(
          id: tId,
          userId: userId,
          title: rt.title,
          amount: rt.amount,
          type: TransactionType.expense,
          category: rt.category,
          date: rt.nextDate,
          note: 'Auto-generated from Recurring: ${rt.title}',
        );

        // Update next date
        DateTime nextDate;
        switch (rt.interval) {
          case RecurringInterval.daily:
            nextDate = rt.nextDate.add(const Duration(days: 1));
            break;
          case RecurringInterval.weekly:
            nextDate = rt.nextDate.add(const Duration(days: 7));
            break;
          case RecurringInterval.monthly:
            nextDate = DateTime(rt.nextDate.year, rt.nextDate.month + 1, rt.nextDate.day);
            break;
          case RecurringInterval.yearly:
            nextDate = DateTime(rt.nextDate.year + 1, rt.nextDate.month, rt.nextDate.day);
            break;
        }

        final batch = _firestore.batch();
        batch.set(_firestore.collection('users').doc(userId).collection('transactions').doc(tId), transaction.toMap());
        batch.update(_firestore.collection('users').doc(userId).collection('recurring_transactions').doc(rt.id), {
          'nextDate': nextDate.toIso8601String(),
        });
        await batch.commit();
      }
    }
  }

  // Budget Methods
  Future<void> addBudget(Budget budget) async {
    await _firestore.collection('users').doc(budget.userId).collection('budgets').doc(budget.id).set(budget.toMap());
  }

  Future<void> deleteBudget(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('budgets').doc(id).delete();
  }

  // Debt Methods
  Future<void> addDebt(Debt debt) async {
    await _firestore.collection('users').doc(debt.userId).collection('debts').doc(debt.id).set(debt.toMap());
  }

  Future<void> settleDebt(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('debts').doc(id).update({'isSettled': true});
  }

  Future<void> deleteDebt(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('debts').doc(id).delete();
  }

  // Savings Goal Methods
  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await _firestore.collection('users').doc(goal.userId).collection('savings_goals').doc(goal.id).set(goal.toMap());
  }

  Future<void> updateSavingsProgress(String userId, String id, double amount) async {
    await _firestore.collection('users').doc(userId).collection('savings_goals').doc(id).update({
      'currentAmount': FieldValue.increment(amount)
    });
  }

  Future<void> deleteSavingsGoal(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('savings_goals').doc(id).delete();
  }

  // Mess Management Methods
  Future<void> addMessMember(String managerId, String name, double deposit) async {
    final id = const Uuid().v4();
    final member = MessMember(
      id: id,
      userId: managerId,
      messId: managerId,
      name: name,
      initialDeposit: deposit,
      isManager: false,
    );
    await _firestore.collection('users').doc(managerId).collection('mess_members').doc(id).set(member.toMap());
    await _addMessLog(managerId, managerId, 'Manager', 'Member Added', 'Added member: $name');
  }

  Future<void> addMeal(String managerId, String memberId, double count) async {
    final id = const Uuid().v4();
    final meal = MessMeal(
      id: id,
      userId: managerId,
      memberId: memberId,
      date: DateTime.now(),
      count: count,
    );
    
    final batch = _firestore.batch();
    batch.set(_firestore.collection('users').doc(managerId).collection('mess_meals').doc(id), meal.toMap());
    batch.update(_firestore.collection('users').doc(managerId).collection('mess_members').doc(memberId), {
      'totalMeals': FieldValue.increment(count)
    });
    
    await batch.commit();
  }

  Future<void> updateMemberBills(String managerId, String memberId, double rent, double wifi, double elect) async {
    await _firestore.collection('users').doc(managerId).collection('mess_members').doc(memberId).update({
      'monthlyRent': rent,
      'wifiBill': wifi,
      'electricityBill': elect,
    });
  }

  Future<void> updateMessInfo(String name, String address, String phone) async {
    if (_messMembers.isEmpty) return;
    final managerId = _messMembers.firstWhere((m) => m.isManager).userId;
    
    final info = MessInfo(
      id: 'details',
      name: name,
      address: address,
      ownerPhone: phone,
    );
    
    await _firestore.collection('users').doc(managerId).collection('mess_info').doc('details').set(info.toMap());
  }

  Future<void> _addMessLog(String userId, String actorId, String actorName, String action, String details) async {
    final logId = const Uuid().v4();
    final log = MessActionLog(
      id: logId,
      messId: userId,
      actorId: actorId,
      actorName: actorName,
      action: action,
      details: details,
      timestamp: DateTime.now(),
    );
    await _firestore.collection('users').doc(userId).collection('mess_logs').doc(logId).set(log.toMap());
  }

  Future<void> updateMessMember(MessMember member) async {
    await _firestore.collection('users').doc(member.userId).collection('mess_members').doc(member.id).update(member.toMap());
  }

  Future<void> transferManagerRole(String userId, String oldManagerMemberId, String newManagerMemberId) async {
    final batch = _firestore.batch();
    final oldRef = _firestore.collection('users').doc(userId).collection('mess_members').doc(oldManagerMemberId);
    final newRef = _firestore.collection('users').doc(userId).collection('mess_members').doc(newManagerMemberId);
    
    batch.update(oldRef, {'isManager': false});
    batch.update(newRef, {'isManager': true});
    
    await batch.commit();
    await _addMessLog(userId, userId, 'System', 'Manager Transferred', 'Role transferred to a new member');
  }

  Future<void> deleteMessMember(String userId, String id) async {
    await _firestore.collection('users').doc(userId).collection('mess_members').doc(id).delete();
    // Also delete their meals
    final meals = await _firestore.collection('users').doc(userId).collection('mess_meals').where('memberId', isEqualTo: id).get();
    final batch = _firestore.batch();
    for (var doc in meals.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> addMessMeal(MessMeal meal) async {
    final batch = _firestore.batch();
    final mealRef = _firestore.collection('users').doc(meal.userId).collection('mess_meals').doc(meal.id);
    batch.set(mealRef, meal.toMap());

    // Update member's total meals
    final memberRef = _firestore.collection('users').doc(meal.userId).collection('mess_members').doc(meal.memberId);
    batch.update(memberRef, {'totalMeals': FieldValue.increment(meal.count)});

    await batch.commit();
  }

  Future<void> deleteMessMeal(MessMeal meal) async {
    final batch = _firestore.batch();
    final mealRef = _firestore.collection('users').doc(meal.userId).collection('mess_meals').doc(meal.id);
    batch.delete(mealRef);

    // Update member's total meals
    final memberRef = _firestore.collection('users').doc(meal.userId).collection('mess_members').doc(meal.memberId);
    batch.update(memberRef, {'totalMeals': FieldValue.increment(-meal.count)});

    await batch.commit();
  }

  Future<void> addMessMarketCost(String userId, String memberId, double amount, String description, String actorName, {bool isManager = false}) async {
    final batch = _firestore.batch();
    
    final expenseId = const Uuid().v4();
    final expenseRef = _firestore.collection('users').doc(userId).collection('mess_market_expenses').doc(expenseId);
    
    final member = _messMembers.firstWhere((m) => m.id == memberId);
    
    final expense = MessMarketExpense(
      id: expenseId,
      messId: userId,
      memberId: memberId,
      memberName: member.name,
      amount: amount,
      description: description,
      date: DateTime.now(),
      status: isManager ? ExpenseStatus.approved : ExpenseStatus.pending,
    );
    
    batch.set(expenseRef, expense.toMap());

    if (isManager) {
      // Update member's total market cost immediately if manager adds it
      final memberRef = _firestore.collection('users').doc(userId).collection('mess_members').doc(memberId);
      batch.update(memberRef, {'totalMarketCost': FieldValue.increment(amount)});
    }

    // Add Log
    final logId = const Uuid().v4();
    final logRef = _firestore.collection('users').doc(userId).collection('mess_logs').doc(logId);
    final log = MessActionLog(
      id: logId,
      messId: userId,
      actorId: memberId,
      actorName: actorName,
      action: 'Market Expense',
      details: '${isManager ? "Added" : "Requested"} $amount for $description',
      timestamp: DateTime.now(),
    );
    batch.set(logRef, log.toMap());

    await batch.commit();
  }

  Future<void> approveExpense(String userId, MessMarketExpense expense) async {
    final batch = _firestore.batch();
    
    // Update expense status
    final expenseRef = _firestore.collection('users').doc(userId).collection('mess_market_expenses').doc(expense.id);
    batch.update(expenseRef, {'status': ExpenseStatus.approved.name});

    // Update member's total market cost
    final memberRef = _firestore.collection('users').doc(userId).collection('mess_members').doc(expense.memberId);
    batch.update(memberRef, {'totalMarketCost': FieldValue.increment(expense.amount)});

    // Add Log
    await _addMessLog(userId, userId, 'Manager', 'Expense Approved', 'Approved ${expense.amount} for ${expense.memberName}');

    await batch.commit();
  }

  Future<void> rejectExpense(String userId, String expenseId) async {
    await _firestore.collection('users').doc(userId).collection('mess_market_expenses').doc(expenseId).update({
      'status': ExpenseStatus.rejected.name
    });
    await _addMessLog(userId, userId, 'Manager', 'Expense Rejected', 'Market expense rejected');
  }

  Future<void> requestMealPlan(String userId, String memberId, String memberName, DateTime date, bool isEnabled) async {
    // Rule: Must be at least 1 day in advance
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final requestDate = DateTime(date.year, date.month, date.day);
    final minDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    
    if (requestDate.isBefore(minDate)) {
      throw Exception('You must request meal changes at least 1 day in advance.');
    }

    final planId = '${memberId}_${date.year}_${date.month}_${date.day}';
    final planRef = _firestore.collection('users').doc(userId).collection('mess_meal_plans').doc(planId);
    
    final plan = MessMealPlan(
      id: planId,
      messId: userId,
      memberId: memberId,
      memberName: memberName,
      date: date,
      isEnabled: isEnabled,
      status: MealPlanStatus.pending,
    );

    await planRef.set(plan.toMap());
    await _addMessLog(userId, memberId, memberName, 'Meal Request', 'Requested meal ${isEnabled ? "ON" : "OFF"} for ${date.day}/${date.month}');
  }

  Future<void> approveMealPlan(String userId, MessMealPlan plan) async {
    await _firestore.collection('users').doc(userId).collection('mess_meal_plans').doc(plan.id).update({
      'status': MealPlanStatus.approved.name
    });
    await _addMessLog(userId, userId, 'Manager', 'Meal Approved', 'Approved ${plan.isEnabled ? "ON" : "OFF"} for ${plan.memberName}');
  }

  Future<void> rejectMealPlan(String userId, String planId) async {
    await _firestore.collection('users').doc(userId).collection('mess_meal_plans').doc(planId).update({
      'status': MealPlanStatus.rejected.name
    });
  }

  Future<void> toggleMealPlan(String userId, String memberId, DateTime date, bool isEnabled, String actorName) async {
    // Manager's direct toggle (auto-approved)
    final planId = '${memberId}_${date.year}_${date.month}_${date.day}';
    final planRef = _firestore.collection('users').doc(userId).collection('mess_meal_plans').doc(planId);
    
    final plan = MessMealPlan(
      id: planId,
      messId: userId,
      memberId: memberId,
      memberName: actorName,
      date: date,
      isEnabled: isEnabled,
      status: MealPlanStatus.approved,
    );

    await planRef.set(plan.toMap());
    await _addMessLog(userId, memberId, actorName, 'Meal Toggle', '${isEnabled ? "Enabled" : "Disabled"} meal for ${date.day}/${date.month}');
  }

  Future<void> updateMessMemberBills(String userId, String memberId, {
    double? rent,
    double? wifi,
    double? electricity,
    double? others,
  }) async {
    final memberRef = _firestore.collection('users').doc(userId).collection('mess_members').doc(memberId);
    Map<String, dynamic> updates = {};
    if (rent != null) updates['monthlyRent'] = rent;
    if (wifi != null) updates['wifiBill'] = wifi;
    if (electricity != null) updates['electricityBill'] = electricity;
    if (others != null) updates['otherBills'] = others;
    
    if (updates.isNotEmpty) {
      await memberRef.update(updates);
    }
  }

  Future<void> toggleMemberPaidStatus(String userId, String memberId, bool isPaid, {String? method}) async {
    final updates = {
      'isPaid': isPaid,
      'paymentMethod': method,
      'paymentStatus': isPaid ? 'pending' : 'unpaid',
    };
    await _firestore.collection('users').doc(userId).collection('mess_members').doc(memberId).update(updates);
    
    final member = _messMembers.firstWhere((m) => m.id == memberId);
    await _addMessLog(userId, memberId, member.name, isPaid ? 'Payment Sent' : 'Payment Reset', 
      isPaid ? 'Sent payment via ${method ?? "Cash"}. Waiting for approval.' : 'Payment status reset.');
  }

  Future<void> confirmPayment(String userId, String memberId) async {
    await _firestore.collection('users').doc(userId).collection('mess_members').doc(memberId).update({
      'paymentStatus': 'confirmed',
      'isPaid': true,
    });
    
    final member = _messMembers.firstWhere((m) => m.id == memberId);
    await _addMessLog(userId, userId, 'Manager', 'Payment Confirmed', 'Confirmed payment for ${member.name}');
  }

  Future<void> settleMonth(String userId) async {
    final batch = _firestore.batch();
    final mRate = mealRate;

    for (var member in _messMembers) {
      final double cost = (member.totalMeals * mRate);
      final double totalDue = (member.monthlyRent + member.wifiBill + member.electricityBill + member.otherBills + cost + member.previousDue) - member.initialDeposit;
      
      final memberRef = _firestore.collection('users').doc(userId).collection('mess_members').doc(member.id);
      
      // If not paid, current balance/due becomes previousDue for next month
      // Reset meals and deposits for new month
      batch.update(memberRef, {
        'previousDue': totalDue,
        'initialDeposit': 0.0,
        'totalMeals': 0.0,
        'totalMarketCost': 0.0,
        'isPaid': false,
        'monthlyRent': 0.0,
        'wifiBill': 0.0,
        'electricityBill': 0.0,
        'otherBills': 0.0,
      });
    }

    // Clear meals and market expenses for the mess
    final meals = await _firestore.collection('users').doc(userId).collection('mess_meals').get();
    for (var doc in meals.docs) {
      batch.delete(doc.reference);
    }

    final expenses = await _firestore.collection('users').doc(userId).collection('mess_market_expenses').get();
    for (var doc in expenses.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    await _addMessLog(userId, userId, 'System', 'Month Settled', 'All accounts carried over to next month.');
  }

  Future<void> depositMoney(String userId, String memberId, double amount) async {
    final memberRef = _firestore.collection('users').doc(userId).collection('mess_members').doc(memberId);
    await memberRef.update({'initialDeposit': FieldValue.increment(amount)});
  }

  Future<void> _addMessLog(String userId, String actorId, String actorName, String action, String details) async {
    final logId = const Uuid().v4();
    final log = MessActionLog(
      id: logId,
      messId: userId,
      actorId: actorId,
      actorName: actorName,
      action: action,
      details: details,
      timestamp: DateTime.now(),
    );
    await _firestore.collection('users').doc(userId).collection('mess_logs').doc(logId).set(log.toMap());
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
