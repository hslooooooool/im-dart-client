/*IM服务器IP*/
let IM_HOST = "127.0.0.1";
/*IM服务端口*/
let IM_PORT = 23456;

/*初始化连接配置*/
function init(host, port) {
    IM_HOST = host;
    IM_PORT = port;
}

const IM_URI = "ws://" + IM_HOST + ":" + IM_PORT;
const SDK_VERSION = "1.0.0";
const SDK_CHANNEL = "browser";
const APP_PACKAGE = "vip.qsos.im.web";
/*特殊的消息类型，代表被服务端强制下线*/
const ACTION_999 = "999";
/*消息头部字节数*/
const DATA_HEADER_LENGTH = 3;
/*心跳指令*/
const CMD_HEARTBEAT_RESPONSE = new Uint8Array([67, 82]);

/**客户端心跳*/
const HEART_CR = 0;
/**服务端心跳*/
const HEART_RQ = 1;
/**消息*/
const MESSAGE = 2;
/**客户端消息发送*/
const SEND_BODY = 3;
/**服务端消息回执*/
const REPLY_BODY = 4;
/**会话*/
const SESSION = 5;
/**Websocket*/
const WEBSOCKET = 6;

let socket;
let manualStop = false;

const IMPushManager = {};

/*连接服务*/
IMPushManager.connection = function () {
    manualStop = false;
    window.localStorage.account = '';
    socket = new WebSocket(IM_URI);
    socket.cookieEnabled = false;
    socket.binaryType = 'arraybuffer';
    socket.onopen = IMPushManager.innerOnConnectionSuccess;
    socket.onmessage = IMPushManager.innerOnMessageReceived;
    socket.onclose = IMPushManager.innerOnConnectionClosed;
};

/*登录账号*/
IMPushManager.bindAccount = function (account) {
    window.localStorage.account = account;
    let deviceId = window.localStorage.deviceIddeviceId;
    if (deviceId === '' || deviceId === undefined) {
        deviceId = generateUUID();
        window.localStorage.deviceId = deviceId;
    }

    const browser = getBrowser();
    const sendBody = new proto.vip.qsos.im.lib.model.proto.Model.SendBody();
    sendBody.setKey("client_bind");
    sendBody.getDataMap().set("account", account);
    sendBody.getDataMap().set("channel", SDK_CHANNEL);
    sendBody.getDataMap().set("version", SDK_VERSION);
    sendBody.getDataMap().set("osVersion", browser.version);
    sendBody.getDataMap().set("device", browser.name);
    sendBody.getDataMap().set("packageName", APP_PACKAGE);
    sendBody.getDataMap().set("deviceId", deviceId);
    IMPushManager.sendRequest(sendBody);
};

/*停止连接*/
IMPushManager.stop = function () {
    manualStop = true;
    socket.close();
};

/*重启连接*/
IMPushManager.resume = function () {
    manualStop = false;
    IMPushManager.connection();
};

/*连接成功*/
IMPushManager.innerOnConnectionSuccess = function () {
    const account = window.localStorage.account;
    if (account === '' || account === undefined) {
        onConnectionSuccess();
    } else {
        IMPushManager.bindAccount(account);
    }
};

/*消息接收处理*/
IMPushManager.innerOnMessageReceived = function (e) {
    let length;
    let data = new Uint8Array(e.data);

    const type = data[0];
    /*收到服务端发来的心跳请求，立即回复响应，否则服务端会在10秒后断开连接*/
    if (type === HEART_RQ) {
        IMPushManager.sendHeartbeatResponse();
        return;
    }
    /*消息*/
    if (type === MESSAGE) {
        length = getContentLength(data[1], data[2]);
        data = new proto.vip.qsos.im.lib.model.proto.Model.Message.deserializeBinary(data.subarray(DATA_HEADER_LENGTH, DATA_HEADER_LENGTH + length));
        onInterceptMessageReceived(data.toObject(false));
        return;
    }
    /*服务器回执*/
    if (type === REPLY_BODY) {
        length = getContentLength(data[1], data[2]);
        data = new proto.vip.qsos.im.lib.model.proto.Model.ReplyBody.deserializeBinary(data.subarray(DATA_HEADER_LENGTH, DATA_HEADER_LENGTH + length));
        /*将proto对象转换成json对象，去除无用信息*/
        const reply = {};
        reply.code = data.getCode();
        reply.key = data.getKey();
        reply.message = data.getMessage();
        reply.timestamp = data.getTimestamp();
        reply.data = {};
        /*遍历map这里的参数 value在前 key 在后*/
        data.getDataMap().forEach(function (v, k) {
            reply.data[k] = v;
        });
        /*服务器请求回执*/
        onReplyReceived(reply);
    }
};

