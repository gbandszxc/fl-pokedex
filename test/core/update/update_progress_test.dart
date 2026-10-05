import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/core/update/update_progress.dart';

void main() {
  group('formatBytes', () {
    test('KB / MB 两档', () {
      expect(formatBytes(0), '0 KB');
      expect(formatBytes(512 * 1024), '512 KB');
      expect(formatBytes(84 * 1024 * 1024 + 700 * 1024), '84.7 MB');
    });

    test('负值按 0 处理', () {
      expect(formatBytes(-1), '0 KB');
    });
  });

  group('formatSpeed', () {
    test('未知速度为 --，其余带单位', () {
      expect(formatSpeed(0), '-- MB/s');
      expect(formatSpeed(-10), '-- MB/s');
      expect(formatSpeed(4.2 * 1024 * 1024), '4.2 MB/s');
      expect(formatSpeed(2048), '2 KB/s');
    });
  });

  group('progressFraction', () {
    test('按总量归一，未知总量为 null（不确定态），超量截到 1', () {
      expect(
        progressFraction(
          const UpdateProgress(received: 50, total: 100, bytesPerSecond: 0),
        ),
        0.5,
      );
      expect(
        progressFraction(
          const UpdateProgress(received: 50, total: null, bytesPerSecond: 0),
        ),
        isNull,
      );
      expect(
        progressFraction(
          const UpdateProgress(received: 200, total: 100, bytesPerSecond: 0),
        ),
        1.0,
      );
    });
  });

  group('formatProgressLabel', () {
    test('已知总量：已下载 / 总量 · 速度', () {
      expect(
        formatProgressLabel(
          const UpdateProgress(
            received: 12 * 1024 * 1024,
            total: 84 * 1024 * 1024,
            bytesPerSecond: 4.2 * 1024 * 1024,
          ),
        ),
        '12.0 MB / 84.0 MB · 4.2 MB/s',
      );
    });

    test('未知总量：只报已下载', () {
      expect(
        formatProgressLabel(
          const UpdateProgress(received: 1024, total: null, bytesPerSecond: 0),
        ),
        '已下载 1 KB · -- MB/s',
      );
    });
  });

  group('UpdateCancelToken', () {
    test('置位后只读不再复位', () {
      final token = UpdateCancelToken();
      expect(token.isCanceled, isFalse);
      token.cancel();
      expect(token.isCanceled, isTrue);
      token.cancel();
      expect(token.isCanceled, isTrue);
    });
  });
}
