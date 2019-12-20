import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_2/model/proto/SendBody.pb.dart';
import 'package:package_info/package_info.dart';
import 'package:web_socket_channel/io.dart';

/*IM服务器参数*/
const IM_URI = "ws://192.168.1.103:23456";

const SDK_VERSION = "1.0.0";
const APP_VERSION = "1.0.0";
const APP_NAME = "1.0.0";
const SDK_CHANNEL = "flutter";
const APP_PACKAGE = "vip.qsos.im.flutter";
/*特殊的消息类型，代表被服务端强制下线*/
const ACTION_999 = "999";
/*消息头部字节数*/
const DATA_HEADER_LENGTH = 3;
/*心跳指令*/
//var CMD_HEARTBEAT_RESPONSE =  Uint8List.fromList(new List()[67,82]);
/*客户端心跳*/
const HEART_CR = 0;
/*服务端心跳*/
const HEART_RQ = 1;
/*消息*/
const MESSAGE = 2;
/*客户端消息发送*/
const SEND_BODY = 3;
/*服务端消息回执*/
const REPLY_BODY = 4;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text('WebSocketDemo'),
          ),
          body: WebSocketDemo()),
    );
  }
}

class WebSocketDemo extends StatefulWidget {
  WebSocketDemo({Key key}) : super(key: key);

  _WebSocketDemoState createState() => _WebSocketDemoState();
}

class _WebSocketDemoState extends State<WebSocketDemo> {
  List _list = new List();
  String _message;
  IOWebSocketChannel _channel;

  void _onChangedHandle(value) {
    setState(() {
      _message = value.toString();
    });
  }

  /*连接消息服务*/
  void _connect() async {
    _channel = IOWebSocketChannel.connect(IM_URI);
    /*监听消息*/
    _channel.stream.listen((message) {
      print(message);
      setState(() {
        _handleMessage(message);
      });
    });
  }

  /*绑定账号*/
  void _bindHandle() async {
    getPackageInfo().then((onValue) {
      var sendBody = new SendBodyModel();
      sendBody.key = "client_bind";
      sendBody.data["account"] = "FLUTTER DEMO";
      sendBody.data["channel"] = SDK_CHANNEL;
      sendBody.data["version"] = SDK_VERSION;
      sendBody.data["osVersion"] = onValue.version;
      sendBody.data["device"] = onValue.appName;
      sendBody.data["packageName"] = onValue.packageName;
      sendBody.data["deviceId"] = "${onValue.hashCode}";
      sendMsg(SEND_BODY, sendBody);
    });
  }

  /*发送心跳*/
  void _sendHeartbeatResponse() {
    var data = new Uint8List(2);
    data[0] = 67;
    data[1] = 82;
    var header = buildHeader(HEART_CR, data.length);
    var protubuf = new Uint8List(header.length + data.length);
    protubuf.setAll(0, header);
    protubuf.setAll(header.length, data);
    try {
      _channel.sink.add(protubuf);
      print("给服务端发送心跳");
    } catch (e) {
      print("给服务端发送心跳异常，${e.toString()}");
    }
  }

  /*消息接收处理*/
  void _handleMessage(Uint8List data) {
    var type = data[0];
    /*收到服务端发来的心跳请求，立即回复响应，否则服务端会在10秒后断开连接*/
    switch (type) {
      case HEART_RQ:
        print("心跳消息");
        _list.add('[Received] 心跳消息');
        _sendHeartbeatResponse();
        break;
      case MESSAGE:
        print("消息");
        _list.add('[Received] 消息');
        break;
      case REPLY_BODY:
        print("回执消息");
        _list.add('[Received] 回执消息');
        break;
    }
  }

  /*发送消息*/
  void _sendHandle() {
    if (_message.isNotEmpty) {
      _list.add('[Sended] $_message');
      getPackageInfo().then((onValue) {
        var sendBody = new SendBodyModel();
        sendBody.key = "client_bind";
        sendBody.data["account"] = "FLUTTER DEMO";
        sendBody.data["channel"] = SDK_CHANNEL;
        sendBody.data["version"] = SDK_VERSION;
        sendBody.data["osVersion"] = onValue.version;
        sendBody.data["device"] = onValue.appName;
        sendBody.data["packageName"] = onValue.packageName;
        sendBody.data["deviceId"] = "${onValue.hashCode}";
        sendMsg(SEND_BODY, sendBody);
      });
    }
  }

  Widget _generatorForm() {
    return Column(
      children: <Widget>[
        TextField(onChanged: _onChangedHandle),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            RaisedButton(
              child: Text('CONNECT'),
              onPressed: _connect,
            ),
            RaisedButton(
              child: Text('BIND'),
              onPressed: _bindHandle,
            ),
            RaisedButton(
              child: Text('SEND'),
              onPressed: _sendHandle,
            ),
          ],
        )
      ],
    );
  }

  List<Widget> _generatorList() {
    List<Widget> tmpList = _list.map((item) => ListItem(msg: item)).toList();
    List<Widget> prefix = [_generatorForm()];
    prefix.addAll(tmpList);
    return prefix;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(10),
      children: _generatorList(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _channel.sink.close();
  }

  /*发消息，指定消息号，pb对象可以为不传(例如发心跳包的时候)*/
  void sendMsg(int msgCode, SendBodyModel sendBody) {
    Uint8List data = sendBody.writeToBuffer();
    var header = buildHeader(SEND_BODY, data.length);
    var protubuf = new Uint8List(header.length + data.length);
    protubuf.setAll(0, header);
    protubuf.setAll(header.length, data);
    try {
      _channel.sink.add(protubuf);
      print("给服务端发送消息，消息号=$msgCode");
    } catch (e) {
      print("send捕获异常：msgCode=$msgCode，e=${e.toString()}");
    }
  }

  Int8List buildHeader(type, length) {
    var header = Int8List(DATA_HEADER_LENGTH);
    header[0] = type;
    header[1] = (length & 0xff);
    header[2] = ((length >> 8) & 0xff);
    return header;
  }

  void errorHandler(error, StackTrace trace) {
    print("捕获socket异常信息：error=$error，trace=${trace.toString()}");
    _channel.sink.close();
  }

  void doneHandler() {
    _channel.sink.close();
    print("socket关闭处理");
  }
}

class ListItem extends StatelessWidget {
  final String msg;

  ListItem({Key key, this.msg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(msg);
  }
}

/*获取APP信息*/
Future<PackageInfo> getPackageInfo() async {
  var packageInfo = await PackageInfo.fromPlatform();
  return packageInfo;
}