/*连接关闭*/
IMPushManager.innerOnConnectionClosed = function (e) {
    if (!manualStop) {
        const time = Math.floor(Math.random() * (30 - 15 + 1) + 15);
        setTimeout(function () {
            IMPushManager.connection();
        }, time);
    }
};

/*发送请求*/
IMPushManager.sendRequest = function (body) {
    const data = body.serializeBinary();
    const header = buildHeader(SEND_BODY, data.length);
    const protubuf = new Uint8Array(data.length + header.length);
    protubuf.set(header, 0);
    protubuf.set(data, header.length);
    socket.send(protubuf);
};

/*发送心跳*/
IMPushManager.sendHeartbeatResponse = function () {
    const data = CMD_HEARTBEAT_RESPONSE;
    const header = buildHeader(HEART_CR, data.length);
    const protubuf = new Uint8Array(data.length + header.length);
    protubuf.set(header, 0);
    protubuf.set(data, header.length);
    socket.send(protubuf);
};

/*获取消息长度*/
function getContentLength(lv, hv) {
    const l = lv & 0xff;
    let h = hv & 0xff;
    return l | (h <<= 8);
}

/*构建消息头字节*/
function buildHeader(type, length) {
    const header = new Uint8Array(DATA_HEADER_LENGTH);
    header[0] = type;
    header[1] = (length & 0xff);
    header[2] = ((length >> 8) & 0xff);
    return header;
}

/*接收到消息*/
function onInterceptMessageReceived(message) {
    /*强制下线，不再继续连接服务端*/
    if (message.action === ACTION_999) {
        manualStop = true;
    }
    /*将消息发送给页面*/
    if (onMessageReceived instanceof Function) {
        onMessageReceived(message);
    }
}

/*获取客户端类型*/
function getBrowser() {
    let ver;
    const explorer = window.navigator.userAgent.toLowerCase();
    /*IE*/
    if (explorer.indexOf("msie") >= 0) {
        ver = explorer.match(/msie ([\d.]+)/)[1];
        return {name: "IE", version: ver};
    }
    /*FIREFOX*/
    else if (explorer.indexOf("firefox") >= 0) {
        ver = explorer.match(/firefox\/([\d.]+)/)[1];
        return {name: "Firefox", version: ver};
    }
    /*CHROME*/
    else if (explorer.indexOf("chrome") >= 0) {
        ver = explorer.match(/chrome\/([\d.]+)/)[1];
        return {name: "Chrome", version: ver};
    }
    /*OPERA*/
    else if (explorer.indexOf("opera") >= 0) {
        ver = explorer.match(/opera.([\d.]+)/)[1];
        return {name: "Opera", version: ver};
    }
    /*SAFARI*/
    else if (explorer.indexOf("Safari") >= 0) {
        ver = explorer.match(/version\/([\d.]+)/)[1];
        return {name: "Safari", version: ver};
    }
    return {name: "Other", version: "unknown"};
}

/*生成UUID作为客户端ID*/
function generateUUID() {
    let d = new Date().getTime();
    const uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        const r = (d + Math.random() * 16) % 16 | 0;
        d = Math.floor(d / 16);
        return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
    return uuid.replace(/-/g, '');
}
	 