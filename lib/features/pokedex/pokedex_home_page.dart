import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// 图鉴首页占位：顶部搜索框为静态预览（后续由 E 单元实装替换）。
class PokedexHomePage extends StatelessWidget {
  const PokedexHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pagePadding = width < 600 ? AppPagePadding.compact : AppPagePadding.expanded;

    return Scaffold(
      appBar: AppBar(title: const Text('琥珀图鉴')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.s),
            // 静态搜索框预览：只读，仅展示样式；E 单元接入 filterProvider 后替换。
            const TextField(
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索名称 / 编号…',
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Expanded(
              child: Center(
                child: Text(
                  '建设中',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
