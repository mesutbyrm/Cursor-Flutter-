// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PostDto {

 String get id; UserEntity get author; String? get caption; String? get mediaUrl; int get likesCount; int get commentsCount; DateTime? get createdAt; String? get fortuneType; int get viewCount; bool get isAutoShare; int get fortuneCount; String? get postType;
/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostDtoCopyWith<PostDto> get copyWith => _$PostDtoCopyWithImpl<PostDto>(this as PostDto, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostDto&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.fortuneType, fortuneType) || other.fortuneType == fortuneType)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.isAutoShare, isAutoShare) || other.isAutoShare == isAutoShare)&&(identical(other.fortuneCount, fortuneCount) || other.fortuneCount == fortuneCount)&&(identical(other.postType, postType) || other.postType == postType));
}


@override
int get hashCode => Object.hash(runtimeType,id,author,caption,mediaUrl,likesCount,commentsCount,createdAt,fortuneType,viewCount,isAutoShare,fortuneCount,postType);

@override
String toString() {
  return 'PostDto(id: $id, author: $author, caption: $caption, mediaUrl: $mediaUrl, likesCount: $likesCount, commentsCount: $commentsCount, createdAt: $createdAt, fortuneType: $fortuneType, viewCount: $viewCount, isAutoShare: $isAutoShare, fortuneCount: $fortuneCount, postType: $postType)';
}


}

/// @nodoc
abstract mixin class $PostDtoCopyWith<$Res>  {
  factory $PostDtoCopyWith(PostDto value, $Res Function(PostDto) _then) = _$PostDtoCopyWithImpl;
@useResult
$Res call({
 String id, UserEntity author, String? caption, String? mediaUrl, int likesCount, int commentsCount, DateTime? createdAt, String? fortuneType, int viewCount, bool isAutoShare, int fortuneCount, String? postType
});




}
/// @nodoc
class _$PostDtoCopyWithImpl<$Res>
    implements $PostDtoCopyWith<$Res> {
  _$PostDtoCopyWithImpl(this._self, this._then);

  final PostDto _self;
  final $Res Function(PostDto) _then;

/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? author = null,Object? caption = freezed,Object? mediaUrl = freezed,Object? likesCount = null,Object? commentsCount = null,Object? createdAt = freezed,Object? fortuneType = freezed,Object? viewCount = null,Object? isAutoShare = null,Object? fortuneCount = null,Object? postType = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as UserEntity,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,fortuneType: freezed == fortuneType ? _self.fortuneType : fortuneType // ignore: cast_nullable_to_non_nullable
as String?,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,isAutoShare: null == isAutoShare ? _self.isAutoShare : isAutoShare // ignore: cast_nullable_to_non_nullable
as bool,fortuneCount: null == fortuneCount ? _self.fortuneCount : fortuneCount // ignore: cast_nullable_to_non_nullable
as int,postType: freezed == postType ? _self.postType : postType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PostDto].
extension PostDtoPatterns on PostDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostDto value)  $default,){
final _that = this;
switch (_that) {
case _PostDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostDto value)?  $default,){
final _that = this;
switch (_that) {
case _PostDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  UserEntity author,  String? caption,  String? mediaUrl,  int likesCount,  int commentsCount,  DateTime? createdAt,  String? fortuneType,  int viewCount,  bool isAutoShare,  int fortuneCount,  String? postType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostDto() when $default != null:
return $default(_that.id,_that.author,_that.caption,_that.mediaUrl,_that.likesCount,_that.commentsCount,_that.createdAt,_that.fortuneType,_that.viewCount,_that.isAutoShare,_that.fortuneCount,_that.postType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  UserEntity author,  String? caption,  String? mediaUrl,  int likesCount,  int commentsCount,  DateTime? createdAt,  String? fortuneType,  int viewCount,  bool isAutoShare,  int fortuneCount,  String? postType)  $default,) {final _that = this;
switch (_that) {
case _PostDto():
return $default(_that.id,_that.author,_that.caption,_that.mediaUrl,_that.likesCount,_that.commentsCount,_that.createdAt,_that.fortuneType,_that.viewCount,_that.isAutoShare,_that.fortuneCount,_that.postType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  UserEntity author,  String? caption,  String? mediaUrl,  int likesCount,  int commentsCount,  DateTime? createdAt,  String? fortuneType,  int viewCount,  bool isAutoShare,  int fortuneCount,  String? postType)?  $default,) {final _that = this;
switch (_that) {
case _PostDto() when $default != null:
return $default(_that.id,_that.author,_that.caption,_that.mediaUrl,_that.likesCount,_that.commentsCount,_that.createdAt,_that.fortuneType,_that.viewCount,_that.isAutoShare,_that.fortuneCount,_that.postType);case _:
  return null;

}
}

}

/// @nodoc


class _PostDto extends PostDto {
  const _PostDto({required this.id, required this.author, this.caption, this.mediaUrl, this.likesCount = 0, this.commentsCount = 0, this.createdAt, this.fortuneType, this.viewCount = 0, this.isAutoShare = false, this.fortuneCount = 0, this.postType}): super._();
  

@override final  String id;
@override final  UserEntity author;
@override final  String? caption;
@override final  String? mediaUrl;
@override@JsonKey() final  int likesCount;
@override@JsonKey() final  int commentsCount;
@override final  DateTime? createdAt;
@override final  String? fortuneType;
@override@JsonKey() final  int viewCount;
@override@JsonKey() final  bool isAutoShare;
@override@JsonKey() final  int fortuneCount;
@override final  String? postType;

/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostDtoCopyWith<_PostDto> get copyWith => __$PostDtoCopyWithImpl<_PostDto>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostDto&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.fortuneType, fortuneType) || other.fortuneType == fortuneType)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.isAutoShare, isAutoShare) || other.isAutoShare == isAutoShare)&&(identical(other.fortuneCount, fortuneCount) || other.fortuneCount == fortuneCount)&&(identical(other.postType, postType) || other.postType == postType));
}


