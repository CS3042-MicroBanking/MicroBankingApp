import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:micro_banking_app/management_page.dart';
import 'package:micro_banking_app/customer_page.dart';
import 'package:micro_banking_app/database_helper.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _unameController = TextEditingController();
  final _pwdController = TextEditingController();
  DatabaseHelper databaseHelper = DatabaseHelper();
  bool initiated = false;

  @override
  Widget build(BuildContext context) {
    if (!initiated) {
      initializeDB();
      initiated = true;
    }
    return Scaffold(
        appBar: AppBar(
          title: Text("Login"),
        ),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              TextField(
                controller: _unameController,
                decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0))),
              ),
              TextField(
                controller: _pwdController,
                obscuringCharacter: '•',
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0))),
              ),
              RaisedButton(
                onPressed: () {
                  var user = databaseHelper.getUserMap(_unameController.text);
                  user.then((usr) {
                    if (usr[0]['password'] == _pwdController.text) {
                      if (usr[0]['type'] == 'management') {
                        navigateToManagementPage(usr[0]['uname']);
                      } else {
                        navigateToCustomerPage(usr[0]['uname']);
                      }
                    }
                  });
                },
                child: Text("Log In"),
              )
            ],
          ),
        ));
  }

  void navigateToManagementPage(String uname) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ManagementPage(
        uname: uname,
      );
    }));
  }

  void navigateToCustomerPage(String uname) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return CustomerPage(
        uname: uname,
      );
    }));
  }

  void initializeDB() {
    final Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) {
      setState(() {});
    });
  }
}
