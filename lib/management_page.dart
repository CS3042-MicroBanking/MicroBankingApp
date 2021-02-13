import 'package:flutter/material.dart';
import 'package:micro_banking_app/create_account.dart';
import 'package:micro_banking_app/delete_account.dart';
import 'package:micro_banking_app/read_acc_reports.dart';
import 'package:micro_banking_app/read_all_reports.dart';

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
            child: Text("Create Account"),
          ),
          RaisedButton(
            onPressed: navigateToDeleteAccount,
            child: Text("Delete Account"),
          ),
          RaisedButton(
            onPressed: navigateToReadReport,
            child: Text("Read Account Reports"),
          ),
          RaisedButton(
            onPressed: navigateToReadAllReports,
            child: Text("Read All Reports"),
          )
        ],
      ),
    );
  }

  void navigateToCreateAccount() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return CreateAccount();
    }));
  }

  void navigateToDeleteAccount() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return DeleteAccount();
    }));
  }

  void navigateToReadReport() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ReadAccountReports();
    }));
  }

  void navigateToReadAllReports() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ReadAllReports();
    }));
  }
}
