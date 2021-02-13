import 'package:flutter/material.dart';
import 'package:micro_banking_app/database_helper.dart';

class ReadAccountReports extends StatefulWidget {
  @override
  _ReadAccountReportsState createState() => _ReadAccountReportsState();
}

class _ReadAccountReportsState extends State<ReadAccountReports> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> trxns;
  List<Map<String, dynamic>> accs;
  List<String> accList = [];
  Map<String, List<dynamic>> accLogs = Map();
  String _selectedAcc;
  bool loaded = false;

  @override
  Widget build(BuildContext context) {
    if (accs == null) {
      var accSet = databaseHelper.getAccountMapList();
      accSet.then((accounts) {
        accs = accounts;
        for (var i in accs) {
          accList.add(i['acc_id'].toString());
          accLogs[i['acc_id'].toString()] = [];
        }
        var logSet = databaseHelper.getLogMapList();
        logSet.then((logs) {
          for (var i in logs) {
            accLogs[i['acc_id'].toString()].add(i);
          }
          setState(() {
            loaded = true;
          });
        });
      });
    }
    return Scaffold(
        appBar: AppBar(
          title: Text("Read Account Reports"),
        ),
        body: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Padding(
                    padding: EdgeInsets.all(10), child: Text("Account ID:")),
                getAccsDropDownButton()
              ],
            ),
            _selectedAcc != null
                ? Column(
                    children: [
                      for (var i in accLogs[_selectedAcc])
                        Card(
                          child:
                              /*Text((i['amount'] < 0
                                    ? "Withdrew"
                                    : "Deposited") +
                                " an amount of " +
                                (i['amount'] < 0
                                    ? (-i['amount']).toString()
                                    : i['amount'].toString()) +
                                " on " +
                                i['datetime'].split(' ')[0] +
                                " at " +
                                i['datetime'].split(' ')[
                                    1])*/
                              Column(
                            children: [
                              Text(
                                  "Transaction ID: " + i['trxn_id'].toString()),
                              Text("Amount: " + i['amount'].toString()),
                              Text("Date Time: " + i['datetime'])
                            ],
                          ),
                        )
                    ],
                  )
                : SizedBox.shrink(),
          ],
        ));
  }

  Widget getAccsDropDownButton() {
    if (!loaded) return SizedBox.shrink();

    return new DropdownButton<String>(
      hint: Text("Choose user"),
      value: _selectedAcc,
      items: accList.map((String value) {
        return new DropdownMenuItem<String>(
          value: value,
          child: new Text(value),
        );
      }).toList(),
      onChanged: (val) {
        if (_selectedAcc != val) {
          setState(() {
            _selectedAcc = val;
          });
        }
      },
    );
  }
}
