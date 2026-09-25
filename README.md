# 琥珀图鉴 (Amber Dex)

完全离线的宝可梦图鉴。安装即用：无账号、无服务器、无互联网依赖，飞行模式下可查询全部 1000+ 宝可梦的资料、种族值、特性、进化树、形态、招式与各游戏版本图鉴说明。

- Flutter + Material 3，手机 / 平板 / 桌面真实响应式布局
- 数据（SQLite + 本地化立绘）全部随应用打包，运行时网络请求数 = 0
- 简体中文优先，支持中 / 英 / 日 / 编号搜索，多条件组合筛选
- 首选平台：Android / Windows / macOS

## 构建步骤

```bash
# 1. 生成离线数据（需要联网，一次性）
export PYTHONUTF8=1
uv run tools/data_builder/build_all.py

# 2. 运行
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows          # 或 -d <android device>

# 3. 测试（含“运行期 0 网络请求”验收测试）
flutter test
```

架构、数据契约与设计系统见 `docs/` 与 `DESIGN.md`。数据与素材来源、许可见 `THIRD_PARTY_NOTICES.md`；宝可梦相关名称与立绘版权归 Nintendo / Creatures Inc. / GAME FREAK inc. 等权利方所有，本项目仅为非商业粉丝工具，应用自身的 UI / 代码为原创。
