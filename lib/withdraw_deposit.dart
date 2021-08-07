import 'package:flutter/material.dart';
import 'package:micro_banking_app/database_helper.dart';
import 'package:micro_banking_app/globals.dart' as gl;

class WithdrawDeposit extends StatefulWidget {
  final String uname;
  WithdrawDeposit({Key key, @required this.uname}) : super(key: key);
  @override
  _WithdrawDepositState createState() => _WithdrawDepositState();
}

class _WithdrawDepositState extends State<WithdrawDeposit> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  Map<String, dynamic> accMap = Map();
  List<Map<String, dynamic>> accs;
  final _amountTextController = TextEditingController();
  final _accountTextController = TextEditingController();
  String _selectedAccount;
  bool isJoint = false;
  double jointBalance = 0;

  @override
  Widget build(BuildContext context) {
    if (accs == null) {
      var res = databaseHelper.getUserAccList(widget.uname);
      res.then((accounts) {
        accs = accounts;
        for (var i in accounts) {
          accMap[i['acc_id'].toString()] = Map.of(i);
        }
        setState(() {});
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Withdraw/Deposit'),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Text("Joint "),
                Checkbox(
                  onChanged: (val) {
                    setState(() {
                      isJoint = val;
                    });
                  },
                  value: isJoint,
                ),
              ],
            ),
            TextField(
              keyboardType: TextInputType.number,
              onChanged: (id) {
                setState(() {
                  _selectedAccount = id;
                  if (isJoint) getBalance(id);
                });
              },
              controller: _accountTextController,
              decoration: InputDecoration(
                  labelText: 'Account',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0))),
            ),
            Row(children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: _amountTextController,
                  decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0))),
                ),
              ),
              if (_selectedAccount != null &&
                  (isJoint || accMap.containsKey(_selectedAccount)))
                Padding(
                    padding: EdgeInsets.all(10),
                    child: isJoint
                        ? Text("Balance: " + jointBalance.toString())
                        : Text("Balance: " +
                            accMap[_selectedAccount]['balance'].toString() +
                            ", Min: " +
                            accMap[_selectedAccount]['min'].toString()))
            ]),
            Row(
              children: [
                RaisedButton(
                  onPressed: () {
                    if (gl.status == 'fc-' + _accountTextController.text ||
                        gl.status == 'o-' + _accountTextController.text) {
                      print("Account currently in use");
                    }
                    double change = double.parse(_amountTextController.text);
                    if (isJoint) {
                      if (jointBalance - change >= 5000) {
                        var response = databaseHelper.updateAccCentralDB(
                            _selectedAccount, -change);
                        response.then((res) {
                          print("Response: " + res);
                        });
                      } else
                        print("Insufficient Balance");
                    } else if (accMap[_selectedAccount]['balance'] - change >=
                        accMap[_selectedAccount]['min']) {
                      var res = databaseHelper.updateAccountBy(
                          int.parse(_selectedAccount), -change);
                      res.then((_) {
                        setState(() {
                          accMap[_selectedAccount]['balance'] -= change;
                        });
                      });
                    } else
                      print("Insufficient Balance");
                    Navigator.pop(context);
                  },
                  child: Text("Withdraw"),
                ),
                RaisedButton(
                  onPressed: () {
                    /*if (gl.status == 'o-' + _accountTextController.text) {
                      print(
                          "Account being used elsewhere. Please return to previous screen");
                    }*/
                    double change = double.parse(_amountTextController.text);
                    if (isJoint) {
                      var response = databaseHelper.updateAccCentralDB(
                          _selectedAccount, change);
                      response.then((res) {
                        print("Response: " + res);
                      });
                    } else {
                      var res = databaseHelper.updateAccountBy(
                          int.parse(_selectedAccount), change);
                      res.then((_) {
                        setState(() {
                          accMap[_selectedAccount]['balance'] += change;
                        });
                      });
                    }
                    Navigator.pop(context);
                  },
                  child: Text("Deposit"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void getBalance(String accID) {
    var res = databaseHelper.getAccCentralDB(accID);
    res.then((result) {
      print(result);
      if (result != "account not found") {
        setState(() {
          if (result.split(",")[1] == "joint")
            jointBalance = double.parse(result.split(",")[0]);
          else
            jointBalance = 0;
        });
      } else {
        jointBalance = 0;
      }
    });
  }
}
