import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/core/update/update_flow.dart';
import 'package:fl_pokedex/core/update/update_installer.dart';
import 'package:fl_pokedex/core/update/update_progress.dart';
import 'package:fl_pokedex/core/update/update_providers.dart';
import 'package:fl_pokedex/core/update/update_service.dart';

import '../../helpers/fake_update_service.dart';

/// 更新流程用例：检查反馈 → 确认对话框 → 下载进度模态 → 拉起安装器。
///
/// 全部走 [FakeUpdateService] / [FakeUpdateInstaller]，不触网、不碰平台通道。
void main() {
  Future<ProviderContainer> pumpFlowHost(
    WidgetTester tester, {
    required FakeUpdateService service,
    required FakeUpdateInstaller installer,
    bool silent = false,
  }) async {
    final container = ProviderContainer(
      overrides: [
        updateServiceProvider.overrideWithValue(service),
        updateInstallerProvider.overrideWithValue(installer),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => runUpdateCheckFlow(
                  context,
                  ref,
                  currentVersion: '1.0.0',
                  silent: silent,
                ),
                child: const Text('检查更新'),
              ),
            ),
          ),
        ),
      ),
    );
    return container;
  }

  Future<void> tapCheck(WidgetTester tester) async {
    await tester.tap(find.text('检查更新'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('已是最新：手动检查给 SnackBar 反馈，不弹更新对话框', (tester) async {
    final service = FakeUpdateService();
    await pumpFlowHost(
      tester,
      service: service,
      installer: FakeUpdateInstaller(),
    );

    await tapCheck(tester);

    expect(find.text('已是最新版本'), findsOneWidget);
    expect(find.text('发现新版本 1.1.0'), findsNothing);
    expect(service.lastCheckedVersion, '1.0.0');
  });

  testWidgets('已是最新：启动静默检查不打扰用户', (tester) async {
    final service = FakeUpdateService();
    await pumpFlowHost(
      tester,
      service: service,
      installer: FakeUpdateInstaller(),
      silent: true,
    );

    await tapCheck(tester);

    expect(find.text('已是最新版本'), findsNothing);
    expect(service.checkCalls, 1);
  });

  testWidgets('检查失败：手动检查提示原因', (tester) async {
    final service = FakeUpdateService(
      checkResult: const UpdateCheckFailed('网络连接失败'),
    );
    await pumpFlowHost(
      tester,
      service: service,
      installer: FakeUpdateInstaller(),
    );
    await tapCheck(tester);
    expect(find.text('检查更新失败：网络连接失败'), findsOneWidget);
  });

  testWidgets('检查失败：启动静默检查无反馈', (tester) async {
    final service = FakeUpdateService(
      checkResult: const UpdateCheckFailed('网络连接失败'),
    );
    await pumpFlowHost(
      tester,
      service: service,
      installer: FakeUpdateInstaller(),
      silent: true,
    );
    await tapCheck(tester);
    expect(find.textContaining('检查更新失败'), findsNothing);
  });

  testWidgets('有新版本：对话框展示当前/最新版本与自动选中的安装包，稍后不下载', (tester) async {
    final service = FakeUpdateService(
      checkResult: UpdateAvailable(fakeRelease()),
    );
    final installer = FakeUpdateInstaller();
    await pumpFlowHost(tester, service: service, installer: installer);

    await tapCheck(tester);

    expect(find.text('发现新版本 1.1.0'), findsOneWidget);
    expect(find.text('当前版本'), findsOneWidget);
    expect(find.text('1.0.0'), findsOneWidget);
    expect(find.text('适用平台'), findsOneWidget);
    expect(find.text('Fl-PokeDex-1.1.0-x86_64-release.apk'), findsOneWidget);

    await tester.tap(find.text('稍后'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(service.downloadCalls, 0);
    expect(installer.openedFiles, isEmpty);
    expect(find.text('发现新版本 1.1.0'), findsNothing);
  });

  testWidgets('确认下载：模态回显已下载/总量与速度，完成后拉起安装器', (tester) async {
    final gate = Completer<void>();
    final service = FakeUpdateService(
      checkResult: UpdateAvailable(fakeRelease()),
      progressScript: const [
        UpdateProgress(received: 0, total: 84 * 1024 * 1024, bytesPerSecond: 0),
        UpdateProgress(
          received: 12 * 1024 * 1024,
          total: 84 * 1024 * 1024,
          bytesPerSecond: 4.2 * 1024 * 1024,
        ),
      ],
    )..downloadGate = gate;
    final installer = FakeUpdateInstaller();
    await pumpFlowHost(tester, service: service, installer: installer);

    await tapCheck(tester);
    await tester.tap(find.text('下载并安装'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 进度模态：文件名 + 进度条 + 字节/速度文案。
    expect(find.text('正在下载更新'), findsOneWidget);
    expect(find.text('Fl-PokeDex-1.1.0-x86_64-release.apk'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('12.0 MB / 84.0 MB'), findsOneWidget);
    expect(find.textContaining('4.2 MB/s'), findsOneWidget);
    expect(installer.openedFiles, isEmpty);

    gate.complete();
    await tester.pumpAndSettle();

    expect(service.downloadCalls, 1);
    expect(installer.openedFiles, hasLength(1));
    expect(find.text('正在下载更新'), findsNothing);
    // Windows 会提示应用将退出（安装器要替换运行中的 exe），其余平台为通用文案。
    expect(
      find.text(
        Platform.isWindows ? '安装程序已打开，应用将退出以完成更新' : '已打开安装程序，请按提示完成更新',
      ),
      findsOneWidget,
    );
  });

  testWidgets('命中缓存：跳过下载直接安装（权限补齐后重试场景）', (tester) async {
    final service = FakeUpdateService(
      checkResult: UpdateAvailable(fakeRelease()),
      cachedFile: File('cached.apk'),
    );
    final installer = FakeUpdateInstaller();
    await pumpFlowHost(tester, service: service, installer: installer);

    await tapCheck(tester);
    await tester.tap(find.text('下载并安装'));
    await tester.pumpAndSettle();

    expect(service.downloadCalls, 0);
    expect(installer.openedFiles, hasLength(1));
  });

  testWidgets('取消下载：模态关闭、不安装、提示已取消', (tester) async {
    final gate = Completer<void>();
    final service = FakeUpdateService(
      checkResult: UpdateAvailable(fakeRelease()),
    )..downloadGate = gate;
    final installer = FakeUpdateInstaller();
    await pumpFlowHost(tester, service: service, installer: installer);

    await tapCheck(tester);
    await tester.tap(find.text('下载并安装'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('取消'));
    gate.complete();
    await tester.pumpAndSettle();

    expect(installer.openedFiles, isEmpty);
    expect(find.text('已取消下载'), findsOneWidget);
  });

  testWidgets('下载失败：提示原因且不安装', (tester) async {
    final service = FakeUpdateService(
      checkResult: UpdateAvailable(fakeRelease()),
      downloadError: SocketException('connection reset'),
    );
    final installer = FakeUpdateInstaller();
    await pumpFlowHost(tester, service: service, installer: installer);

    await tapCheck(tester);
    await tester.tap(find.text('下载并安装'));
    await tester.pumpAndSettle();

    expect(find.text('下载失败：网络连接失败'), findsOneWidget);
    expect(installer.openedFiles, isEmpty);
  });

  testWidgets('无安装权限：弹窗引导去系统设置', (tester) async {
    final service = FakeUpdateService(
      checkResult: UpdateAvailable(fakeRelease()),
      cachedFile: File('cached.apk'),
    );
    final installer = FakeUpdateInstaller(
      outcome: UpdateInstallOutcome.permissionRequired,
    );
    await pumpFlowHost(tester, service: service, installer: installer);

    await tapCheck(tester);
    await tester.tap(find.text('下载并安装'));
    await tester.pumpAndSettle();

    expect(find.text('需要安装权限'), findsOneWidget);
    await tester.tap(find.text('前往设置'));
    await tester.pumpAndSettle();
    expect(installer.permissionSettingsCalls, 1);
  });
}
