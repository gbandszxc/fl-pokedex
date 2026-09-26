import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 图鉴说明本地朗读（任务 D）。
///
/// 引擎 = flutter_tts（Android TextToSpeech / Windows SAPI / Apple
/// AVSpeechSynthesizer，全部平台本地合成，纯 MethodChannel 无 HTTP，
/// 满足运行时 0 网络红线）。
///
/// 生命周期约定：
/// - 引擎为应用级单例（[flutterTtsProvider]）；其构造只注册 platform
///   回调、不发通道消息，故按钮挂载期对引擎零扰动；
/// - 朗读状态由 [speakControllerProvider]（autoDispose）承载：按钮卸载
///   （页面退出）即 dispose 并 stop；文本变化（切物种 / 形态 / 版本）
///   由 [SpeakButton.didUpdateWidget] 主动 stop；
/// - 状态推进只信平台事件（onStart / onComplete / onCancel / onError）
///   与调用结果码，不依赖 speak() 的完成语义（不开启
///   awaitSpeakCompletion，避免引擎初始化期的额外通道调用）。

/// 应用级 flutter_tts 引擎单例。
final flutterTtsProvider = Provider<FlutterTts>((ref) => FlutterTts());

/// 「当前设备没有可用的语音引擎」是否已提示过：
/// 应用会话内只提示一次，避免无语音设备反复点按刷屏。
final speakErrorAnnouncedProvider = StateProvider<bool>((ref) => false);

/// 朗读阶段。
enum SpeakPhase { idle, speaking }

/// 朗读状态：阶段 + 错误提示事件计数（errorTick 递增一次 = 请求 UI
/// 提示一次；去重判定在控制器内完成）。
class SpeakState {
  const SpeakState({
    required this.phase,
    this.errorTick = 0,
  });

  final SpeakPhase phase;

  final int errorTick;

  bool get isSpeaking => phase == SpeakPhase.speaking;
}

/// 朗读状态控制器（autoDispose：按钮卸载即 dispose 并停止引擎）。
final speakControllerProvider =
    NotifierProvider.autoDispose<SpeakController, SpeakState>(
  SpeakController.new,
);

/// 朗读控制器。
///
/// 以世代计数（[_generation]）使 stop / dispose 之后的 in-flight 朗读
/// 序列失效，防「stop 后延迟返回的 setLanguage / speak 结果」覆盖新状态
/// （连续快速 stop→speak 的竞态）。
class SpeakController extends AutoDisposeNotifier<SpeakState> {
  int _generation = 0;
  bool _active = true;

  @override
  SpeakState build() {
    _active = true;
    _generation++;
    final tts = ref.read(flutterTtsProvider);
    ref.onDispose(() {
      _active = false;
      _generation++;
      // 引擎侧兜底停：dispose 时无论状态如何都停（通道异常吞掉，
      // 测试 / 无插件环境下不会产生未处理异常）。
      unawaited(tts.stop().then((_) {}, onError: (_) {}));
      // handler 是引擎上的单槽回调，置空防触及已销毁控制器
      // （下一个控制器实例会在 build 里重新注册）。
      tts.startHandler = null;
      tts.completionHandler = null;
      tts.cancelHandler = null;
      tts.errorHandler = null;
    });
    tts.setStartHandler(() {
      if (_active) {
        state = _withPhase(SpeakPhase.speaking);
      }
    });
    tts.setCompletionHandler(() {
      if (_active) {
        state = _withPhase(SpeakPhase.idle);
      }
    });
    tts.setCancelHandler(() {
      if (_active) {
        state = _withPhase(SpeakPhase.idle);
      }
    });
    tts.setErrorHandler((message) {
      if (_active) {
        _fail();
      }
    });
    return const SpeakState(phase: SpeakPhase.idle);
  }

