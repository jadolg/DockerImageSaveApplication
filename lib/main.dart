import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Docker Image Save',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Docker Image Save'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final imageTextController = TextEditingController(text: "alpine:3.12");
  var _fieldsEnabled = true;
  var _imageURL = "";
  var _errorMessage = "";

  Future pullImageUntilCompleted(String imageName) async {
    Map<String, dynamic> data;
    do {
      var image = await http
          .get(Uri.https('dockerimagesave.copincha.org', 'pull/$imageName'));
      data = jsonDecode(image.body);
      if (data['status'] == 'Error') {
        throw ("Error pulling image $imageName");
      }
      if (data['status'] != 'Downloaded') {
        await Future.delayed(const Duration(seconds: 10));
      }
    } while (data['status'] != 'Downloaded');
  }

  Future<String> saveImageUntilCompleted(String imageName) async {
    Map<String, dynamic> data;
    do {
      var image = await http
          .get(Uri.https('dockerimagesave.copincha.org', 'save/$imageName'));
      data = jsonDecode(image.body);
      if (data['status'] != 'Ready') {
        await Future.delayed(const Duration(seconds: 10));
      }
    } while (data['status'] != 'Ready');
    return data['url'];
  }

  downloadImage() {
    setState(() {
      _fieldsEnabled = false;
      _imageURL = "";
      _errorMessage = "";
    });
    pullImageUntilCompleted(imageTextController.value.text).then((value) {
      saveImageUntilCompleted(imageTextController.value.text).then((url) {
        setState(() {
          _imageURL = "https://dockerimagesave.copincha.org/$url";
          _fieldsEnabled = true;
        });
      });
    }).onError((error, stackTrace) {
      setState(() {
        _errorMessage = error;
        _fieldsEnabled = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(50, 8, 50, 20),
                    child: TextField(
                      autofocus: true,
                      onSubmitted: (value) => downloadImage(),
                      style: _fieldsEnabled
                          ? TextStyle(color: Colors.black)
                          : TextStyle(color: Colors.grey),
                      enabled: _fieldsEnabled,
                      controller: imageTextController,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter image name Eg: alpine:3.12',
                          labelText: "Image"),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 50, 20),
                  child: MaterialButton(
                    onPressed: _fieldsEnabled ? downloadImage : null,
                    child: Text("Download"),
                    color: _fieldsEnabled ? Colors.blue : Colors.grey,
                    textColor: Colors.white,
                  ),
                )
              ],
            ),
            _imageURL == ""
                ? Text("")
                : MaterialButton(
                    onPressed: () => launch(_imageURL),
                    child: Text(_imageURL),
                    textColor: Colors.lightBlueAccent,
                  ),
            _imageURL == "" && !_fieldsEnabled
                ? Text("Downloading...")
                : Text(""),
            _errorMessage != "" ? Text(_errorMessage) : Text(""),
          ],
        ),
      ),
    );
  }
}
