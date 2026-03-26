import 'package:flutter/material.dart';

void main() {

  
  runApp(MaterialApp(
    home: 
}

class Home extends StatelessWidget {
  const test({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wsg bro')
        ,centerTitle: true,
        backgroundColor: Colors.amberAccent[900],
      ),
    body: Center(
      child: Text(
        "Hello World",
        style: TextStyle(
          fontSize: 80,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(onPressed: () {
    },  
      child: Text("+"),
      backgroundColor: Colors.amberAccent[900],
    ),
  )));
  ;
  }
}




