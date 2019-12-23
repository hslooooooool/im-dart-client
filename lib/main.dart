import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_2/model/proto/Message.pb.dart';
import 'package:flutter_app_2/model/proto/ReplyBody.pb.dart';
import 'package:flutter_app_2/model/proto/SendBody.pb.dart';
import 'package:flutter_app_2/sdk/im_lib.dart';

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
  IMWebSocketHelper _helper = IMWebSocketHelper.instance;

  Widget _generatorForm() {
    return Column(
      children: <Widget>[
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
              child: Text('Close'),
              onPressed: _closeHandle,
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
    _helper.sendCloseAction();
  }

  /// 连接消息服务
  void _connect() async {
    _helper.config("ws://192.168.1.3:23456", "test dart", false).connect();
    setState(() {
      _list.add('[Connect] 建立连接');
    });
    _helper.setOnMessageListener(
        OnMessageListener(getMessage: (MessageModel message) {
      _handleMessage(message);
    }, getReply: (ReplyModel reply) {
      _handleReply(reply);
    }, getSend: (SendBodyModel send) {
      setState(() {
        _list.add('[Send] $send');
      });
    }, error: (Exception error) {
      _handleError(error);
    }));
  }

  /// 自定义消息
  void _handleMessage(MessageModel message) {
    setState(() {
      _list.add('[Received] 自定义消息 ${message.title} 内容：${message.content}');
    });
  }

  /// 服务器回执
  void _handleReply(ReplyModel reply) {
    setState(() {
      _list.add('[Received] 服务器回执：$reply');
    });
  }

  /// 服务器报错
  void _handleError(Exception error) {
    setState(() {
      _list.add('[Error] $error');
    });
  }

  /// 账号绑定
  void _bindHandle() {
    _helper.bindHandle();
    setState(() {
      _list.add('[Bind] ${_helper.mAccount}');
    });
  }

  /// 发送消息
  void _sendHandle() {
    setState(() {
      _list.add('[Sended] $_message');
    });
  }

  /// 关闭连接
  void _closeHandle() {
    _helper.sendCloseAction();
    setState(() {
      _list.add('[Closed]');
    });
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
