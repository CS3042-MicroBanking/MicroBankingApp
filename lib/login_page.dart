import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:micro_banking_app/management_page.dart';
import 'package:micro_banking_app/customer_page.dart';
import 'package:micro_banking_app/database_helper.dart';
import 'package:micro_banking_app/specialReq.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'globals.dart' as gl;

DatabaseHelper databaseHelper = DatabaseHelper();
final dbRef = FirebaseDatabase.instance.reference();

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _unameController = TextEditingController();
  final _pwdController = TextEditingController();
  final _accController = TextEditingController();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool initiated = false;
  bool specialRequest = false;
  int count = 0;
  String agentID;
  Map<String, dynamic> acc;

  @override
  void initState() {
    super.initState();
    setAgentID();
    _getToken();
    _configureFirebaseListeners();
    startWorkManager();
    // databaseHelper.encryptLocalPwds();
    // databaseHelper.emptyAccountTable();

    /**
     * Statuses and corresponding meaning
     * 
     * 0                      // default
     * a-{agent_id}-{acc_id}  // get acc_id data from central db
     * b-{agent_id}-{acc_id}  // remove account with acc_id from local db
     * c-{agent_id}-{acc_id}  // update central db with acc_id balance from local db
     * u                      // update central db with all data
     * o-{acc_id}             // operating at the moment
     * fc-{acc_id}            // finished 'c' action
     * 
     */
  }

  @override
  Widget build(BuildContext context) {
    if (!initiated) {
      initializeDB();
      initiated = true;
    }
    return Scaffold(
        appBar: AppBar(
          title: Text("Login"),
        ),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              TextField(
                controller: _unameController,
                decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0))),
              ),
              TextField(
                controller: _pwdController,
                obscuringCharacter: '•',
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0))),
              ),
              Row(
                children: [
                  Text("Special Request "),
                  Checkbox(
                    onChanged: (val) {
                      setState(() {
                        specialRequest = val;
                      });
                    },
                    value: specialRequest,
                  ),
                ],
              ),
              if (specialRequest)
                TextField(
                  controller: _accController,
                  decoration: InputDecoration(
                      labelText: 'Account ID',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0))),
                ),
              RaisedButton(
                onPressed: () {
                  var user = databaseHelper.getUserMap(_unameController.text);
                  user.then((usr) {
                    if (!specialRequest) {
                      var pwd = databaseHelper.encryptPwd(_pwdController.text);
                      pwd.then((password) {
                        if (usr[0]['password'] == password) {
                          _accController.clear();
                          _pwdController.clear();
                          _unameController.clear();
                          if (usr[0]['type'] == 'management') {
                            navigateToManagementPage(usr[0]['uname']);
                          } else {
                            navigateToCustomerPage(usr[0]['uname']);
                          }
                        }
                      });
                    } else {
                      var check = databaseHelper.checkPwdCentralDB(
                          _unameController.text, _pwdController.text);
                      check.then((correct) {
                        if (correct == '0') {
                          var id = databaseHelper
                              .getUserAgentCentralDB(_unameController.text);
                          id.then((agentID) {
                            updateStatus("c-$agentID-" + _accController.text);
                            var res = waitWhile(_accController.text);
                            res.then((result) {
                              var balance =
                                  databaseHelper.getBalanceAndMinCentralDB(
                                      _accController.text);
                              balance.then((val) {
                                if (val != "failed") {
                                  print(val);
                                  var items = val.split(',');
                                  if (items.length == 2) {
                                    navigateToSpecialReqPage(
                                        _accController.text,
                                        double.parse(items[0]),
                                        double.parse(items[1]),
                                        agentID);
                                    _accController.clear();
                                    _pwdController.clear();
                                    _unameController.clear();
                                  } else
                                    print("Something wrong");
                                } else {
                                  print("account unavailable");
                                }
                              });
                            });
                          });
                        } else
                          print("password incorrect");
                      });
                    }
                  });
                },
                child: Text("Log In"),
              )
            ],
          ),
        ));
  }

  _getToken() {
    _firebaseMessaging.getToken().then((deviceToken) {
      print("Device Token: $deviceToken");
      dbRef
          .child("DeviceTokens")
          .child(deviceToken)
          .set({"token": deviceToken});
    });
  }

  _configureFirebaseListeners() {
    _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
      gl.status = message['data']['message'];
      statusHandler(gl.status);
      print("onMessage: $message");
    });
  }

  void statusHandler(String status) {
    String char = status[0];
    switch (char) {
      case 'a':
        {
          var items = status.split('-');
          if (items[1] == agentID) {
            // update local acc_id data from central db
            var res = databaseHelper.getAccCentralDB(items[2]);
            res.then((result) {
              updateStatus("0");
              print(result);
              double balance;
              try {
                balance = double.parse(result.split(",")[0]);
              } catch (error) {
                print("Something wrong");
              }
              databaseHelper.updateAccountTo(int.parse(items[2]), balance);
            });
          }
        }
        break;

      case 'b':
        {
          var items = status.split('-');
          if (items[1] == agentID) {
            // remove account with acc_id from local db
            databaseHelper.deleteAccount(items[2]);
            updateStatus("0");
          }
        }
        break;

      case 'c':
        {
          var items = status.split('-');
          if (items[1] == agentID) {
            // update central db with local acc_id data
            updateStatus("o-" + items[2]);
            var res = databaseHelper.updateAccCentralDBPeriodic(items[2]);
            res.then((result) {
              updateStatus("fc-" + items[2]);
            });
          }
        }
        break;

      case 'u':
        {
          // update central db with all data
          updateStatus("o");
          var res = databaseHelper.updateAllCentralDB();
          res.then((result) {
            updateStatus("0");
          });
        }
    }
  }

  Future waitWhile(String accID, [Duration pollInterval = Duration.zero]) {
    var completer = new Completer();
    check() {
      if (gl.status == 'fc-' + accID) {
        print("completed");
        completer.complete();
      } else {
        new Timer(pollInterval, check);
      }
    }

    check();
    return completer.future;
  }

  void setAgentID() {
    var prefs = SharedPreferences.getInstance();
    prefs.then((pref) {
      // pref.remove('agent_id');
      String id = pref.getString('agent_id');
      if (id == null) {
        var agID = databaseHelper.insertAgentCentralDB("name");
        agID.then((ag) {
          agentID = ag;
          pref.setString('agent_id', ag);
          print(ag);
        });
      } else {
        agentID = id;
      }
      print(agentID);
    });
  }

  void startWorkManager() async {
    var prefs = SharedPreferences.getInstance();
    prefs.then((pref) {
      bool started = pref.getBool('started');
      if (started == null) {
        Workmanager.initialize(callbackDispatcher);
        Workmanager.registerPeriodicTask("1", "update",
            frequency: Duration(hours: 730));
        pref.setBool('started', true);
      }
    });
  }

  void navigateToManagementPage(String uname) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ManagementPage(
        uname: uname,
      );
    }));
  }

  void navigateToCustomerPage(String uname) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return CustomerPage(
        uname: uname,
      );
    }));
  }

  void navigateToSpecialReqPage(
      String accID, double balance, double min, String agentID) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return SpecialReq(
        accID: accID,
        balance: balance,
        min: min,
        agentID: agentID,
      );
    }));
  }

  void initializeDB() {
    final Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) {
      setState(() {});
    });
  }
}

void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    updateStatus('o');
    await databaseHelper.updateAllCentralDB();
    updateStatus('0');
    print("Updated");
    return Future.value(true);
  });
}

void updateStatus(String status) {
  dbRef.update({"status": status});
  gl.status = status;
  var prefs = SharedPreferences.getInstance();
  prefs.then((pref) {
    pref.setInt("trxnNum", 0);
  });
}
