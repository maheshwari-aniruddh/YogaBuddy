import 'package:flutter/material.dart';

void main() {

  
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: Text('Wsg bro')
        ,centerTitle: true,
        backgroundColor: Colors.amberAccent[900],
      ),
    body: Center(
      child: Text(
        "Hello World",
        style: TextStyle(
          fontSize: 24,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(onPressed: () {


    },  
      child: Text("+"),
    ),
  )));
  
}




