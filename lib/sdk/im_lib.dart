import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info/device_info.dart';
import 'package:flutter_app_2/model/proto/Message.pb.dart';
import 'package:flutter_app_2/model/proto/ReplyBody.pb.dart';
import 'package:flutter_app_2/model/proto/SendBody.pb.dart';
import 'package:web_socket_channel/io.dart';

const SDK_VERSION = "1.0.0";

/// 特殊的消息类型，代表被服务端强制下线
const ACTION_999 = "999";

/// 消息头部字节数
const DATA_HEADER_LENGTH = 3;

/// 心跳指令，67对应C 82对应R
const CMD_HEARTBEAT_RESPONSE = [67, 82];

/// 客户端心跳
const HEART_CR = 0;

/// 服务端心跳
const HEART_RQ = 1;

/// 自定义消息
const MESSAGE = 2;

/// 客户端消息发送
const SEND_BODY = 3;

/// 服务端消息回执
const REPLY_BODY = 4;

typedef OnMessage = void Function(MessageModel message);
typedef OnReply = void Function(ReplyModel message);
typedef OnError = void Function(Exception error);

/// 消息回调接口
class OnMessageListener {
  OnMessage getMessage;
  OnReply getReply;
  OnError error;

  OnMessageListener({this.getMessage, this.getReply, this.error});
}

/// 消息服务帮助类
class IMWebSocketHelper {
  factory IMWebSocketHelper() => _getInstance();

  static IMWebSocketHelper get instance => _getInstance();
  static IMWebSocketHelper _instance;

  IOWebSocketChannel _channel;
  OnMessageListener mOnMessageListener;

  /// IM服务器地址
  var mUrl = "ws://192.168.3.107:23456";

  /// IM服务器账号
  var mAccount = "";

  /// IM服务器账号自动绑定
  var mAutoBind = true;

  /// 设置IM服务器地址
  IMWebSocketHelper config(String url, String account, [bool autoBind = true]) {
    mUrl = url;
    mAccount = account;
    mAutoBind = account.isNotEmpty && autoBind;
    return this;
  }

  /// 设置消息监听
  IMWebSocketHelper setOnMessageListener(OnMessageListener listener) {
    mOnMessageListener = listener;
    return this;
  }

  /// 初始化
  IMWebSocketHelper._internal() {
    mOnMessageListener = null;
    _channel = null;
  }

  static IMWebSocketHelper _getInstance() {
    if (_instance == null) {
      _instance = new IMWebSocketHelper._internal();
    }
    return _instance;
  }

  /// 连接消息服务
  void connect() async {
    _channel = IOWebSocketChannel.connect(mUrl);
    log("$_channel");
    if (mAutoBind) {
      this.bindHandle();
    }
    /**监听消息*/
    _channel.stream.listen((message) {
      log(message);
      _handleMessage(message);
    });
  }

  /// 绑定账号
  void bindHandle() async {
    _createSendBody().then((sendBody) {
      log("${sendBody.data}");
      sendBody.key = "client_bind";
      sendAction(SEND_BODY, sendBody);
    });
  }

  /// 发送心跳
  void sendHeartbeatResponse() {
    var cmd = Uint8List.fromList(CMD_HEARTBEAT_RESPONSE);
    var header = buildHeader(HEART_CR, cmd.length);
    var protubuf = new Uint8List(header.length + cmd.length);
    protubuf.setAll(0, header);
    protubuf.setAll(header.length, cmd);
    try {
      _channel.sink.add(protubuf);
    } catch (e) {
      log("给服务端发送心跳异常，${e.toString()}");
    }
  }

  /// 消息接收处理
  void _handleMessage(Uint8List data) {
    if (data.length < DATA_HEADER_LENGTH) {
      print("空消息");
      return;
    }
    var type = data[0];
    /**收到服务端发来的心跳请求，立即回复响应，否则服务端会在【30】秒后断开连接*/
    switch (type) {
      case HEART_RQ:
        print("[Received] 心跳消息");
        sendHeartbeatResponse();
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

  /// 自定义消息解析
  void _getMessage(Uint8List data) {
    MessageModel message = new MessageModel.fromBuffer(
        data.sublist(DATA_HEADER_LENGTH, data.length));
    log("[Received] 自定义消息 ${message.title} 内容：${message.content}");
    mOnMessageListener.getMessage(message);
  }

  /// 服务器回执消息解析
  void _getReplyBody(data) {
    ReplyModel reply = new ReplyModel.fromBuffer(data);
    log("[Received] 服务器回执 ${reply.key} 内容：${reply.message}");
    mOnMessageListener.getReply(reply);
  }

  /// 发送关闭请求
  void sendCloseAction() {
    _createSendBody().then((sendBody) {
      log("${sendBody.data}");
      sendBody.key = "client_closed";
      sendAction(SEND_BODY, sendBody);
    });
    closeHandler();
  }

  /// 发送指令消息*/
  void sendAction(int msgCode, SendBodyModel sendBody) {
    Uint8List data = sendBody.writeToBuffer();
    var header = buildHeader(SEND_BODY, data.length);
    var protubuf = new Uint8List(header.length + data.length);
    protubuf.setAll(0, header);
    protubuf.setAll(header.length, data);
    try {
      _channel.sink.add(protubuf);
      print("发送消息，$sendBody");
    } catch (e) {
      print("发送异常，sendBody>>>$sendBody error>>>${e.toString()}");
    }
  }

  /// 异常捕获
  void errorHandler(Exception error) {
    print("消息异常：error=$error");
    mOnMessageListener.error(error);
  }

  /// 关闭连接
  void closeHandler() {
    _channel.sink.close();
    print("socket关闭处理");
  }

  /// 构建消息头
  Uint8List buildHeader(type, length) {
    var header = Uint8List(DATA_HEADER_LENGTH);
    header[0] = type;
    header[1] = (length & 0xff);
    header[2] = ((length >> 8) & 0xff);
    return header;
  }

  /// 获得一个指令发送体
  Future<SendBodyModel> _createSendBody() async {
    var sendBody = new SendBodyModel();
    if (mAccount.isNotEmpty) {
      sendBody.data["account"] = mAccount;
      sendBody.data["version"] = SDK_VERSION;
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo info = await deviceInfo.androidInfo;
        sendBody.data["channel"] = "ios";
        sendBody.data["osVersion"] = info.product;
        sendBody.data["device"] = info.model;
        sendBody.data["deviceId"] = info.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo info = await deviceInfo.iosInfo;
        sendBody.data["channel"] = "android";
        sendBody.data["osVersion"] = info.utsname.version;
        sendBody.data["device"] = info.model;
        sendBody.data["deviceId"] = info.utsname.machine;
      }
      sendBody.data["packageName"] = "vip.qsos.im.flutter";
    }
    return sendBody;
  }
}
