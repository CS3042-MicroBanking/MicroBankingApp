import 'package:flutter/material.dart';
import 'package:micro_banking_app/database_helper.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  List<Map<String, dynamic>> interests;
  List<Map<String, dynamic>> users;
  DatabaseHelper databaseHelper = DatabaseHelper();
  String _selectedAccountType;
  List<String> typeList = [];
  Set<String> userList = {};
  List<double> mins;
  final _balanceTextController = TextEditingController();
  final _unameTextController = TextEditingController();
  final _jUnameTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (interests == null) {
      print("Loading interest rates");
      var interestRates = databaseHelper.getInterestMapList();
      interestRates.then((ints) {
        interests = ints;
        setState(() {});
      });
      print("Loading users");
      var userSet = databaseHelper.getUserMapList();
      userSet.then((usrs) {
        users = usrs;
        for (var i in users) {
          userList.add(i['uname']);
        }
        setState(() {});
      });
    }
    return Scaffold(
        appBar: AppBar(
          title: Text("Create Account"),
        ),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                      padding: EdgeInsets.all(10),
                      child: Text("Account type:")),
                  getInterestsDropDownButton()
                ],
              ),
              TextField(
                controller: _unameTextController,
                decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0))),
              ),
              if (_selectedAccountType == 'joint')
                TextField(
                  controller: _jUnameTextController,
                  decoration: InputDecoration(
                      labelText: 'Username 2',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0))),
                ),
              Row(children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: _balanceTextController,
                    decoration: InputDecoration(
                        labelText: 'Deposit',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0))),
                  ),
                ),
                if (_selectedAccountType != null)
                  Padding(
                      padding: EdgeInsets.all(10),
                      child: Text("Min: " +
                          mins[typeList.indexOf(_selectedAccountType)]
                              .toString()))
              ]),
              RaisedButton(
                onPressed: () {
                  double min = mins[typeList.indexOf(_selectedAccountType)];
                  double balance;
                  try {
                    balance = double.parse(_balanceTextController.text);
                  } catch (error) {
                    print("Balance not a double");
                    return;
                  }
                  if (balance > min) {
                    var accIDFuture = databaseHelper.insertAccCentralDB(
                        _unameTextController.text,
                        _selectedAccountType,
                        double.parse(_balanceTextController.text),
                        jUname: _jUnameTextController.text);
                    accIDFuture.then((accID) {
                      print("accID: " + accID);
                      if (_selectedAccountType != 'joint') {
                        var check = databaseHelper.insertAcc(
                            int.parse(accID), _selectedAccountType, balance);
                        check.then((val) {
                          if (!userList.contains(_unameTextController.text)) {
                            var user = databaseHelper
                                .getUserCentralDB(_unameTextController.text);
                            user.then((details) {
                              try {
                                var userDet = details.split(',');
                                var added = databaseHelper.insertUser(
                                    _unameTextController.text,
                                    userDet[0],
                                    userDet[1]);
                                added.then((result) {
                                  databaseHelper.inserUserToAcc(
                                      _unameTextController.text,
                                      int.parse(accID));
                                });
                              } catch (err) {
                                print("Something went wrong: " + err);
                              }
                            });
                          } else
                            databaseHelper.inserUserToAcc(
                                _unameTextController.text, int.parse(accID));
                        });
                      }
                    });
                    Navigator.pop(context);
                  } else {
                    print("Balance insufficient");
                  }
                },
                child: Text("Add account"),
              ),
            ],
          ),
        ));
  }

  Widget getInterestsDropDownButton() {
    if (typeList.length == 0) {
      typeList = [];
      mins = [];
      if (interests == null) {
        return SizedBox.shrink();
      }
      for (var i in interests) {
        typeList.add(i['acc_type']);
        mins.add(i['min']);
      }
    }

    return new DropdownButton<String>(
      hint: Text("Choose account type"),
      value: _selectedAccountType,
      items: typeList.map((String value) {
        return new DropdownMenuItem<String>(
          value: value,
          child: new Text(value),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedAccountType = val;
        });
      },
    );
  }
}
