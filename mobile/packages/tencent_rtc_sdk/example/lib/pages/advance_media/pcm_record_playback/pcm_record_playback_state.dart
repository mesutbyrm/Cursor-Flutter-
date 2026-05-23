import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:tencent_rtc_sdk/trtc_cloud.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_def.dart';
import 'package:tencent_rtc_sdk/trtc_cloud_listener.dart';
import 'package:api_example/debug/generate_test_user_sig.dart';

class PcmRecordPlaybackState extends ChangeNotifier {
  final String userId;
  final String roomId;
  
  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';
  bool _isEnterRoomSuccess = false;
  
  // PCM录制相关状态
  bool _isRecording = false;
  File? _pcmFile;
  IOSink? _pcmSink;
  int _recordedBytes = 0;
  String _recordingStatus = 'Ready to record';
  
  // PCM播放相关状态
  bool _isPlaying = false;
  String? _lastRecordedFilePath;
  
  // 当前录制的音频参数（每次录制独立）
  int _currentRecordingSampleRate = 0;
  int _currentRecordingChannels = 0;
  bool _audioParamsLocked = false;  // 锁定后不再更新参数
  
  // 录制源选择
  PcmRecordSource _recordSource = PcmRecordSource.localProcessed;
  
  // 录制文件列表
  final List<RecordedFile> _recordedFiles = [];

  TRTCCloud? _trtcCloud;
  TRTCCloudListener? _listener;
  bool _audioCallbackRegistered = false;  // 标记回调是否已注册

