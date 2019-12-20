///
//  Generated code. Do not modify.
//  source: ReplyBody.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class ReplyModel extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Model', package: const $pb.PackageName('vip.qsos.im.lib.model.proto'), createEmptyInstance: create)
    ..aOS(1, 'key')
    ..aOS(2, 'code')
    ..aOS(3, 'message')
    ..aInt64(4, 'timestamp')
    ..m<$core.String, $core.String>(5, 'data', entryClassName: 'Model.DataEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('vip.qsos.im.lib.model.proto'))
    ..hasRequiredFields = false
  ;

  ReplyModel._() : super();
  factory ReplyModel() => create();
  factory ReplyModel.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReplyModel.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  ReplyModel clone() => ReplyModel()..mergeFromMessage(this);
  ReplyModel copyWith(void Function(ReplyModel) updates) => super.copyWith((message) => updates(message as ReplyModel));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ReplyModel create() => ReplyModel._();
  ReplyModel createEmptyInstance() => create();
  static $pb.PbList<ReplyModel> createRepeated() => $pb.PbList<ReplyModel>();
  @$core.pragma('dart2js:noInline')
  static ReplyModel getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReplyModel>(create);
  static ReplyModel _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get timestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set timestamp($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimestamp() => clearField(4);

  @$pb.TagNumber(5)
  $core.Map<$core.String, $core.String> get data => $_getMap(4);
}

