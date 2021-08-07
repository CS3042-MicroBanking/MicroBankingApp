import 'package:flutter/material.dart';
import 'package:micro_banking_app/database_helper.dart';

class ReadReports extends StatefulWidget {
  @override
  _ReadReportsState createState() => _ReadReportsState();
}

enum Filteration { all, account, agent }

class _ReadReportsState extends State<ReadReports> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  var _agentController = TextEditingController();
  var _accController = TextEditingController();
  Map<String, List<List<String>>> accWise = Map();
  Map<String, List<List<String>>> agentWise = Map();
  List<List<String>> all = [];
  Filteration mode = Filteration.all;

  @override
  Widget build(BuildContext context) {
    if (accWise.keys.length == 0) {
      var res = databaseHelper.getLogCentralDB();
      res.then((response) {
        var rows = response.split(';');
        print(rows.length);
        for (var i in rows) {
          var cols = i.split(',');
          if (cols.length == 4) {
            all.add(cols);
            if (accWise.containsKey(cols[1])) {
              accWise[cols[1]].add(cols);
            } else {
              accWise[cols[1]] = [cols];
            }
            if (agentWise.containsKey(cols[0])) {
              agentWise[cols[0]].add(cols);
            } else {
              agentWise[cols[0]] = [cols];
            }
          }
        }
        setState(() {});
      });
    }

    return Scaffold(
        appBar: AppBar(
          title: Text("Read Reports"),
        ),
        body: ListView(
          children: [
            Row(
              children: [
                Radio(
                  groupValue: mode,
                  value: Filteration.all,
                  onChanged: (Filteration val) {
                    setState(() {
                      mode = val;
                    });
                  },
                ),
                Text("All")
              ],
            ),
            Row(
              children: [
                Radio(
                  groupValue: mode,
                  value: Filteration.account,
                  onChanged: (Filteration val) {
                    setState(() {
                      mode = val;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _accController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                        labelText: 'Account Number',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0))),
                  ),
                )
              ],
            ),
            Row(
              children: [
                Radio(
                  groupValue: mode,
                  value: Filteration.agent,
                  onChanged: (Filteration val) {
                    setState(() {
                      mode = val;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _agentController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                        labelText: 'Agent Number',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0))),
                  ),
                )
              ],
            ),
            createCards()
          ],
        ));
  }

  Widget createCards() {
    List<List<String>> iter;
    if (mode == Filteration.all)
      iter = all;
    else if (mode == Filteration.account) {
      if (accWise.containsKey(_accController.text))
        iter = accWise[_accController.text];
      else {
        print("Account not found");
      }
    } else {
      if (agentWise.containsKey(_agentController.text))
        iter = agentWise[_agentController.text];
      else {
        print("Account not found");
      }
    }

    return iter != null
        ? Column(
            children: [
              for (var i in iter)
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Column(
                          children: [
                            Text("Agent ID: " + i[0]),
                            Text("Account ID: " + i[1]),
                            Text("Amount: " + i[2]),
                            Text("Time: " + i[3]),
                          ],
                        ),
                      ),
                    )
                  ],
                )
            ],
          )
        : SizedBox.shrink();
  }
}
