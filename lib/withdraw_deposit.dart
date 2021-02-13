import 'package:flutter/material.dart';
import 'package:micro_banking_app/database_helper.dart';

class WithdrawDeposit extends StatefulWidget {
  final String uname;
  WithdrawDeposit({Key key, @required this.uname}) : super(key: key);
  @override
  _WithdrawDepositState createState() => _WithdrawDepositState();
}

class _WithdrawDepositState extends State<WithdrawDeposit> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<String> accList = [];
  List<Map<String, dynamic>> accs;
  List<double> balances = [];
  List<double> mins = [];
  final _amountTextController = TextEditingController();
  String _selectedAccount;
  int _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (accs == null) {
      var res = databaseHelper.getUserAccList(widget.uname);
      res.then((accounts) {
        accs = accounts;
        for (var i in accounts) {
          accList.add(i['acc_id'].toString());
          balances.add(i['balance']);
          mins.add(i['min']);
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
                Padding(
                    padding: EdgeInsets.all(10), child: Text("Account ID:")),
                getAccountsDropDownButton()
              ],
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
              if (_selectedAccount != null)
                Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("Balance: " +
                        balances[_selectedIndex].toString() +
                        ", Min: " +
                        mins[_selectedIndex].toString()))
            ]),
            Row(
              children: [
                RaisedButton(
                  onPressed: () {
                    double change = double.parse(_amountTextController.text);
                    if (balances[_selectedIndex] - change >=
                        mins[_selectedIndex]) {
                      var res = databaseHelper.updateAccount(
                          int.parse(_selectedAccount), -change);
                      res.then((_) {
                        setState(() {
                          balances[_selectedIndex] -= change;
                        });
                      });
                    } else
                      print("Insufficient Balance");
                  },
                  child: Text("Withdraw"),
                ),
                RaisedButton(
                  onPressed: () {
                    double change = double.parse(_amountTextController.text);
                    var res = databaseHelper.updateAccount(
                        int.parse(_selectedAccount), change);
                    res.then((_) {
                      setState(() {
                        balances[_selectedIndex] += change;
                      });
                    });
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

  Widget getAccountsDropDownButton() {
    if (accs == null) return SizedBox.shrink();

    return new DropdownButton<String>(
      hint: Text("Choose account"),
      value: _selectedAccount,
      items: accList.map((String value) {
        return new DropdownMenuItem<String>(
          value: value,
          child: new Text(value),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedAccount = val;
          _selectedIndex = _selectedIndex;
        });
      },
    );
  }
}
