import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cosmetic_product.dart';

/// Local database service for storing cosmetic products
/// Uses SQLite for offline data persistence
class DatabaseService {
  static Database? _database;
  static const String _tableName = 'cosmetic_products';

  /// Get database instance (singleton pattern)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database and create tables
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'skincare_harmony.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT,
        category TEXT,
        openDate TEXT NOT NULL,
        paoDays INTEGER NOT NULL,
        imagePath TEXT,
        notes TEXT,
        userId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  /// Insert new cosmetic product
  Future<int> insertProduct(CosmeticProduct product) async {
    final db = await database;
    return await db.insert(_tableName, product.toMap());
  }

  /// Get all products for a user
  Future<List<CosmeticProduct>> getProducts(String? userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return CosmeticProduct.fromMap(maps[i]);
    });
  }

  /// Update existing product
  Future<int> updateProduct(CosmeticProduct product) async {
    final db = await database;
    return await db.update(
      _tableName,
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Delete product
  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get products expiring soon (within specified days)
  Future<List<CosmeticProduct>> getExpiringProducts(String? userId, int days) async {
    final db = await database;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $_tableName 
      WHERE ${userId != null ? 'userId = ? AND' : ''} 
      date(openDate, '+' || paoDays || ' days') <= date(?)
      ORDER BY date(openDate, '+' || paoDays || ' days') ASC
    ''', userId != null ? [userId, futureDate.toIso8601String()] : [futureDate.toIso8601String()]);

    return List.generate(maps.length, (i) {
      return CosmeticProduct.fromMap(maps[i]);
    });
  }

  /// Search products by name or brand
  Future<List<CosmeticProduct>> searchProducts(String query, String? userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '''
        ${userId != null ? 'userId = ? AND' : ''} 
        (name LIKE ? OR brand LIKE ?)
      ''',
      whereArgs: userId != null 
        ? [userId, '%$query%', '%$query%']
        : ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) {
      return CosmeticProduct.fromMap(maps[i]);
    });
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
