///
//  Generated code. Do not modify.
//  source: SendBody.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class SendBodyModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Model', package: const $pb.PackageName('vip.qsos.im.lib.model.proto'), createEmptyInstance: create)
    ..aOS(1, 'key')
    ..aInt64(2, 'timestamp')
    ..m<$core.String, $core.String>(3, 'data', entryClassName: 'Model.DataEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('vip.qsos.im.lib.model.proto'))
    ..hasRequiredFields = false
  ;

  SendBodyModel._() : super();
  factory SendBodyModel() => create();
  factory SendBodyModel.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SendBodyModel.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  SendBodyModel clone() => SendBodyModel()..mergeFromMessage(this);
  SendBodyModel copyWith(void Function(SendBodyModel) updates) => super.copyWith((message) => updates(message as SendBodyModel));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SendBodyModel create() => SendBodyModel._();
  SendBodyModel createEmptyInstance() => create();
  static $pb.PbList<SendBodyModel> createRepeated() => $pb.PbList<SendBodyModel>();
  @$core.pragma('dart2js:noInline')
  static SendBodyModel getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SendBodyModel>(create);
  static SendBodyModel _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => clearField(2);

  @$pb.TagNumber(3)
  $core.Map<$core.String, $core.String> get data => $_getMap(2);
}

