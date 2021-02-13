import 'package:flutter/material.dart';
import 'login_page.dart';

void main(List<String> args) {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Microbank',
      theme: ThemeData(primarySwatch: Colors.lightBlue),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
