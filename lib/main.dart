import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  var _imageSize = 0;
  var _errorMessage = "";

  Future pullImageUntilCompleted(String imageName) async {
    Map<String, dynamic> data;
    do {
      var image = await http
          .get(Uri.https('dockerimagesave.akiel.dev', 'pull/$imageName'));
      data = jsonDecode(image.body);
      if (data['status'] == 'Error') {
        throw ("Error pulling image $imageName");
      }
      if (data['status'] != 'Downloaded') {
        await Future.delayed(const Duration(seconds: 10));
      }
    } while (data['status'] != 'Downloaded');
  }

  Future<Map<String, dynamic>> saveImageUntilCompleted(String imageName) async {
    Map<String, dynamic> data;
    do {
      var image = await http
          .get(Uri.https('dockerimagesave.akiel.dev', 'save/$imageName'));
      data = jsonDecode(image.body);
      if (data['status'] != 'Ready') {
        await Future.delayed(const Duration(seconds: 10));
      }
    } while (data['status'] != 'Ready');
    return data;
  }

  downloadImage() {
    setState(() {
      _fieldsEnabled = false;
      _imageURL = "";
      _errorMessage = "";
      _imageSize = 0;
    });
    pullImageUntilCompleted(imageTextController.value.text).then((value) {
      saveImageUntilCompleted(imageTextController.value.text).then((data) {
        setState(() {
          _imageURL = "https://dockerimagesave.akiel.dev/${data["url"]}";
          _imageSize = data["size"];
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
                    child: Text("Pull"),
                    color: _fieldsEnabled ? Colors.blue : Colors.grey,
                    textColor: Colors.white,
                  ),
                )
              ],
            ),
            Visibility(
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              visible: _imageURL != "",
              child: MaterialButton(
                onPressed: () => launch(_imageURL),
                child: Text(
                    "${_imageURL.replaceFirst("https://dockerimagesave.akiel.dev/download/", "")} [${filesize(_imageSize)}]"),
                textColor: Colors.lightBlueAccent,
              ),
            ),
            Visibility(
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              visible: _imageURL == "" && !_fieldsEnabled,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                  Text("Obtaining"),
                ],
              ),
            ),
            Visibility(
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                visible: _errorMessage != "",
                child: Text(_errorMessage)),
            Container(
              constraints: BoxConstraints.tight(Size.fromRadius(300)),
              child: Markdown(
                  selectable: true,
                  data: "# What's this:\n"
                      "This application downloads **Docker** images compressed as zip files.\n\n"
                      "It is intended to be used in places like *Cuba* where the access to DockerHub is blocked.\n\n"
                      "# How to use:\n"
                      "1. Enter image and tag that you want to download in the text box (**image:tag**)\n"
                      "2. Click **pull** and wait for the download link to appear\n"
                      "3. Download the zip file\n"
                      "4. Unzip the file in your computer\n"
                      "5. Load the **docker image** in your local **docker** `docker load -i image_tag.tar`"),
            ),
          ],
        ),
      ),
    );
  }
}
