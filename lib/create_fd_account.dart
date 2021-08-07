import 'package:flutter/material.dart';
import 'package:micro_banking_app/database_helper.dart';

class CreateFDAccount extends StatefulWidget {
  @override
  _CreateFDAccountState createState() => _CreateFDAccountState();
}

class _CreateFDAccountState extends State<CreateFDAccount> {
  List<Map<String, dynamic>> periods;
  List<Map<String, dynamic>> users;
  DatabaseHelper databaseHelper = DatabaseHelper();
  String _selectedAccountType;
  int _selectedIndex;
  List<String> periodList = [];
  List<String> userList = [];
  List<double> rates;
  final _balanceTextController = TextEditingController();
  final _accTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (periods == null) {
      print("Loading interest rates");
      var periodsFuture = databaseHelper.getFDPlanMapList();
      periodsFuture.then((prds) {
        periods = prds;
        setState(() {});
      });
    }
    return Scaffold(
        appBar: AppBar(
          title: Text("Create FD Account"),
        ),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  Padding(padding: EdgeInsets.all(10), child: Text("Period: ")),
                  getPeriodDropDownButton(),
                ],
              ),
              if (_selectedAccountType != null)
                Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                        "Interest Rate: " + rates[_selectedIndex].toString())),
              TextField(
                controller: _accTextController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Savings Account ID',
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
              ]),
              RaisedButton(
                onPressed: () {
                  try {
                    double.parse(_balanceTextController.text);
                  } catch (error) {
                    print("Balance not a double");
                  }
                  try {
                    var res = databaseHelper.insertFDAccCentralDB(
                        _balanceTextController.text,
                        _accTextController.text,
                        periodList[_selectedIndex]);
                    res.then((result) {
                      print(result);
                      Navigator.pop(context);
                    });
                  } catch (error) {
                    print("Something went wrong");
                  }
                },
                child: Text("Add account"),
              ),
            ],
          ),
        ));
  }

  Widget getPeriodDropDownButton() {
    if (periodList.length == 0) {
      periodList = [];
      rates = [];
      if (periods == null) {
        return SizedBox.shrink();
      }
      for (var i in periods) {
        periodList.add(i['period'].toString());
        rates.add(i['interest']);
      }
    }

    return new DropdownButton<String>(
      hint: Text("Choose account period"),
      value: _selectedAccountType,
      items: periodList.map((String value) {
        return new DropdownMenuItem<String>(
          value: value,
          child: new Text(value),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedAccountType = val;
          _selectedIndex = periodList.indexOf(_selectedAccountType);
        });
      },
    );
  }
}
