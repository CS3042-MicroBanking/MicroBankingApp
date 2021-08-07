import 'package:flutter/material.dart';
import 'package:micro_banking_app/create_account.dart';
import 'package:micro_banking_app/create_fd_account.dart';
import 'package:micro_banking_app/delete_account.dart';
import 'package:micro_banking_app/read_reports.dart';

class ManagementPage extends StatefulWidget {
  final String uname;
  ManagementPage({Key key, @required this.uname}) : super(key: key);
  @override
  _ManagementPageState createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, " + widget.uname),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RaisedButton(
            onPressed: navigateToCreateAccount,
            child: Text("Create Savings Account"),
          ),
          RaisedButton(
            onPressed: navigateToCreateFDAccount,
            child: Text("Create FD Account"),
          ),
          RaisedButton(
            onPressed: navigateToDeleteAccount,
            child: Text("Delete Account"),
          ),
          RaisedButton(
            onPressed: navigateToReadReport,
            child: Text("Read Reports"),
          ),
        ],
      ),
    );
  }

  void navigateToCreateAccount() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return CreateAccount();
    }));
  }

  void navigateToCreateFDAccount() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return CreateFDAccount();
    }));
  }

  void navigateToDeleteAccount() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return DeleteAccount();
    }));
  }

  void navigateToReadReport() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ReadReports();
    }));
  }
}
