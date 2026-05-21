// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_stream_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LiveStreamDto {

 String get id; String get title; String? get streamerName; String? get thumbnailUrl; int get viewerCount; bool get isLive; String? get hostUserId;
/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveStreamDtoCopyWith<LiveStreamDto> get copyWith => _$LiveStreamDtoCopyWithImpl<LiveStreamDto>(this as LiveStreamDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveStreamDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.streamerName, streamerName) || other.streamerName == streamerName)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.viewerCount, viewerCount) || other.viewerCount == viewerCount)&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.hostUserId, hostUserId) || other.hostUserId == hostUserId));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,streamerName,thumbnailUrl,viewerCount,isLive,hostUserId);

@override
String toString() {
  return 'LiveStreamDto(id: $id, title: $title, streamerName: $streamerName, thumbnailUrl: $thumbnailUrl, viewerCount: $viewerCount, isLive: $isLive, hostUserId: $hostUserId)';
}


}

/// @nodoc
abstract mixin class $LiveStreamDtoCopyWith<$Res>  {
  factory $LiveStreamDtoCopyWith(LiveStreamDto value, $Res Function(LiveStreamDto) _then) = _$LiveStreamDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? streamerName, String? thumbnailUrl, int viewerCount, bool isLive, String? hostUserId
});




}
/// @nodoc
class _$LiveStreamDtoCopyWithImpl<$Res>
    implements $LiveStreamDtoCopyWith<$Res> {
  _$LiveStreamDtoCopyWithImpl(this._self, this._then);

  final LiveStreamDto _self;
  final $Res Function(LiveStreamDto) _then;

/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? streamerName = freezed,Object? thumbnailUrl = freezed,Object? viewerCount = null,Object? isLive = null,Object? hostUserId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,streamerName: freezed == streamerName ? _self.streamerName : streamerName // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,viewerCount: null == viewerCount ? _self.viewerCount : viewerCount // ignore: cast_nullable_to_non_nullable
as int,isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,hostUserId: freezed == hostUserId ? _self.hostUserId : hostUserId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveStreamDto].
extension LiveStreamDtoPatterns on LiveStreamDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveStreamDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveStreamDto value)  $default,){
final _that = this;
switch (_that) {
case _LiveStreamDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveStreamDto value)?  $default,){
final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? streamerName,  String? thumbnailUrl,  int viewerCount,  bool isLive,  String? hostUserId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
return $default(_that.id,_that.title,_that.streamerName,_that.thumbnailUrl,_that.viewerCount,_that.isLive,_that.hostUserId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? streamerName,  String? thumbnailUrl,  int viewerCount,  bool isLive,  String? hostUserId)  $default,) {final _that = this;
switch (_that) {
case _LiveStreamDto():
return $default(_that.id,_that.title,_that.streamerName,_that.thumbnailUrl,_that.viewerCount,_that.isLive,_that.hostUserId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? streamerName,  String? thumbnailUrl,  int viewerCount,  bool isLive,  String? hostUserId)?  $default,) {final _that = this;
switch (_that) {
case _LiveStreamDto() when $default != null:
return $default(_that.id,_that.title,_that.streamerName,_that.thumbnailUrl,_that.viewerCount,_that.isLive,_that.hostUserId);case _:
  return null;

}
}

}

/// @nodoc


class _LiveStreamDto extends LiveStreamDto {
  const _LiveStreamDto({required this.id, this.title = 'Canlı yayın', this.streamerName, this.thumbnailUrl, this.viewerCount = 0, this.isLive = true, this.hostUserId}): super._();
  

@override final  String id;
@override@JsonKey() final  String title;
@override final  String? streamerName;
@override final  String? thumbnailUrl;
@override@JsonKey() final  int viewerCount;
@override@JsonKey() final  bool isLive;
@override final  String? hostUserId;

/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveStreamDtoCopyWith<_LiveStreamDto> get copyWith => __$LiveStreamDtoCopyWithImpl<_LiveStreamDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveStreamDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.streamerName, streamerName) || other.streamerName == streamerName)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.viewerCount, viewerCount) || other.viewerCount == viewerCount)&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.hostUserId, hostUserId) || other.hostUserId == hostUserId));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,streamerName,thumbnailUrl,viewerCount,isLive,hostUserId);

@override
String toString() {
  return 'LiveStreamDto(id: $id, title: $title, streamerName: $streamerName, thumbnailUrl: $thumbnailUrl, viewerCount: $viewerCount, isLive: $isLive, hostUserId: $hostUserId)';
}


}

/// @nodoc
abstract mixin class _$LiveStreamDtoCopyWith<$Res> implements $LiveStreamDtoCopyWith<$Res> {
  factory _$LiveStreamDtoCopyWith(_LiveStreamDto value, $Res Function(_LiveStreamDto) _then) = __$LiveStreamDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? streamerName, String? thumbnailUrl, int viewerCount, bool isLive, String? hostUserId
});




}
/// @nodoc
class __$LiveStreamDtoCopyWithImpl<$Res>
    implements _$LiveStreamDtoCopyWith<$Res> {
  __$LiveStreamDtoCopyWithImpl(this._self, this._then);

  final _LiveStreamDto _self;
  final $Res Function(_LiveStreamDto) _then;

/// Create a copy of LiveStreamDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? streamerName = freezed,Object? thumbnailUrl = freezed,Object? viewerCount = null,Object? isLive = null,Object? hostUserId = freezed,}) {
  return _then(_LiveStreamDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,streamerName: freezed == streamerName ? _self.streamerName : streamerName // ignore: cast_nullable_to_non_nullable
as String?,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,viewerCount: null == viewerCount ? _self.viewerCount : viewerCount // ignore: cast_nullable_to_non_nullable
as int,isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,hostUserId: freezed == hostUserId ? _self.hostUserId : hostUserId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