  PcmRecordPlaybackState({
    required this.userId,
    required this.roomId,
  }) {
    _initialize();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  String get statusMessage => _statusMessage;
  bool get isEnterRoomSuccess => _isEnterRoomSuccess;
  bool get isRecording => _isRecording;
  int get recordedBytes => _recordedBytes;
  String get recordingStatus => _recordingStatus;
  bool get isPlaying => _isPlaying;
  bool get hasRecordedFile => _lastRecordedFilePath != null;
  PcmRecordSource get recordSource => _recordSource;
  List<RecordedFile> get recordedFiles => List.unmodifiable(_recordedFiles);

  Future<void> _initialize() async {
    try {
      await _initializeTRTC();
      _isInitialized = true;
      _statusMessage = 'Room is ready';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Initialization failed: $e';
      notifyListeners();
    }
  }

  Future<void> _initializeTRTC() async {
    if (_trtcCloud == null) {
      _trtcCloud = await TRTCCloud.sharedInstance();
      _isInitialized = true;
    }
    _listener ??= _getTRTCCloudListener();
    if (_listener != null) {
      _trtcCloud?.registerListener(_listener!);
    }

    _statusMessage = 'Entering room...';
    _trtcCloud?.enterRoom(TRTCParams(
      sdkAppId: GenerateTestUserSig.sdkAppId,
      userId: userId,
      roomId: int.parse(roomId),
      role: TRTCRoleType.anchor,
      userSig: GenerateTestUserSig.genTestSig(userId)
    ), TRTCAppScene.voiceChatRoom);

    _trtcCloud?.startLocalAudio(TRTCAudioQuality.music);
  }

  void _setupAudioFrameCallback() {
    if (_audioCallbackRegistered) return;
    _audioCallbackRegistered = true;
    
    final audioFrameCallback = TRTCAudioFrameCallback(
      onCapturedAudioFrame: (frame) {
        if (_recordSource == PcmRecordSource.captured && _isRecording && _pcmSink != null) {
          _updateAudioParams(frame.sampleRate, frame.channel);
          _writePcmData(frame.data, frame.length);
        }
      },
      onLocalProcessedAudioFrame: (frame) {
        if (_recordSource == PcmRecordSource.localProcessed && _isRecording && _pcmSink != null) {
          _updateAudioParams(frame.sampleRate, frame.channel);
          _writePcmData(frame.data, frame.length);
        }
      },
      onPlayAudioFrame: (frame, userId) {
        // 远程用户音频数据 - 暂不使用
      },
      onMixedPlayAudioFrame: (frame) {
        if (_recordSource == PcmRecordSource.mixedPlay && _isRecording && _pcmSink != null) {
          _updateAudioParams(frame.sampleRate, frame.channel);
          _writePcmData(frame.data, frame.length);
        }
      },
      onMixedAllAudioFrame: (frame) {
        if (_recordSource == PcmRecordSource.mixedAll && _isRecording && _pcmSink != null) {
          _updateAudioParams(frame.sampleRate, frame.channel);
          _writePcmData(frame.data, frame.length);
        }
      },
    );
    
    _trtcCloud?.setAudioFrameCallback(audioFrameCallback);
  }

  void _updateAudioParams(int sampleRate, int channel) {
    if (_audioParamsLocked) return;
    if (sampleRate > 0 && _currentRecordingSampleRate == 0) {
      _currentRecordingSampleRate = sampleRate;
    }
    if (channel > 0 && _currentRecordingChannels == 0) {
      _currentRecordingChannels = channel;
    }
    if (_currentRecordingSampleRate > 0 && _currentRecordingChannels > 0) {
      _audioParamsLocked = true;
    }
  }

  void _writePcmData(Uint8List data, int expectedLength) {
    if (_pcmSink == null) return;
    try {
      final int actualLength = data.length < expectedLength ? data.length : expectedLength;
      final writeData = actualLength == data.length ? data : data.sublist(0, actualLength);
      _pcmSink!.add(writeData);
      _recordedBytes += writeData.length;
      notifyListeners();
    } catch (e) {
      _recordingStatus = 'Write error: $e';
      notifyListeners();
    }
  }

  void updateRecordSource(PcmRecordSource source) {
    if (_recordSource != source && !_isRecording) {
      _recordSource = source;
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    
    // 确保回调已注册（只注册一次）
    _setupAudioFrameCallback();
    
    // 重置音频参数，等待从第一帧回调中获取
    _currentRecordingSampleRate = 0;
    _currentRecordingChannels = 0;
    _audioParamsLocked = false;
    
    try {
      final directory = await _getRecordingDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sourceName = _recordSource.name;
      final filePath = '${directory.path}/pcm_${sourceName}_$timestamp.pcm';
      
      _pcmFile = File(filePath);
      _pcmSink = _pcmFile!.openWrite(mode: FileMode.write);
      _isRecording = true;
      _recordedBytes = 0;
      _recordingStatus = 'Recording from ${_recordSource.displayName}...';
      
      notifyListeners();
    } catch (e) {
      _recordingStatus = 'Start recording failed: $e';
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    _isRecording = false;
    _audioParamsLocked = true;
    
    final finalSampleRate = _currentRecordingSampleRate > 0 ? _currentRecordingSampleRate : 48000;
    final finalChannels = _currentRecordingChannels > 0 ? _currentRecordingChannels : 1;
    
    final sinkToClose = _pcmSink;
    _pcmSink = null;
    
    try {
      await sinkToClose?.flush();
      await sinkToClose?.close();
      _lastRecordedFilePath = _pcmFile?.path;
      
      if (_pcmFile != null) {
        _recordedFiles.add(RecordedFile(
          filePath: _pcmFile!.path,
          source: _recordSource,
          size: _recordedBytes,
          timestamp: DateTime.now(),
          sampleRate: finalSampleRate,
          channels: finalChannels,
        ));
      }
      
      _recordingStatus = 'Recording saved (${finalSampleRate}Hz, ${finalChannels}ch)';
      notifyListeners();
    } catch (e) {
      _recordingStatus = 'Stop recording failed: $e';
      notifyListeners();
    }
  }

  Future<void> startPlayback([RecordedFile? recordedFile]) async {
    final targetPath = recordedFile?.filePath ?? _lastRecordedFilePath;
    if (_isPlaying || targetPath == null) return;
    
    int playbackSampleRate = 48000;
    int playbackChannels = 1;
    
    RecordedFile? targetFile = recordedFile;
    if (targetFile == null && _recordedFiles.isNotEmpty) {
      targetFile = _recordedFiles.where((f) => f.filePath == targetPath).firstOrNull ?? _recordedFiles.last;
    }
    
    if (targetFile != null) {
      playbackSampleRate = targetFile.sampleRate;
      playbackChannels = targetFile.channels;
    }
    
    try {
      final file = File(targetPath);
      if (!await file.exists()) {
        _recordingStatus = 'Recorded file not found';
        notifyListeners();
        return;
      }
      
      await FlutterPcmSound.release();
      await FlutterPcmSound.setup(
        sampleRate: playbackSampleRate,
        channelCount: playbackChannels,
      );
      FlutterPcmSound.setFeedCallback(_onFeedCallback);
      
      _isPlaying = true;
      _recordingStatus = 'Playing (${playbackSampleRate}Hz, ${playbackChannels}ch)...';
      notifyListeners();
      
      final pcmData = await file.readAsBytes();
      _playPcmData(pcmData, playbackChannels);
    } catch (e) {
      _recordingStatus = 'Playback failed: $e';
      _isPlaying = false;
      notifyListeners();
    }
  }
  
  Uint8List? _pcmPlaybackData;
  int _pcmPlaybackOffset = 0;
  int _playbackChannels = 1;
  static const int _feedChunkSize = 8192;
  
  void _playPcmData(Uint8List pcmData, int channels) {
    _pcmPlaybackData = pcmData;
    _pcmPlaybackOffset = 0;
    _playbackChannels = channels;
    _feedNextChunk();
  }
  
  void _feedNextChunk() {
    if (_pcmPlaybackData == null || !_isPlaying) return;
    
    if (_pcmPlaybackOffset >= _pcmPlaybackData!.length) {
      _onPlaybackComplete();
      return;
    }
    
    final remaining = _pcmPlaybackData!.length - _pcmPlaybackOffset;
    final bytesPerFrame = 2 * _playbackChannels;
    int chunkSize = remaining < _feedChunkSize ? remaining : _feedChunkSize;
    chunkSize = (chunkSize ~/ bytesPerFrame) * bytesPerFrame;
    
    if (chunkSize <= 0) {
      _onPlaybackComplete();
      return;
    }
    
    final chunk = Uint8List.fromList(
      _pcmPlaybackData!.sublist(_pcmPlaybackOffset, _pcmPlaybackOffset + chunkSize)
    );
    final int16Data = chunk.buffer.asInt16List();
    FlutterPcmSound.feed(PcmArrayInt16.fromList(int16Data));
    _pcmPlaybackOffset += chunkSize;
  }
  
  void _onFeedCallback(int remainingFrames) {
    final samplesPerChunk = _feedChunkSize ~/ (2 * _playbackChannels);
    if (remainingFrames < samplesPerChunk) {
      _feedNextChunk();
    }
  }
  
  void _onPlaybackComplete() async {
    _isPlaying = false;
    _pcmPlaybackData = null;
    _pcmPlaybackOffset = 0;
    _playbackChannels = 1;
    _recordingStatus = 'Playback completed';
    await FlutterPcmSound.release();
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    if (!_isPlaying) return;
    
    _isPlaying = false;
    _pcmPlaybackData = null;
    _pcmPlaybackOffset = 0;
    _playbackChannels = 1;
    await FlutterPcmSound.release();
    _recordingStatus = 'Playback stopped';
    notifyListeners();
  }

  Future<void> deleteRecordedFile(RecordedFile file) async {
    try {
      final f = File(file.filePath);
      if (await f.exists()) {
        await f.delete();
      }
      _recordedFiles.remove(file);
      if (_lastRecordedFilePath == file.filePath) {
        _lastRecordedFilePath = _recordedFiles.isNotEmpty ? _recordedFiles.last.filePath : null;
      }
      _recordingStatus = 'File deleted';
      notifyListeners();
    } catch (e) {
      _recordingStatus = 'Delete failed: $e';
      notifyListeners();
    }
  }

  Future<Directory> _getRecordingDirectory() async {
    final directory = Directory.systemTemp;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  TRTCCloudListener _getTRTCCloudListener() {
    return TRTCCloudListener(
      onError: (errorCode, errorMsg) {
        _statusMessage = 'Error: $errorMsg';
        notifyListeners();
      },
      onEnterRoom: (result) {
        if (result > 0) {
          _statusMessage = 'Room entered successfully';
          _isEnterRoomSuccess = true;
        } else {
          _statusMessage = 'Failed to enter room: $result';
          _isEnterRoomSuccess = false;
        }
        notifyListeners();
      },
      onRemoteUserEnterRoom: (userId) {
        _statusMessage = 'User $userId joined the room';
        notifyListeners();
      },
      onRemoteUserLeaveRoom: (userId, reason) {
        _statusMessage = 'User $userId left the room';
        notifyListeners();
      },
    );
  }

  Future<void> exitRoom() async {
    try {
      if (_isRecording) {
        await stopRecording();
      }
      if (_isPlaying) {
        await stopPlayback();
      }
      _isInitialized = false;
      _statusMessage = 'Room exited';
      if (_trtcCloud != null) {
        _trtcCloud?.exitRoom();
      }
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Failed to exit room: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isRecording) {
      stopRecording();
    }
    if (_isPlaying) {
      stopPlayback();
    }
    TRTCCloud.destroySharedInstance();
    super.dispose();
  }
}

enum PcmRecordSource {
  captured('Captured', 'Raw captured audio'),
  localProcessed('Local Processed', 'Processed local audio'),
  mixedPlay('Mixed Play', 'Mixed playback audio'),
  mixedAll('Mixed All', 'All mixed audio');

  final String displayName;
  final String description;
  
  const PcmRecordSource(this.displayName, this.description);
}

class RecordedFile {
  final String filePath;
  final PcmRecordSource source;
  final int size;
  final DateTime timestamp;
  final int sampleRate;
  final int channels;

  RecordedFile({
    required this.filePath,
    required this.source,
    required this.size,
    required this.timestamp,
    this.sampleRate = 48000,
    this.channels = 1,
  });

  String get fileName => filePath.split('/').last;
  String get sizeStr => '${(size / 1024).toStringAsFixed(1)} KB';
  String get formatStr => '${sampleRate}Hz ${channels}ch';
}
