import 'package:flutter/material.dart';

void main() 
{
  List fibonnaci = [];
  int base_1 = 0;
  int base_2 = 1;
  for (int i =0; i<200; i++) 
  {
    int base_3 = base_1 + base_2;
    fibonnaci.add(base_3);
    base_1=base_2;
    base_2=base_3;
    
  }
  print(fibonnaci);
}



