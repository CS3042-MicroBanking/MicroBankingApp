import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

class DatabaseHelper {
  static DatabaseHelper _databaseHelper;
  static Database _database;
  DatabaseHelper._createInstance();

  String userTable = "user";
  String userToAccTable = "user_to_acc";
  String logTable = "log";
  String accTable = "acc";
  String interestTable = "interest_rates";
  String fdPlanTable = "fd_plan";

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
        "CREATE TABLE $accTable (acc_id INTEGER PRIMARY KEY, acc_type TEXT, balance REAL, FOREIGN KEY (acc_type) REFERENCES $interestTable(acc_type))");
    await db.execute(
        "CREATE TABLE $userToAccTable (uname TEXT, acc_id INTEGER, PRIMARY KEY (uname, acc_id), FOREIGN KEY (uname) REFERENCES $userTable(uname), FOREIGN KEY (acc_id) REFERENCES $accTable(acc_id))");
    await db.execute(
        "CREATE TABLE $logTable (trxn_id INTEGER PRIMARY KEY AUTOINCREMENT, acc_id INTEGER, amount REAL, datetime TEXT)");
    await db.execute(
        "CREATE TABLE $fdPlanTable (period INTEGER PRIMARY KEY, interest REAL)");

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

    // FD plans
    await db.insert(fdPlanTable, {'period': 6, 'interest': 13});
    await db.insert(fdPlanTable, {'period': 12, 'interest': 14});
    await db.insert(fdPlanTable, {'period': 36, 'interest': 15});

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

    // TRIGGERS
    await db.execute(
        "CREATE TRIGGER IF NOT EXISTS trxn_trig AFTER UPDATE ON $accTable " +
            "BEGIN " +
            "INSERT INTO $logTable (acc_id, amount, datetime) VALUES (old.acc_id, new.balance - old.balance, strftime('%Y-%m-%d %H:%M:%S', datetime('now')));" +
            "END;");

    await db.execute(
        "CREATE TRIGGER IF NOT EXISTS user_to_acc_del_trig BEFORE DELETE ON $accTable " +
            "BEGIN " +
            "DELETE FROM $userToAccTable WHERE acc_id = OLD.acc_id;" +
            "DELETE FROM $logTable WHERE acc_id = OLD.acc_id;"
                "END;");

    // INDEX
    await db.execute("CREATE UNIQUE INDEX uname_idx ON $userTable (uname);");
  }

  Future<int> insertAcc(int accID, String accType, double balance) async {
    Database db = await this.database;
    return await db.insert(
        accTable, {'acc_id': accID, 'acc_type': accType, 'balance': balance});
  }

  Future<int> insertUser(String uname, String name, String password,
      {String type = "customer"}) async {
    Database db = await this.database;
    return await db.insert(userTable,
        {'uname': uname, 'name': name, 'password': password, 'type': type});
  }

  Future<String> insertAccCentralDB(
      String uname, String accType, double balance,
      {String jUname = ''}) async {
    final response = await http
        .post("http://moorish-seat.000webhostapp.com/insertAccount.php", body: {
      "uname": uname,
      "acc_type": accType,
      "balance": balance.toString(),
      "j_uname": jUname
    });
    return response.body;
  }

  Future<String> insertAgentCentralDB(String name) async {
    final response = await http
        .post("http://moorish-seat.000webhostapp.com/insertAgent.php", body: {
      "name": name,
    });
    return response.body;
  }

  Future<String> insertLogCentralDB(
      String accID, String amount, String timestamp) async {
    final response = await http.post(
        "http://moorish-seat.000webhostapp.com/insertLog.php",
        body: {"acc_id": accID, "amount": amount, "timestamp": timestamp});
    return response.body;
  }

  Future<String> insertUserToAccCentralDB(String uname, String accID) async {
    final response = await http.post(
        "http://moorish-seat.000webhostapp.com/insertUserToAcc.php",
        body: {
          "uname": uname,
          "acc_id": accID,
        });
    return response.body;
  }

  Future<String> insertFDAccCentralDB(
      String balance, String accID, String period) async {
    final response = await http.post(
        "http://moorish-seat.000webhostapp.com/insertFDAccount.php",
        body: {'acc_id': accID, 'balance': balance, 'period': period});
    return response.body;
  }

  Future<String> getStatusCentralServer() async {
    final response =
        await http.post("http://moorish-seat.000webhostapp.com/status.txt");
    return response.body;
  }

  Future<String> getAccCentralDB(String accID) async {
    final response = await http
        .post("http://moorish-seat.000webhostapp.com/getAccount.php", body: {
      "acc_id": accID,
    });
    return response.body;
  }

  Future<String> getUserCentralDB(String uname) async {
    final response = await http
        .post("http://moorish-seat.000webhostapp.com/getUser.php", body: {
      "uname": uname,
    });
    return response.body;
  }

  Future<String> getLogCentralDB() async {
    final response =
        await http.post("http://moorish-seat.000webhostapp.com/getLog.php");
    return response.body;
  }

  Future<String> getUserAgentCentralDB(String uname) async {
    final response = await http
        .post("http://moorish-seat.000webhostapp.com/getUserAgent.php", body: {
      "uname": uname,
    });
    return response.body;
  }

  Future<String> getAccAgentCentralDB(String accID) async {
    final response = await http
        .post("http://moorish-seat.000webhostapp.com/getAccAgent.php", body: {
      "acc_id": accID,
    });
    return response.body;
  }

  Future<String> deleteAccCentralDB(String accID) async {
    final response = await http
        .post("http://moorish-seat.000webhostapp.com/deleteAccount.php", body: {
      "acc_id": accID,
    });
    return response.body;
  }

  Future<String> updateAccCentralDB(String accID, double amount) async {
    final response = await http
        .post("http://moorish-seat.000webhostapp.com/updateAccount.php", body: {
      "acc_id": accID,
      "amount": amount.toString(),
      "periodic": 'false'
    });
    print("Updated Central DB account for accID: $accID by amount: $amount");
    return response.body;
  }

  Future<String> updateAccCentralDBPeriodic(String accID,
      {double balance}) async {
    Database db = await this.database;
    if (balance == null) {
      var bal =
          (await db.query(accTable, where: "acc_id = ?", whereArgs: [accID]))[0]
              ['balance'];
      if (bal is double) {
        balance = bal;
      } else {
        print("Something wrong");
        return null;
      }
    }
    print("acc_id: $accID, amount: $balance");
    final response = await http
        .post("http://moorish-seat.000webhostapp.com/updateAccount.php", body: {
      "acc_id": accID,
      "amount": balance.toString(),
      "periodic": 'true'
    });
    return response.body;
  }

  Future<String> updateAllCentralDB() async {
    var accounts = await getAccountMapList();
    String res;
    for (var acc in accounts) {
      res = await updateAccCentralDBPeriodic(acc['acc_id'],
          balance: acc['balance']);
    }
    Database db = await this.database;
    var logs = await db.query(logTable);
    for (var log in logs) {
      insertLogCentralDB(
          log['acc_id'].toString(), log['amount'].toString(), log['datetime']);
    }
    return res;
  }

  Future<String> checkPwdCentralDB(String uname, String pwd) async {
    final response = await http.post(
        "http://moorish-seat.000webhostapp.com/checkPwd.php",
        body: {"uname": uname, "pwd": pwd});
    return response.body;
  }

  Future<String> encryptPwd(String pwd) async {
    final response = await http.post(
        "http://moorish-seat.000webhostapp.com/encryptPwd.php",
        body: {"pwd": pwd});
    return response.body;
  }

  void encryptLocalPwds() async {
    Database db = await this.database;
    var users = await db.query(userTable);
    Map<String, String> pwds = {
      'ross123': '87f9c39b9e3f358174d58a584c2727b4',
      'chan123': '61532745cddbf89676ce3844ac091721',
      'joey123': 'f1998b83278879af72f0cebf0fb0a3aa',
      'rach123': '14b5b099098de0c68164ad2eeec35409',
      'phoebe123': '5a7c5156c0f64867b607abf66f3bbe1f',
      'mon123': '4c85b3625c95b8bf313d47934599eef5'
    };
    for (var user in users) {
      String encPwd = pwds[user['uname']];
      db.update(userTable, {'password': encPwd},
          where: 'uname = ?', whereArgs: [user['uname']]);
    }
  }

  Future<String> getBalanceAndMinCentralDB(String accID) async {
    final response = await http.post(
        "http://moorish-seat.000webhostapp.com/getAccBalanceMin.php",
        body: {"acc_id": accID});
    return response.body;
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

  Future<List<Map<String, dynamic>>> getFDPlanMapList() async {
    Database db = await this.database;
    return await db.query(fdPlanTable);
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

  Future<List<Map<String, dynamic>>> getMinAccBalance(String accType) async {
    Database db = await this.database;
    return await db
        .query(interestTable, where: 'acc_type = ?', whereArgs: [accType]);
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

  Future<int> deleteAccount(String id) async {
    Database db = await this.database;
    return await db.delete(accTable, where: 'acc_id = ?', whereArgs: [id]);
  }

  Future<int> deleteUserToAcc(int id) async {
    Database db = await this.database;
    return await db
        .delete(userToAccTable, where: 'acc_id = ?', whereArgs: [id]);
  }

  Future<int> updateAccountBy(int id, double change) async {
    Database db = await this.database;
    int updateCount = 30;
    double balance = (await db
        .query(accTable, where: 'acc_id = ?', whereArgs: [id]))[0]['balance'];
    print("Updating account ID $id by $change");
    var res = await db.update(accTable, {'balance': balance + change},
        where: 'acc_id = ?', whereArgs: [id]);

    // check for all update
    var prefs = await SharedPreferences.getInstance();
    int n = prefs.getInt("trxnNum");
    if (n == null) {
      prefs.setInt("trxnNum", 0);
      n = 0;
    }
    n += 1;
    if (n >= updateCount) {
      updateAllCentralDB();
      Workmanager.cancelAll();
      Workmanager.registerPeriodicTask("1", "update",
          frequency: Duration(hours: 730));
    }
    return res;
  }

  Future<int> updateAccountTo(int id, double balance) async {
    Database db = await this.database;
    int updateCount = 30;
    print("Updating account ID $id to $balance");
    var res = await db.update(accTable, {'balance': balance},
        where: 'acc_id = ?', whereArgs: [id]);

    // check for all update
    var prefs = await SharedPreferences.getInstance();
    int n = prefs.getInt("trxnNum");
    if (n == null) {
      prefs.setInt("trxnNum", 0);
      n = 0;
    }
    n += 1;
    if (n >= updateCount) {
      updateAllCentralDB();
      Workmanager.cancelAll();
      Workmanager.registerPeriodicTask("1", "update",
          frequency: Duration(hours: 730));
    }
    return res;
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

  void emptyAccountTable() async {
    Database db = await this.database;
    db.execute(
        "CREATE TRIGGER IF NOT EXISTS acc_del_ BEFORE DELETE ON $accTable " +
            "BEGIN " +
            "DELETE FROM $logTable WHERE acc_id = OLD.acc_id;" +
            "END;");
    var n = await db.delete(accTable);
    print("$n rows affected");
  }
}
