import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DatabaseHelper {
  static DatabaseHelper _databaseHelper;
  static Database _database;
  DatabaseHelper._createInstance();

  String userTable = "user";
  String userToAccTable = "user_to_acc";
  String logTable = "log";
  String accTable = "acc";
  String interestTable = "interest_rates";

  factory DatabaseHelper() {
    if (_databaseHelper == null) {
      _databaseHelper = DatabaseHelper._createInstance();
    }
    return _databaseHelper;
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database;
  }

  // Get Singleton instance of Database
  Future<Database> initializeDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + 'microbank.db';
    var tasksDatabase = await openDatabase(path,
        version: 1, onCreate: _createDb, onConfigure: _onConfigure);
    return tasksDatabase;
  }

  static Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute(
        "CREATE TABLE $userTable (uname TEXT PRIMARY KEY, name TEXT, password TEXT, type TEXT DEFAULT 'customer')");
    await db.execute(
        "CREATE TABLE $interestTable (acc_type TEXT PRIMARY KEY, interest REAL, min REAL DEFAULT 0)");
    await db.execute(
        "CREATE TABLE $accTable (acc_id INTEGER PRIMARY KEY AUTOINCREMENT, acc_type TEXT, balance REAL, FOREIGN KEY (acc_type) REFERENCES $interestTable(acc_type))");
    await db.execute(
        "CREATE TABLE $userToAccTable (uname TEXT, acc_id INTEGER, PRIMARY KEY (uname, acc_id), FOREIGN KEY (uname) REFERENCES $userTable(uname), FOREIGN KEY (acc_id) REFERENCES $accTable(acc_id))");
    await db.execute(
        "CREATE TABLE $logTable (trxn_id INTEGER PRIMARY KEY AUTOINCREMENT, acc_id INTEGER, amount REAL, datetime TEXT, FOREIGN KEY (acc_id) REFERENCES $accTable(acc_id))");

    // Interest rates
    await db.insert(interestTable, {'acc_type': 'children', 'interest': 12});
    await db.insert(
        interestTable, {'acc_type': 'teen', 'interest': 11, 'min': 500});
    await db.insert(
        interestTable, {'acc_type': 'adult', 'interest': 10, 'min': 1000});
    await db.insert(
        interestTable, {'acc_type': 'senior', 'interest': 13, 'min': 1000});
    await db.insert(
        interestTable, {'acc_type': 'joint', 'interest': 7, 'min': 5000});

    // Dummy data for bank managememt
    await db.insert(userTable, {
      'name': 'Ross',
      'uname': 'ross123',
      'password': 'dinosaurs',
      'type': 'management'
    });

    // Dummy data for customers
    await db.insert(userTable, {
      'name': 'Joey Tribbiani',
      'uname': 'joey123',
      'password': 'babykangaroo'
    });
    await db.insert(userTable, {
      'name': 'Chandler Bing',
      'uname': 'chan123',
      'password': 'chanchanman'
    });
    await db.insert(userTable,
        {'name': 'Rachel Greene', 'uname': 'rach123', 'password': 'onabreak'});

    await db.execute(
        "CREATE TRIGGER IF NOT EXISTS trxn_trig AFTER UPDATE ON $accTable " +
            "BEGIN " +
            "INSERT INTO $logTable (acc_id, amount, datetime) VALUES (old.acc_id, new.balance - old.balance, datetime('now'));" +
            "END;");
  }

  Future<int> insertAcc(String accType, double balance) async {
    Database db = await this.database;
    return await db.insert(accTable, {'acc_type': accType, 'balance': balance});
  }

  void insertAccCentralDB(String uname, String accType, double balance) async {
    final response = await http
        .post("http://moorish-seat.000webhostapp.com/insertAccount.php", body: {
      "uname": uname,
      "acc_type": accType,
      "balance": balance.toString(),
    });
    print(response.body);
  }

  Future<int> inserUserToAcc(String uname, int id) async {
    Database db = await this.database;
    return await db.insert(userToAccTable, {'uname': uname, 'acc_id': id});
  }

  Future<List<Map<String, dynamic>>> getUserMap(String uname) async {
    Database db = await this.database;
    return await db.query(userTable, where: 'uname = ?', whereArgs: [uname]);
  }

  Future<List<Map<String, dynamic>>> getInterestMapList() async {
    Database db = await this.database;
    return await db.query(interestTable);
  }

  Future<List<Map<String, dynamic>>> getUserMapList() async {
    Database db = await this.database;
    return await db.query(userTable);
  }

  Future<List<Map<String, dynamic>>> getAccountMapList() async {
    Database db = await this.database;
    return await db.query(accTable);
  }

  Future<List<Map<String, dynamic>>> getAccountLogMapList(String id) async {
    Database db = await this.database;
    return await db.query(logTable, where: 'acc_id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getLogMapList() async {
    Database db = await this.database;
    return await db.query(logTable);
  }

  Future<List<Map<String, dynamic>>> getUserAccList(String uname) async {
    Database db = await this.database;
    return await db.rawQuery(
        "SELECT acc_id, acc_type, balance, min FROM $userToAccTable NATURAL JOIN $accTable NATURAL JOIN $interestTable WHERE uname = '$uname'");
  }

  Future<List<Map<String, dynamic>>> getAccsFromList(
      List<String> accIDs) async {
    Database db = await this.database;
    return await db.query(accTable, where: 'acc_id = ?', whereArgs: accIDs);
  }

  Future<int> deleteAccount(int id) async {
    Database db = await this.database;
    return await db.delete(accTable, where: 'acc_id = ?', whereArgs: [id]);
  }

  Future<int> deleteUserToAcc(int id) async {
    Database db = await this.database;
    return await db
        .delete(userToAccTable, where: 'acc_id = ?', whereArgs: [id]);
  }

  Future<int> updateAccount(int id, double change) async {
    Database db = await this.database;
    double balance = (await db
        .query(accTable, where: 'acc_id = ?', whereArgs: [id]))[0]['balance'];
    return await db.update(accTable, {'balance': balance + change});
  }

  void deleteDB() {
    var db = this.database;
    db.then((datab) {
      datab.close();
      var databasesPath = getDatabasesPath();
      databasesPath.then((dbpath) {
        String path = dbpath + 'microbank.db';
        var x = deleteDatabase(path);
        x.then((res) {});
      });
    });
  }
}
