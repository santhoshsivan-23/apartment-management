import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Central offline database for the whole app.
/// Everything the app needs lives in a single local SQLite file on the
/// device's application documents directory — no server, no network calls.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static Database? _db;
  static const int dbVersion = 1;
  static const String dbFileName = 'apartment_management.db';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  /// Full path to the underlying .db file — used by backup/restore.
  Future<String> get dbFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, dbFileName);
  }

  Future<Database> _initDb() async {
    final path = await dbFilePath;
    return openDatabase(
      path,
      version: dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // ---------------- Community / structure ----------------
    batch.execute('''
      CREATE TABLE communities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        city TEXT,
        state TEXT,
        pincode TEXT,
        contact_number TEXT,
        email TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )''');

    batch.execute('''
      CREATE TABLE buildings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        community_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        total_floors INTEGER DEFAULT 0,
        total_apartments INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (community_id) REFERENCES communities (id) ON DELETE CASCADE
      )''');

    batch.execute('''
      CREATE TABLE floors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        building_id INTEGER NOT NULL,
        floor_number INTEGER NOT NULL,
        name TEXT,
        FOREIGN KEY (building_id) REFERENCES buildings (id) ON DELETE CASCADE
      )''');

    batch.execute('''
      CREATE TABLE apartments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        building_id INTEGER NOT NULL,
        floor_id INTEGER,
        apartment_number TEXT NOT NULL,
        type TEXT,
        area_sqft REAL,
        status TEXT DEFAULT 'vacant',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (building_id) REFERENCES buildings (id) ON DELETE CASCADE,
        FOREIGN KEY (floor_id) REFERENCES floors (id) ON DELETE SET NULL
      )''');

    // ---------------- Residents ----------------
    batch.execute('''
      CREATE TABLE residents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        apartment_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        type TEXT DEFAULT 'owner',
        move_in_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (apartment_id) REFERENCES apartments (id) ON DELETE CASCADE
      )''');

    batch.execute('''
      CREATE TABLE family_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        resident_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        relation TEXT,
        age INTEGER,
        FOREIGN KEY (resident_id) REFERENCES residents (id) ON DELETE CASCADE
      )''');

    batch.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        resident_id INTEGER NOT NULL,
        vehicle_number TEXT NOT NULL,
        type TEXT,
        model TEXT,
        FOREIGN KEY (resident_id) REFERENCES residents (id) ON DELETE CASCADE
      )''');

    batch.execute('''
      CREATE TABLE parking_slots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        apartment_id INTEGER,
        slot_number TEXT NOT NULL,
        type TEXT,
        FOREIGN KEY (apartment_id) REFERENCES apartments (id) ON DELETE SET NULL
      )''');

    // ---------------- Maintenance / billing ----------------
    batch.execute('''
      CREATE TABLE maintenance_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )''');

    batch.execute('''
      CREATE TABLE maintenance_bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        apartment_id INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        amount REAL NOT NULL,
        due_date TEXT,
        status TEXT DEFAULT 'unpaid',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (apartment_id) REFERENCES apartments (id) ON DELETE CASCADE
      )''');

    batch.execute('''
      CREATE TABLE bill_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES maintenance_bills (id) ON DELETE CASCADE
      )''');

    batch.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        mode TEXT,
        reference TEXT,
        FOREIGN KEY (bill_id) REFERENCES maintenance_bills (id) ON DELETE CASCADE
      )''');

    // ---------------- Expenses ----------------
    batch.execute('''
      CREATE TABLE expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )''');

    batch.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        vendor_id INTEGER,
        description TEXT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES expense_categories (id) ON DELETE SET NULL,
        FOREIGN KEY (vendor_id) REFERENCES vendors (id) ON DELETE SET NULL
      )''');

    // ---------------- Complaints ----------------
    batch.execute('''
      CREATE TABLE complaints (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        apartment_id INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT DEFAULT 'open',
        priority TEXT DEFAULT 'normal',
        created_date TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (apartment_id) REFERENCES apartments (id) ON DELETE SET NULL
      )''');

    batch.execute('''
      CREATE TABLE complaint_comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        complaint_id INTEGER NOT NULL,
        comment TEXT NOT NULL,
        date TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (complaint_id) REFERENCES complaints (id) ON DELETE CASCADE
      )''');

    // ---------------- Visitors ----------------
    batch.execute('''
      CREATE TABLE visitors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        apartment_id INTEGER,
        name TEXT NOT NULL,
        phone TEXT,
        purpose TEXT,
        entry_time TEXT DEFAULT CURRENT_TIMESTAMP,
        exit_time TEXT,
        FOREIGN KEY (apartment_id) REFERENCES apartments (id) ON DELETE SET NULL
      )''');

    batch.execute('''
      CREATE TABLE visitor_passes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        visitor_id INTEGER NOT NULL,
        valid_from TEXT,
        valid_to TEXT,
        code TEXT,
        FOREIGN KEY (visitor_id) REFERENCES visitors (id) ON DELETE CASCADE
      )''');

    // ---------------- Amenities ----------------
    batch.execute('''
      CREATE TABLE amenities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        capacity INTEGER
      )''');

    batch.execute('''
      CREATE TABLE facility_bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amenity_id INTEGER NOT NULL,
        apartment_id INTEGER,
        date TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        status TEXT DEFAULT 'booked',
        FOREIGN KEY (amenity_id) REFERENCES amenities (id) ON DELETE CASCADE,
        FOREIGN KEY (apartment_id) REFERENCES apartments (id) ON DELETE SET NULL
      )''');

    // ---------------- Notices / events ----------------
    batch.execute('''
      CREATE TABLE notices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        date TEXT DEFAULT CURRENT_TIMESTAMP,
        priority TEXT DEFAULT 'normal'
      )''');

    batch.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        date TEXT,
        venue TEXT
      )''');

    // ---------------- Vendors / staff ----------------
    batch.execute('''
      CREATE TABLE vendors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        phone TEXT,
        email TEXT
      )''');

    batch.execute('''
      CREATE TABLE vendor_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendor_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (vendor_id) REFERENCES vendors (id) ON DELETE CASCADE
      )''');

    batch.execute('''
      CREATE TABLE staff (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT,
        phone TEXT,
        salary REAL,
        join_date TEXT
      )''');

    batch.execute('''
      CREATE TABLE staff_attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        staff_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT DEFAULT 'present',
        FOREIGN KEY (staff_id) REFERENCES staff (id) ON DELETE CASCADE
      )''');

    // ---------------- Assets ----------------
    batch.execute('''
      CREATE TABLE assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        purchase_date TEXT,
        value REAL,
        location TEXT
      )''');

    batch.execute('''
      CREATE TABLE asset_maintenance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        cost REAL,
        FOREIGN KEY (asset_id) REFERENCES assets (id) ON DELETE CASCADE
      )''');

    // ---------------- Documents ----------------
    batch.execute('''
      CREATE TABLE documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT,
        file_path TEXT,
        upload_date TEXT DEFAULT CURRENT_TIMESTAMP
      )''');

    // ---------------- Users / roles / audit ----------------
    batch.execute('''
      CREATE TABLE roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )''');

    batch.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        pin_hash TEXT NOT NULL,
        role TEXT DEFAULT 'admin',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )''');

    batch.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        entity TEXT,
        entity_id INTEGER,
        user_id INTEGER,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP
      )''');

    await batch.commit(noResult: true);
    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(Database db) async {
    await db.insert('roles', {'name': 'admin'});
    await db.insert('roles', {'name': 'manager'});
    await db.insert('roles', {'name': 'staff'});

    for (final c in ['General', 'Water', 'Electricity', 'Security', 'Cleaning', 'Sinking Fund']) {
      await db.insert('maintenance_categories', {'name': c});
    }
    for (final c in ['Utilities', 'Repairs', 'Salaries', 'Security', 'Housekeeping', 'Landscaping', 'Misc']) {
      await db.insert('expense_categories', {'name': c});
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migrations here as dbVersion increases.
  }

  Future<void> logAction(String action, {String? entity, int? entityId}) async {
    final db = await database;
    await db.insert('audit_logs', {
      'action': action,
      'entity': entity,
      'entity_id': entityId,
    });
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
