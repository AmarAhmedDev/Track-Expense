import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

/// SQLite database helper — single source of truth for all local data.
/// Handles initialization, migrations, and CRUD for all entities.
/// Fully offline — no network calls anywhere in this class.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  /// Global notifier to trigger UI reloads automatically across screens
  final ValueNotifier<int> onTransactionsChanged = ValueNotifier<int>(0);

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_expense_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Transactions table — core financial records
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        category_icon TEXT NOT NULL,
        category_color TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense'))
      )
    ''');

    // Categories table — user-defined spending categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    // Budget table — monthly spending limits
    await db.execute('''
      CREATE TABLE budget (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monthly_limit REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        UNIQUE(month, year)
      )
    ''');

    // Seed default categories
    await _seedDefaultCategories(db);

    // Seed realistic sample transactions
    await _seedSampleTransactions(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final categories = [
      {'name': 'Food & Dining', 'icon': 'restaurant', 'color': '#F97316'},
      {'name': 'Transport', 'icon': 'directions_car', 'color': '#3B82F6'},
      {'name': 'Shopping', 'icon': 'shopping_bag', 'color': '#EC4899'},
      {'name': 'Bills', 'icon': 'receipt', 'color': '#8B5CF6'},
      {'name': 'Health', 'icon': 'favorite', 'color': '#EF4444'},
      {'name': 'Education', 'icon': 'school', 'color': '#10B981'},
      {'name': 'Entertainment', 'icon': 'movie', 'color': '#F59E0B'},
      {'name': 'Other', 'icon': 'more_horiz', 'color': '#6B7280'},
    ];
    for (final cat in categories) {
      await db.insert('categories', cat);
    }
  }

  Future<void> _seedSampleTransactions(Database db) async {
    final now = DateTime.now();
    final transactions = [
      {
        'title': 'Grocery Store',
        'amount': 67.50,
        'category': 'Food & Dining',
        'category_icon': 'restaurant',
        'category_color': '#F97316',
        'date': now.subtract(const Duration(hours: 3)).toIso8601String(),
        'note': 'Weekly groceries',
        'type': 'expense',
      },
      {
        'title': 'Monthly Salary',
        'amount': 3200.00,
        'category': 'Other',
        'category_icon': 'attach_money',
        'category_color': '#6B7280',
        'date': now.subtract(const Duration(days: 1)).toIso8601String(),
        'note': 'April salary',
        'type': 'income',
      },
      {
        'title': 'Uber Ride',
        'amount': 12.40,
        'category': 'Transport',
        'category_icon': 'directions_car',
        'category_color': '#3B82F6',
        'date': now
            .subtract(const Duration(days: 1, hours: 5))
            .toIso8601String(),
        'note': null,
        'type': 'expense',
      },
      {
        'title': 'Netflix Subscription',
        'amount': 15.99,
        'category': 'Entertainment',
        'category_icon': 'movie',
        'category_color': '#F59E0B',
        'date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'note': 'Monthly plan',
        'type': 'expense',
      },
      {
        'title': 'Electricity Bill',
        'amount': 89.00,
        'category': 'Bills',
        'category_icon': 'receipt',
        'category_color': '#8B5CF6',
        'date': now.subtract(const Duration(days: 3)).toIso8601String(),
        'note': 'March billing',
        'type': 'expense',
      },
      {
        'title': 'Freelance Project',
        'amount': 450.00,
        'category': 'Other',
        'category_icon': 'attach_money',
        'category_color': '#6B7280',
        'date': now.subtract(const Duration(days: 4)).toIso8601String(),
        'note': 'UI design project',
        'type': 'income',
      },
      {
        'title': 'Pharmacy',
        'amount': 34.20,
        'category': 'Health',
        'category_icon': 'favorite',
        'category_color': '#EF4444',
        'date': now.subtract(const Duration(days: 5)).toIso8601String(),
        'note': null,
        'type': 'expense',
      },
      {
        'title': 'Online Course',
        'amount': 29.99,
        'category': 'Education',
        'category_icon': 'school',
        'category_color': '#10B981',
        'date': now.subtract(const Duration(days: 6)).toIso8601String(),
        'note': 'Flutter advanced course',
        'type': 'expense',
      },
      {
        'title': 'Clothing Store',
        'amount': 145.00,
        'category': 'Shopping',
        'category_icon': 'shopping_bag',
        'category_color': '#EC4899',
        'date': now.subtract(const Duration(days: 7)).toIso8601String(),
        'note': null,
        'type': 'expense',
      },
      {
        'title': 'Restaurant Dinner',
        'amount': 52.80,
        'category': 'Food & Dining',
        'category_icon': 'restaurant',
        'category_color': '#F97316',
        'date': now.subtract(const Duration(days: 8)).toIso8601String(),
        'note': 'Family dinner',
        'type': 'expense',
      },
    ];

    for (final tx in transactions) {
      await db.insert('transactions', tx);
    }

    // Seed default budget
    await db.insert('budget', {
      'monthly_limit': 1500.00,
      'month': now.month,
      'year': now.year,
    });
  }

  // ── TRANSACTION CRUD ──────────────────────────────────────────

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> searchTransactions(String query) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'title LIKE ? OR category LIKE ? OR note LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );
    return maps.map(TransactionModel.fromMap).toList();
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    final id = await db.insert('transactions', transaction.toMap());
    onTransactionsChanged.value++;
    return id;
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    final count = await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    onTransactionsChanged.value++;
    return count;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    final count = await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    onTransactionsChanged.value++;
    return count;
  }

  Future<double> getTotalByType(TransactionType type, {DateTime? month}) async {
    final db = await database;
    final typeStr = type == TransactionType.income ? 'income' : 'expense';
    String where = 'type = ?';
    List<dynamic> whereArgs = [typeStr];

    if (month != null) {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      where += ' AND date BETWEEN ? AND ?';
      whereArgs.addAll([
        startOfMonth.toIso8601String(),
        endOfMonth.toIso8601String(),
      ]);
    }

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM transactions WHERE $where',
      whereArgs,
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getCategoryTotals({DateTime? month}) async {
    final db = await database;
    String where = "type = 'expense'";
    List<dynamic> whereArgs = [];

    if (month != null) {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      where += ' AND date BETWEEN ? AND ?';
      whereArgs.addAll([
        startOfMonth.toIso8601String(),
        endOfMonth.toIso8601String(),
      ]);
    }

    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM transactions WHERE $where GROUP BY category',
      whereArgs,
    );

    return {
      for (final row in result)
        row['category'] as String: (row['total'] as num).toDouble(),
    };
  }

  // ── CATEGORIES CRUD ───────────────────────────────────────────

  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(CategoryModel.fromMap).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── BUDGET CRUD ───────────────────────────────────────────────

  Future<BudgetModel?> getCurrentBudget() async {
    final db = await database;
    final now = DateTime.now();
    final maps = await db.query(
      'budget',
      where: 'month = ? AND year = ?',
      whereArgs: [now.month, now.year],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BudgetModel.fromMap(maps.first);
  }

  Future<int> upsertBudget(BudgetModel budget) async {
    final db = await database;
    return await db.insert(
      'budget',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── RESET ─────────────────────────────────────────────────────

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('budget');
    onTransactionsChanged.value++;
  }
}
