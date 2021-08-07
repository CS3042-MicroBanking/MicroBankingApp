import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:micro_banking_app/database_helper.dart';
import 'globals.dart' as gl;

class DeleteAccount extends StatefulWidget {
  @override
  _DeleteAccountState createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<int> accList = [];
  List<Map<String, dynamic>> accounts;
  final _accTextController = TextEditingController();
  final dbRef = FirebaseDatabase.instance.reference();

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
              TextField(
                controller: _accTextController,
                decoration: InputDecoration(
                    labelText: 'Account ID',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0))),
              ),
              RaisedButton(
                onPressed: () {
                  if (_accTextController.text != null) {
                    var deleteStatus = databaseHelper
                        .deleteAccCentralDB(_accTextController.text);
                    deleteStatus.then((status) {
                      if (status != '0') {
                        print("Deletion failed");
                        return;
                      }
                    });
                    var res = waitWhile();
                    res.then((result) {
                      var id = databaseHelper
                          .getAccAgentCentralDB(_accTextController.text);
                      id.then((agentID) {
                        String status = "b-$agentID-" + _accTextController.text;
                        dbRef.update({"status": status});
                        gl.status = status;
                        Navigator.pop(context);
                      });
                    });
                  }
                },
                child: Text("Delete"),
              )
            ])));
  }

  Future waitWhile([Duration pollInterval = Duration.zero]) {
    var completer = new Completer();
    check() {
      if (gl.status == '0') {
        print("completed");
        completer.complete();
      } else {
        new Timer(pollInterval, check);
      }
    }

    check();
    return completer.future;
  }
}
