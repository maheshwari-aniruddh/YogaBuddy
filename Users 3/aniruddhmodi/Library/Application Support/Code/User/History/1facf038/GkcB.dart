import 'package:flutter/material.dart';

void main() {
  int counter = 0;
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: Text('Wsg bro')
      ),
      body: Center(
        child: Text(counter.toString()
        ),
        floatingActionButton: FloatingActionButton(onPressed: () {
          counter=counter + 1;
        },  
          child: Text("+"),
        ),
    )
  )));
}


