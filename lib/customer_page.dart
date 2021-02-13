import 'package:flutter/material.dart';
import 'package:micro_banking_app/withdraw_deposit.dart';

class CustomerPage extends StatefulWidget {
  final String uname;
  CustomerPage({Key key, @required this.uname}) : super(key: key);
  @override
  _CustomerPageState createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
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
            onPressed: navigateToWithdrawDeposit,
            child: Text("Withdraw / Deposit"),
          ),
        ],
      ),
    );
  }

  void navigateToWithdrawDeposit() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return WithdrawDeposit(
        uname: widget.uname,
      );
    }));
  }
}
