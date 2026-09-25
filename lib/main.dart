import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/offline/blocking_http_overrides.dart';

void main() {
  // 离线守卫：任何运行时 HTTP 请求一律抛 OfflineRequestBlocked
  // （PRODUCT.md 硬性契约 / architecture.md §8）。必须先于 runApp 设置。
  HttpOverrides.global = BlockingHttpOverrides();

  runApp(const ProviderScope(child: AmberDexApp()));
}
