import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/app/theme/app_colors.dart';
import 'package:fl_pokedex/shared/widgets/pokemon_list_tile.dart';

import 'test_utils.dart';

PokemonListTile _tile({
  bool isFavorite = false,
  ValueChanged<bool>? onFavoriteToggle,
  VoidCallback? onTap,
}) {
  return PokemonListTile(
    nationalDex: 6,
    nameZh: '喷火龙',
    nameEn: 'Charizard',
    typeIds: const ['fire', 'flying'],
    thumbAsset: null,
    isFavorite: isFavorite,
    onFavoriteToggle: onFavoriteToggle,
    onTap: onTap,
  );
}

void main() {
  testWidgets('行高 64；渲染编号 / 中文名+英文名同行 / 属性徽章 / 占位 thumb',
      (tester) async {
    await tester.pumpWidget(wrapTheme(child: _tile()));

    expect(tester.getSize(find.byType(PokemonListTile)).height, 64);
    expect(find.text('#006'), findsOneWidget);
    expect(find.text('喷火龙'), findsOneWidget);
    expect(find.text('Charizard'), findsOneWidget);
    expect(find.text('火'), findsOneWidget);
    expect(find.text('飞行'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pokemon_list_tile_thumb_placeholder')),
      findsOneWidget,
    );
  });

  testWidgets('未收藏：不显示心形；已收藏：常显并可切换', (tester) async {
    await tester.pumpWidget(
      wrapTheme(child: _tile(onFavoriteToggle: (_) {})),
    );
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsNothing);

    var toggledTo = true;
    await tester.pumpWidget(
      wrapTheme(
        child: _tile(isFavorite: true, onFavoriteToggle: (v) => toggledTo = v),
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
    expect(icon.color, AppColors.favoriteLight);
    await tester.tap(find.byIcon(Icons.favorite));
    expect(toggledTo, isFalse);
  });

  testWidgets('点击整行回调 onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrapTheme(
        child: SizedBox(
          width: 400,
          child: _tile(onTap: () => tapped = true),
        ),
      ),
    );

    await tester.tap(find.text('喷火龙'));
    expect(tapped, isTrue);
  });

  testWidgets('dark 主题渲染无异常（关键组件暗色跑一遍）', (tester) async {
    await tester.pumpWidget(
      wrapTheme(brightness: Brightness.dark, child: _tile()),
    );
    expect(tester.takeException(), isNull);
  });
}
