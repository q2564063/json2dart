import 'dart:convert';
import 'dart:html';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json2dart/generator.dart';
import 'package:json2dart/my_config.dart';
import 'package:json2dart/storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'json2dart',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'dart model generator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controllerLeft = TextEditingController();
  final TextEditingController _controllerRight = TextEditingController();
  final TextEditingController _controllerClassName = TextEditingController();

  var downloadFileName = "";

  @override
  void initState() {
    super.initState();

    var dataHelper = CookieHelper();
    _controllerClassName.text = "Entity";
    _controllerLeft.text = dataHelper.loadJsonString();

    _controllerLeft.addListener(() {
      dataHelper.saveJsonString(_controllerLeft.text);
      refreshData();
    });
    _controllerClassName.addListener(() {
      refreshData();
    });

    window.onResize.listen((event) {
      setState(() {});
    });
  }

  late Generator generator;
  void refreshData() async {
    var string = _controllerLeft.text;

    try {
      formatJson(string);
    } on Exception {
      _controllerRight.text = "不是一个正确的json";
      return;
    }
    String entityName = _controllerClassName.text;
    String entityClassName;
    if (entityName == "" || entityName.trim() == "") {
      entityClassName = "Entity";
    } else {
      entityClassName = entityName;
    }

    generator = Generator(string, entityClassName, v);
    generator.refreshAllTemplates();
    makeCode(generator);
  }

  void makeCode(Generator generator) {
    var dartCode = generator.makeDartCode(_controllerClassName.text);
    var dartFileName = ("${generator.fileName}.dart");
    setState(() {
      downloadFileName = dartFileName;
    });

    String filePrefix = "应该使用的文件名为:";

    final resultName = "$filePrefix $dartFileName";
    writeToResult(resultName, dartCode);
  }

  void writeToResult(String resultName, String resultText) {
    _controllerRight.text = resultText;
  }

  String formatJson(String jsonString) {
    var map = json.decode(jsonString);
    var prettyString = const JsonEncoder.withIndent("  ").convert(map);
    return prettyString;
  }

  void refreshClassNameChange(String text) {
    final value = generator.makeDartCode(_controllerClassName.text);
    String filePrefix = "应该使用的文件名为:";

    var dartFileName = ("${generator.fileName}.dart");
    setState(() {
      downloadFileName = dartFileName;
    });
    final resultName = "$filePrefix $dartFileName";
    writeToResult(resultName, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Container(
        padding: const EdgeInsets.all(30.0),
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text("类名："),
                Expanded(
                  child: TextField(
                    controller: _controllerClassName,
                    onChanged: refreshClassNameChange,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text('下载文件名：$downloadFileName'),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 2,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text("json"),
                        Expanded(
                          child: TextField(
                            controller: _controllerLeft,
                            maxLines: 1000,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: ElevatedButton(
                                  onPressed: formatAction,
                                  child: const Text('格式化')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text("dart"),
                        Expanded(
                          child: TextField(
                            controller: _controllerRight,
                            maxLines: 1000,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: ElevatedButton(
                                  onPressed: copyAction, child: Text('复制')),
                            ),
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: ElevatedButton(
                                  onPressed: downloadFile, child: Text('下载文件')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  formatAction() {
    String pretty = convertJsonString(_controllerLeft.text);
    try {
      pretty = formatJson(pretty);
    } on Exception {
      return;
    }
    _controllerLeft.text = pretty;
  }

  copyAction() {
    String textToCopy = _controllerRight.text;
    Clipboard.setData(ClipboardData(text: textToCopy));
  }

  void downloadFile() {
    var dartFileName = ("${generator.fileName}.dart");
    var content = _controllerRight.text;
    // 将文件内容写入一个Blob对象中
    final blob = Blob([content]);

    // 创建一个URL对象，用于下载
    final url = Url.createObjectUrlFromBlob(blob);

    // 创建一个anchor元素，设置下载属性和href链接
    final link = document.createElement('a') as AnchorElement
      ..href = url
      ..download = dartFileName;

    // 将anchor元素添加到DOM中并模拟点击下载
    document.body?.append(link);
    link.click();

    // 释放URL对象
    Url.revokeObjectUrl(url);
  }
}
