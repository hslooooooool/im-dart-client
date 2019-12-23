import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_2/model/proto/Message.pb.dart';
import 'package:flutter_app_2/model/proto/ReplyBody.pb.dart';
import 'package:flutter_app_2/model/proto/SendBody.pb.dart';
import 'package:flutter_app_2/sdk/im_lib.dart';
import 'package:web_socket_channel/io.dart';

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
  IMWebSocketHelper _helper;

  void _onChangedHandle(value) {
    setState(() {
      _message = value.toString();
    });
  }

  /*连接消息服务*/
  void _connect() async {
    _helper.init("ws://192.168.3.107:23456", "test dart", false);
    setState(() {
      _list.add('[Connect] 建立连接');
    });
    _helper.setOnMessageListener(
        OnMessageListener(getMessage: (MessageModel message) {

        }));
  }

  /*消息接收处理*/
  void _handleMessage(Uint8List data) {
    if (data.length < DATA_HEADER_LENGTH) {
      print("空消息");
      return;
    }
    var type = data[0];
    /*收到服务端发来的心跳请求，立即回复响应，否则服务端会在10秒后断开连接*/
    switch (type) {
      case HEART_RQ:
        print("[Received] 心跳消息");
        _sendHeartbeatResponse();
        break;
      case MESSAGE:
        print("[Received] 自定义消息");
        _getMessage(data);
        break;
      case REPLY_BODY:
        print("[Received] 回执消息");
        _getReplyBody(data);
        break;
    }
  }

  /*自定义消息解析*/
  void _getMessage(Uint8List data) {
    MessageModel message = new MessageModel.fromBuffer(
        data.sublist(DATA_HEADER_LENGTH, data.length));
    _list.add('[Received] 自定义消息 ${message.title} 内容：${message.content}');
  }

  /*服务器回执消息*/
  void _getReplyBody(data) {
    ReplyModel reply = new ReplyModel.fromBuffer(data);
    _list.add('[Received] 服务器回执 ${reply.key} 内容：${reply.message}');
  }

  /*发送消息*/
  void _sendHandle() {
    setState(() {
      _list.add('[Sended] $_message');
    });
    getPackageInfo().then((onValue) {
      var sendBody = new SendBodyModel();
      sendBody.key = "client_closed";
      sendBody.data["account"] = "FLUTTER DEMO";
      sendBody.data["channel"] = SDK_CHANNEL;
      sendBody.data["version"] = SDK_VERSION;
      sendBody.data["osVersion"] = "${onValue.version}";
      sendBody.data["device"] = "${onValue.appName}";
      sendBody.data["packageName"] = "${onValue.packageName}";
      sendBody.data["deviceId"] = "${onValue.hashCode}";
      sendMsg(SEND_BODY, sendBody);
    });
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
    List<Widget> prefix = [_generatorForm()];
    List<Widget> tmpList = _list.map((item) => ListItem(msg: item)).toList();
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
      setState(() {
        _list.add('[Send] 发送消息>>>$sendBody');
      });
      _channel.sink.add(protubuf);
      print("给服务端发送消息，消息号=$msgCode");
    } catch (e) {
      print("send捕获异常：msgCode=$msgCode，e=${e.toString()}");
    }
  }

  Uint8List buildHeader(type, length) {
    var header = Uint8List(DATA_HEADER_LENGTH);
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
