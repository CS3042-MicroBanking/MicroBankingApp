import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:micro_banking_app/database_helper.dart';
import 'globals.dart' as gl;

class SpecialReq extends StatefulWidget {
  final double balance;
  final double min;
  final String accID;
  final String agentID;
  SpecialReq(
      {Key key,
      @required this.accID,
      @required this.balance,
      @required this.min,
      @required this.agentID})
      : super(key: key);
  @override
  _SpecialReqState createState() => _SpecialReqState();
}

class _SpecialReqState extends State<SpecialReq> {
  final _amountController = TextEditingController();
  DatabaseHelper databaseHelper = DatabaseHelper();
  double fee = 50;
  final dbRef = FirebaseDatabase.instance.reference();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Special Request"),
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0))),
            ),
            Text("Balance: " +
                widget.balance.toString() +
                "\nMin: " +
                widget.min.toString()),
            RaisedButton(
              onPressed: () {
                if (widget.balance -
                        fee -
                        double.parse(_amountController.text) >=
                    widget.min) {
                  var res = databaseHelper.updateAccCentralDB(widget.accID,
                      -double.parse(_amountController.text) - fee);
                  res.then((result) {
                    String status = "a-" + widget.agentID + "-" + widget.accID;
                    dbRef.update({"status": status});
                    gl.status = status;
                    Navigator.pop(context);
                  });
                } else
                  print("Balance insufficient");
              },
              child: Text("Withdraw"),
            ),
            RaisedButton(
              onPressed: () {
                if (fee < double.parse(_amountController.text)) {
                  var res = databaseHelper.updateAccCentralDB(
                      widget.accID, double.parse(_amountController.text) - fee);
                  res.then((result) {
                    print("Central db update result: $result");
                    String status = "a-" + widget.agentID + "-" + widget.accID;
                    dbRef.update({"status": status});
                    gl.status = status;
                    Navigator.pop(context);
                  });
                } else
                  print("Fee larger than deposit.");
              },
              child: Text("Deposit"),
            ),
          ],
        ),
      ),
    );
  }
}
