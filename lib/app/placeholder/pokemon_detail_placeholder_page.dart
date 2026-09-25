import 'package:flutter/material.dart';

/// 宝可梦详情占位页（后续由 F 单元 lib/features/pokemon_detail/ 实装替换，
/// 替换时仅需修改 router.dart 的 builder 指向）。
class PokemonDetailPlaceholderPage extends StatelessWidget {
  const PokemonDetailPlaceholderPage({super.key, required this.speciesId});

  final int speciesId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('宝可梦详情')),
      body: Center(
        child: Text('Species #$speciesId · 建设中'),
      ),
    );
  }
}
