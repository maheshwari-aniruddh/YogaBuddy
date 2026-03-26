import 'package:flutter/material.dart';

void main() {
  int counter = 0;
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: Text('Wsg bro')
      ),
    body: Center(
      child: Text(counter1().toString(),
        style: TextStyle(
          fontSize: 30,
          color: Colors.red,
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(onPressed: () {
      counter=counter + 1;
    },  
      child: Text("+"),
    ),
  )));
  int counter1()
  {
    return counter;
  }
}