  /// 点击朗读（幂等：朗读中忽略，停止走 [stop]）。
  ///
  /// 空文本不动作——部分平台空串会崩（flutter_tts#508，macOS）。
  Future<void> speak(String text, String ttsLanguage) async {
    if (!_active || state.isSpeaking) {
      return;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final tts = ref.read(flutterTtsProvider);
    final generation = _generation;
    // 乐观进入朗读态：引擎启动可达数百 ms，先给出「停止」反馈；
    // 失败路径立即回退空闲。
    state = _withPhase(SpeakPhase.speaking);
    try {
      // 结果码：1=成功，0=该语言无可用语音（静默失败，无异常）。
      final languageResult = await tts.setLanguage(ttsLanguage);
      if (generation != _generation) {
        return; // 期间已 stop / 控制器已销毁。
      }
      if (languageResult != 1) {
        _fail();
        return;
      }
      // 结果码：1=已开始 / 已排队，0=失败或被引擎丢弃。
      final result = await tts.speak(trimmed);
      if (generation != _generation) {
        return;
      }
      if (result != 1) {
        _fail();
      }
    } on Object catch (error) {
      // 通道级异常（引擎异常终止等）：按「引擎不可用」兜底，不冒泡。
      if (generation == _generation && _active) {
        debugPrint('SpeakButton TTS error: $error');
        _fail();
      }
    }
  }

  /// 停止朗读（幂等；空闲时不打扰引擎）。
  Future<void> stop() async {
    if (!_active || !state.isSpeaking) {
      return;
    }
    _generation++;
    state = _withPhase(SpeakPhase.idle);
    try {
      await ref.read(flutterTtsProvider).stop();
    } on Object {
      // 平台侧停止失败无从恢复（Dart 状态已回空闲），吞掉通道级异常。
    }
  }

  /// 失败回空闲；提示事件按会话去重（无语音设备反复点按不刷屏）。
  void _fail() {
    final announced = ref.read(speakErrorAnnouncedProvider);
    state = SpeakState(
      phase: SpeakPhase.idle,
      errorTick: announced ? state.errorTick : state.errorTick + 1,
    );
    if (!announced) {
      ref.read(speakErrorAnnouncedProvider.notifier).state = true;
    }
  }

  SpeakState _withPhase(SpeakPhase phase) => SpeakState(
        phase: phase,
        errorTick: state.errorTick,
      );
}

/// 图鉴文本语言（flavor_entries.language）→ BCP-47 语音码。
///
/// 各平台引擎均按此格式匹配语音（zh_hans→zh-CN、zh_hant→zh-TW、
/// en→en-US、ja→ja-JP）；超出已知语言时返回 null（UI 不渲染按钮）。
String? ttsLanguageCode(String dataLanguage) => switch (dataLanguage) {
      'zh_hans' => 'zh-CN',
      'zh_hant' => 'zh-TW',
      'en' => 'en-US',
      'ja' => 'ja-JP',
      _ => null,
    };

/// 图鉴说明朗读按钮：点击朗读 [text]，再点停止。
///
/// - 朗读中：stop 图标 + primary 高亮（色取 ColorScheme，无硬编码）；
/// - 文本 / 语言变化（物种 / 形态 / 版本切换）自动停止；
/// - 卸载（页面退出）经控制器 autoDispose 自动停止。
class SpeakButton extends ConsumerStatefulWidget {
  const SpeakButton({
    super.key,
    required this.text,
    required this.language,
  });

  /// 朗读的文本 = 当前显示的图鉴说明。
  final String text;

  /// 文本语言（flavor text 的 language 值，如 zh_hans）。
  final String language;

  @override
  ConsumerState<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends ConsumerState<SpeakButton> {
  @override
  void didUpdateWidget(covariant SpeakButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.language != widget.language) {
      // 朗读对象已变：立即停止（下一段文本是否可读由新一轮交互决定）。
      // didUpdateWidget 处于 widget 树构建阶段，Riverpod 禁止在此时同步
      // 修改 provider 状态（stop 内部要置 state），故推迟到构建栈结束后。
      scheduleMicrotask(() {
        if (mounted) {
          unawaited(ref.read(speakControllerProvider.notifier).stop());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final speak = ref.watch(speakControllerProvider);
    // 错误提示：errorTick 递增即请求一次 SnackBar（会话内去重在控制器）。
    ref.listen<SpeakState>(speakControllerProvider, (previous, next) {
      if (previous != null && next.errorTick != previous.errorTick) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('当前设备没有可用的语音引擎')),
          );
      }
    });

    return IconButton(
      tooltip: speak.isSpeaking ? '停止朗读' : '朗读图鉴说明',
      onPressed: () {
        final controller = ref.read(speakControllerProvider.notifier);
        final ttsLanguage = ttsLanguageCode(widget.language);
        if (ttsLanguage == null) {
          return;
        }
        if (speak.isSpeaking) {
          unawaited(controller.stop());
        } else {
          unawaited(controller.speak(widget.text, ttsLanguage));
        }
      },
      icon: Icon(
        speak.isSpeaking ? Icons.stop : Icons.volume_up,
        color: speak.isSpeaking ? Theme.of(context).colorScheme.primary : null,
      ),
    );
  }
}
