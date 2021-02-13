import 'package:flutter/material.dart';
import 'package:micro_banking_app/database_helper.dart';

class DeleteAccount extends StatefulWidget {
  @override
  _DeleteAccountState createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  String _selectedAccount;
  List<int> accList = [];
  List<Map<String, dynamic>> accounts;

  @override
  Widget build(BuildContext context) {
    if (accounts == null) {
      print("Loading Accounts");
      var accs = databaseHelper.getAccountMapList();
      accs.then((accnts) {
        accounts = accnts;
        setState(() {});
      });
    }

    return Scaffold(
        appBar: AppBar(
          title: Text("Delete Account"),
        ),
        body: Padding(
            padding: EdgeInsets.all(10),
            child: Column(children: [
              Row(
                children: [
                  Padding(
                      padding: EdgeInsets.all(10), child: Text("Account id:")),
                  getAccountDropDownButton()
                ],
              ),
              RaisedButton(
                onPressed: () {
                  if (_selectedAccount != null) {
                    var res = databaseHelper
                        .deleteUserToAcc(int.parse(_selectedAccount));
                    res.then((_) {
                      var res1 = databaseHelper
                          .deleteAccount(int.parse(_selectedAccount));
                      res1.then((_) {
                        setState(() {
                          Navigator.pop(context, true);
                          _selectedAccount = null;
                        });
                      });
                    });
                  }
                },
                child: Text("Delete"),
              )
            ])));
  }

  Widget getAccountDropDownButton() {
    if (accList.length == 0) {
      accList = [];
      if (accounts == null) {
        return SizedBox.shrink();
      }
      for (var i in accounts) {
        accList.add(i['acc_id']);
      }
    }

    return new DropdownButton<String>(
      hint: Text("Choose account id"),
      value: _selectedAccount,
      items: accList.map((int value) {
        return new DropdownMenuItem<String>(
          value: value.toString(),
          child: new Text(value.toString()),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedAccount = val;
        });
      },
    );
  }
}
