import 'package:flutter/material.dart';
import 'package:micro_banking_app/database_helper.dart';

class ReadAllReports extends StatefulWidget {
  @override
  _ReadAllReportsState createState() => _ReadAllReportsState();
}

class _ReadAllReportsState extends State<ReadAllReports> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> trxns;

  @override
  Widget build(BuildContext context) {
    if (trxns == null) {
      var trxnSet = databaseHelper.getLogMapList();
      trxnSet.then((trns) {
        trxns = trns;
        setState(() {});
      });
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Read All Reports"),
      ),
      body: trxns != null
          ? ListView.builder(
              itemCount: trxns.length,
              itemBuilder: (_, int position) {
                return Card(
                  child: Column(
                    children: [
                      Text("Account ID: " +
                          trxns[position]['acc_id'].toString()),
                      Text("Transaction ID: " +
                          trxns[position]['trxn_id'].toString()),
                      // Text("Type: " + trxns[position]['type']),
                      Text("Amount: " + trxns[position]['amount'].toString()),
                      Text("Date Time: " + trxns[position]['datetime'])
                    ],
                  ),
                );
              },
            )
          : SizedBox.shrink(),
    );
  }
}
