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
  String _selectedUser;
  String _selectedJUser;
  List<String> typeList = [];
  List<String> userList = [];
  List<double> mins;
  final _balanceTextController = TextEditingController();

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
              Row(
                children: [
                  Padding(
                      padding: EdgeInsets.all(10), child: Text("Username:")),
                  getUsersDropDownButton(false)
                ],
              ),
              if (_selectedAccountType == 'joint')
                Row(
                  children: [
                    Padding(
                        padding: EdgeInsets.all(10),
                        child: Text("Joint username:")),
                    getUsersDropDownButton(true)
                  ],
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
                  if (double.parse(_balanceTextController.text) > min) {
                    var res = databaseHelper.insertAcc(_selectedAccountType,
                        double.parse(_balanceTextController.text));
                    res.then((id) {
                      var res1 =
                          databaseHelper.inserUserToAcc(_selectedUser, id);
                      res1.then((res_0) {}).catchError((e) {
                        print("error: " + e.toString());
                      });
                      print("your account id is " + id.toString());
                      _balanceTextController.clear();
                      _selectedUser = null;
                      if (_selectedAccountType == 'joint') {
                        databaseHelper.inserUserToAcc(_selectedJUser, id);
                        _selectedJUser = null;
                      }
                    }).catchError((e) {
                      print("error: " + e.toString());
                    });
                  }
                  databaseHelper.insertAccCentralDB(
                      _selectedUser,
                      _selectedAccountType,
                      double.parse(_balanceTextController.text));
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

  Widget getUsersDropDownButton(bool isJoin) {
    if (userList.length == 0) {
      userList = [];
      if (users == null) {
        return SizedBox.shrink();
      }
      for (var i in users) {
        userList.add(i['uname']);
      }
    }

    return new DropdownButton<String>(
      hint: Text(isJoin ? "Choose joint user" : "Choose user"),
      value: isJoin ? _selectedJUser : _selectedUser,
      items: userList.map((String value) {
        return new DropdownMenuItem<String>(
          value: value,
          child: new Text(value),
        );
      }).toList(),
      onChanged: (val) {
        if (_selectedUser != val) {
          setState(() {
            if (isJoin)
              _selectedJUser = val;
            else
              _selectedUser = val;
          });
        }
      },
    );
  }
}
