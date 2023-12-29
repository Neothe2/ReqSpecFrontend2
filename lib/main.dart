import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reqspec/step_list/http_providor.dart';
import 'package:reqspec/step_list/step_bloc.dart';
import 'package:reqspec/step_list/step_list_widget.dart';

import 'home_page.dart';
import 'step_list/models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'Steps Tree Widget ;)'),
      debugShowCheckedModeBanner: false,
    );
  }
}

