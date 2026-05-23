import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';


/// 视频视图窗口，用于显示本地视频、远程视频或辅流
///
/// **参数:**
///
/// `onViewCreated`：视图创建后的回调，生成的 `viewId`
class TRTCCloudVideoView extends StatefulWidget {
  static final Set<int> _viewIdSets = {};
  static addViewId(int viewId) {
    if (_viewIdSets.contains(viewId)) { return; }
    _viewIdSets.add(viewId);
  }
  static removeViewId(int viewId) {
    _viewIdSets.remove(viewId);
  }
  static bool containsViewId(int viewId) {
    return _viewIdSets.contains(viewId);
  }

  /// 视图创建后的回调，将会返回一个 `viewId`，这个 `viewId` 用于在 Flutter 中唯一标识一个平台视图
  final ValueChanged<int>? onViewCreated;

  /// 手势识别器，用于处理视图的手势事件
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// [PlatformViewHitTestBehavior] 枚举值，用于指定如何进行点击测试。点击测试是用于确定用户点击或触摸的位置是否在视图内。
  final PlatformViewHitTestBehavior? hitTestBehavior;

  const TRTCCloudVideoView(
      {Key? key,
        this.onViewCreated,
        this.hitTestBehavior,
        this.gestureRecognizers})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TRTCCloudVideoViewState();
}

/// @nodoc
class _TRTCCloudVideoViewState extends State<TRTCCloudVideoView> {
  MethodChannel? _channel;

  int? _textureId;
  int? _viewId;

  int textureWidth = 720;
  int textureHeight = 1280;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || TRTCPlatform.isMacOS) {
      const MethodChannel("TencentRTCffi")
        .invokeMethod("createTextureView")
        .then((value) => {
          setState(() {
            _textureId = value;
            _setTextureAspectRatioListener(value);
            widget.onViewCreated!(_textureId!);
          })
        });
    }
  }

  _setTextureAspectRatioListener(int textureId) {
    MethodChannel("tencent_rtc_texture_$textureId").setMethodCallHandler(
        (call) async {
          switch (call.method) {
            case "updateVideoAspectRatio":
              textureWidth = call.arguments["width"];
              textureHeight = call.arguments["height"];
              break;
            default:
              throw MissingPluginException();
          }
          if (mounted) {
            setState(() {});
          }
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return _getPlatformFaceView();
  }

  Widget _getPlatformFaceView() {
    if (Platform.isAndroid) {
      return AndroidView(
        hitTestBehavior: widget.hitTestBehavior == null ? PlatformViewHitTestBehavior.opaque : widget.hitTestBehavior!,
        viewType: 'TRTCPlatformView',
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: widget.gestureRecognizers,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        hitTestBehavior: widget.hitTestBehavior == null ? PlatformViewHitTestBehavior.opaque : widget.hitTestBehavior!,
        viewType: 'TRTCPlatformView',
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: widget.gestureRecognizers,
      );
    } else if (TRTCPlatform.isOhos) {
      // return OhosView(
      //   hitTestBehavior: widget.hitTestBehavior == null ? PlatformViewHitTestBehavior.opaque : widget.hitTestBehavior!,
      //   gestureRecognizers: widget.gestureRecognizers,
      //   viewType: 'TRTCPlatformView',
      //   onPlatformViewCreated: _onPlatformViewCreated,
      // );
    }
    if (_textureId != null) {
      return _getTRTCTextureView();
    }
    return Container();
  }

  Widget _getTRTCTextureView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerAspectRatio = constraints.maxWidth / constraints.maxHeight;
        final textureAspectRatio = textureWidth / textureHeight;

        return ClipRect(
          child: Transform.scale(
            scale: _getScaleFactor(containerAspectRatio, textureAspectRatio),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: textureWidth.toDouble(),
                height: textureHeight.toDouble(),
                child: Center(
                    child: AspectRatio(
                        aspectRatio: textureAspectRatio,
                        child: Texture(textureId: _textureId!)
                    )
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getScaleFactor(double containerAspectRatio, double textureAspectRatio) {
    return max(containerAspectRatio, textureAspectRatio) / min(containerAspectRatio, textureAspectRatio);
  }

  void _onPlatformViewCreated(int id) async {
    _channel = MethodChannel("TRTCPlatformView_$id");
    if (TRTCPlatform.isOhos) {
      _viewId = id;
      TRTCCloudVideoView.addViewId(_viewId!);
      widget.onViewCreated!(id);
      return;
    }
    int? txView = await _channel!.invokeMethod<int>("getTXView");
    _viewId = txView;
    TRTCCloudVideoView.addViewId(_viewId!);
    widget.onViewCreated!(txView!);
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isMacOS) {
      const MethodChannel("TencentRTCffi")
        .invokeMethod("disposeTextureView", {"textureId" : _textureId!});
    } else if (_viewId != null && (Platform.isAndroid || Platform.isIOS)) {
      TRTCCloudVideoView.removeViewId(_viewId!);
    }
    super.dispose();
  }
}