import 'package:flutter/material.dart';

/// 招式详情占位页（后续由 F 单元 lib/features/moves/ 实装替换，
/// 替换时仅需修改 router.dart 的 builder 指向）。
class MoveDetailPlaceholderPage extends StatelessWidget {
  const MoveDetailPlaceholderPage({super.key, required this.moveId});

  final int moveId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('招式详情')),
      body: Center(
        child: Text('Move #$moveId · 建设中'),
      ),
    );
  }
}