@override
int get hashCode => Object.hash(runtimeType,id,author,caption,mediaUrl,likesCount,commentsCount,createdAt,fortuneType,viewCount,isAutoShare,fortuneCount,postType);

@override
String toString() {
  return 'PostDto(id: $id, author: $author, caption: $caption, mediaUrl: $mediaUrl, likesCount: $likesCount, commentsCount: $commentsCount, createdAt: $createdAt, fortuneType: $fortuneType, viewCount: $viewCount, isAutoShare: $isAutoShare, fortuneCount: $fortuneCount, postType: $postType)';
}


}

/// @nodoc
abstract mixin class _$PostDtoCopyWith<$Res> implements $PostDtoCopyWith<$Res> {
  factory _$PostDtoCopyWith(_PostDto value, $Res Function(_PostDto) _then) = __$PostDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, UserEntity author, String? caption, String? mediaUrl, int likesCount, int commentsCount, DateTime? createdAt, String? fortuneType, int viewCount, bool isAutoShare, int fortuneCount, String? postType
});




}
/// @nodoc
class __$PostDtoCopyWithImpl<$Res>
    implements _$PostDtoCopyWith<$Res> {
  __$PostDtoCopyWithImpl(this._self, this._then);

  final _PostDto _self;
  final $Res Function(_PostDto) _then;

/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? author = null,Object? caption = freezed,Object? mediaUrl = freezed,Object? likesCount = null,Object? commentsCount = null,Object? createdAt = freezed,Object? fortuneType = freezed,Object? viewCount = null,Object? isAutoShare = null,Object? fortuneCount = null,Object? postType = freezed,}) {
  return _then(_PostDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as UserEntity,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,fortuneType: freezed == fortuneType ? _self.fortuneType : fortuneType // ignore: cast_nullable_to_non_nullable
as String?,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,isAutoShare: null == isAutoShare ? _self.isAutoShare : isAutoShare // ignore: cast_nullable_to_non_nullable
as bool,fortuneCount: null == fortuneCount ? _self.fortuneCount : fortuneCount // ignore: cast_nullable_to_non_nullable
as int,postType: freezed == postType ? _self.postType : postType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
