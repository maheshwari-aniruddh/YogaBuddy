import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: Text('Wsg bro')
      ),
      body: Center(
        child: Text("Wsg bro"),
        ),
        floatingActionButton: FloatingActionButton(onPressed: () {
          print("Floating Action Button Pressed");
        },
          child: Text("+"),
        ),
    )
  ));
}


