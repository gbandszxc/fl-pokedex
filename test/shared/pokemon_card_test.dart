import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/app/theme/app_colors.dart';
import 'package:fl_pokedex/shared/widgets/pokemon_card.dart';

import 'test_utils.dart';

const _cardKey = ValueKey('card-under-test');

PokemonCard _card({
  bool isFavorite = false,
  ValueChanged<bool>? onFavoriteToggle,
  List<String> typeIds = const ['grass', 'poison'],
  VoidCallback? onTap,
}) {
  return PokemonCard(
    key: _cardKey,
    nationalDex: 1,
    nameZh: '妙蛙种子',
    nameEn: 'Bulbasaur',
    typeIds: typeIds,
    artworkAsset: null, // 测试环境无图片资产 → 占位圆形色块
    isFavorite: isFavorite,
    onFavoriteToggle: onFavoriteToggle,
    onTap: onTap,
  );
}

void main() {
  testWidgets('渲染编号 / 中文名 / 英文名 / 属性徽章；无立绘时显示占位',
      (tester) async {
    await tester.pumpWidget(
      wrapTheme(child: SizedBox(width: 180, child: _card())),
    );

    expect(find.text('#001'), findsOneWidget);
    expect(find.text('妙蛙种子'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('草'), findsOneWidget);
    expect(find.text('毒'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pokemon_card_art_placeholder')),
      findsOneWidget,
    );
  });

  testWidgets('徽章最多渲染 2 个', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        child: SizedBox(
          width: 180,
          child: _card(typeIds: const ['grass', 'poison', 'fire']),
        ),
      ),
    );

    expect(find.text('草'), findsOneWidget);
    expect(find.text('毒'), findsOneWidget);
    expect(find.text('火'), findsNothing);
  });

  testWidgets('未收藏且未交互：不显示心形（V1 默认布局不塌）', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        child: SizedBox(
          width: 180,
          child: _card(onFavoriteToggle: (_) {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('已收藏：实心心形常显，favorite 色，点击回调取消', (tester) async {
    var toggledTo = true;
    await tester.pumpWidget(
      wrapTheme(
        child: SizedBox(
          width: 180,
          child: _card(
            isFavorite: true,
            onFavoriteToggle: (v) => toggledTo = v,
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
    expect(icon.color, AppColors.favoriteLight);

    await tester.tap(find.byIcon(Icons.favorite));
    expect(toggledTo, isFalse);
  });

  testWidgets('整卡点击回调 onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrapTheme(child: SizedBox(width: 180, child: _card(onTap: () {
        tapped = true;
      }))),
    );

    await tester.tap(find.byKey(_cardKey));
    expect(tapped, isTrue);
  });

  testWidgets('dark 主题：卡片底色为 dark surfaceContainer', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        brightness: Brightness.dark,
        child: SizedBox(width: 180, child: _card()),
      ),
    );

    final material = firstDescendantMaterial(tester, PokemonCard);
    expect(material.color, AppColors.dark.surfaceContainer);
  });
}
