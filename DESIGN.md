# DESIGN.md — Fl-PokeDex Design System

本文件是全项目唯一视觉事实来源。所有 UI 代码必须引用这里定义的 Token（`lib/app/theme/tokens.dart`、`app_colors.dart`），禁止在组件里硬编码颜色 / 圆角 / 时长。

## 1. 品牌色（OKLCH 推导，落地为 sRGB）

品牌色支持 6 个主题种子色（seed，`AppSeedColor`）：amber=琥珀（默认）、rose=粉、forest=墨绿、blue=蓝、teal=青、violet=紫。琥珀即下方两表；其余 seed 见 §1.1。

Light（琥珀 amber，默认 seed）：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| bg | 1.00 0.00 0 | `#FFFFFF` | 页面底色（纯白） |
| surfaceContainerLow | 0.975 0.006 85 | `#F9F6F2` | 输入框、次级面板 |
| surfaceContainer | 0.955 0.008 85 | `#F3F0EA` | 卡片、栏容器 |
| outlineVariant | 0.90 0.010 85 | `#E1DED7` | 分隔线、描边弱 |
| outline | 0.72 0.015 80 | `#AAA49A` | 描边强 |
| onSurface | 0.24 0.012 80 | `#221F19` | 正文墨色 |
| onSurfaceVariant | 0.47 0.015 80 | `#5F5A52` | 次级文字 |
| primary | 0.58 0.125 78 | `#A26F00` | 蜂蜜琥珀：选中、主按钮、焦点（白字） |
| primaryContainer | 0.90 0.075 85 | `#F5DBA5` | 琥珀弱底 |
| onPrimaryContainer | 0.33 0.08 75 | `#4D2E00` | 琥珀弱底上的字 |
| secondary | 0.46 0.06 210 | `#29616B` | 墨青：链接、次级强调 |
| secondaryContainer | 0.91 0.03 210 | `#CCE7EC` | 墨青弱底 |
| onSecondaryContainer | 0.30 0.05 215 | `#05343D` | 墨青弱底上的字 |
| favorite | 0.58 0.19 15 | `#D23855` | 收藏（心形） |
| error | 0.55 0.19 25 | `#C92F33` | 错误 |

Dark（琥珀 amber）：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| bg | 0.12 0.00 0 | `#060606` | 页面底色（碳黑，OLED 友好） |
| surfaceContainerLow | 0.17 0.006 80 | `#110F0D` | 次级面板 |
| surfaceContainer | 0.21 0.008 80 | `#1A1814` | 卡片 |
| outlineVariant | 0.30 0.010 80 | `#302D28` | 分隔线弱 |
| outline | 0.45 0.012 80 | `#59554E` | 描边强 |
| onSurface | 0.93 0.008 85 | `#EAE7E2` | 正文 |
| onSurfaceVariant | 0.70 0.010 85 | `#A19E98` | 次级文字 |
| primary | 0.80 0.135 85 | `#E5B64A` | 蜜金（深色字 #271700） |
| primaryContainer | 0.38 0.09 78 | `#5C3B00` | 琥珀弱底 |
| onPrimaryContainer | 0.90 0.07 85 | `#F3DBA9` | |
| secondary | 0.75 0.07 210 | `#77BAC6` | |
| secondaryContainer | 0.32 0.05 210 | `#0A3A41` | |
| onSecondaryContainer | 0.90 0.03 210 | `#C8E4E9` | |
| favorite | 0.72 0.16 15 | `#F87584` | 收藏 |
| error | 0.70 0.15 25 | `#ED756E` | |

填充上写字的规则（**对比度优先**）：填充前景取**白 / 深两候选中对比度更高且 ≥4.5 者**；两候选均不达标时调整填充色本身，禁止凑合。原亮度分带保留为默认启发——饱和中亮度（L 0.42–0.78 且 C≥0.08）倾向白字，浅色填充（L>0.85）或近中性填充倾向深字；启发与实测对比度冲突时以对比度为准（如 rose 品牌粉 `#FB7299` 用深字 `#4A0E24`，5.8:1）。

### 1.1 主题种子色（seed）落地表

**规则**：primary 族与 secondary 族随 seed 切换；**中性色（bg / surface 族 / outline 族 / onSurface 族）随 seed hue 派生**——各 token 的 OKLCH **L 与 C 逐字沿用琥珀系**（§1 两表对应行），仅把 hue 替换为该 seed primary 的 OKLCH hue（light / dark 各用各侧 primary 的 hue），经标准 OKLCH→sRGB 公式 round-trip 到 8bit hex。bg 两档为纯灰（C=0），hue 旋转不变形，全 seed 同值。favorite、error 与 §2 属性色**不参与 hue 旋转**，全 seed 固定（设计分工，非遗漏）。amber 中性即 §1 两表本体（默认，向后兼容），不另列。

各 seed 派生 hue 与 surfaceContainer 代表值（其余中性 token 按上述公式派生，落地值以 `lib/app/theme/app_colors.dart` 为准）：

| seed | hue light / dark | surfaceContainer light | dark |
|---|---|---|---|
| amber | 80–85（基准） | `#F3F0EA` | `#1A1814` |
| rose | 4.5 / 4.5 | `#F6EEF0` | `#1C1718` |
| forest | 161 / 160 | `#ECF2EE` | `#151917` |
| blue | 264 / 261 | `#EDF0F6` | `#16181C` |
| teal | 204 / 183 | `#EAF2F3` | `#141A19` |
| violet | 295 / 297 | `#F1EFF6` | `#19171C` |

各表 onPrimary / onSecondary 不单列：light 模式一律 `#FFFFFF`（**例外：rose 品牌粉上为深字 `#4A0E24`**，见 §1 写字规则）；dark 模式 onPrimary 为同 seed 深色调（见 primary 行注），onSecondary 一律 `#060606`（与琥珀表同规则）。下列 OKLCH 为落地 sRGB 的精确反推（与正向推导等价，按 2 位小数舍入）。全部组合过守门测试（`test/app/theme/app_colors_seeds_test.dart`）。例外：① amber light primary 白字 4.37:1 为品牌锁定值（满足大文本 3:1 档）；② rose light primary `#FB7299` 对白底 2.64:1，特批 ≥2.6——B 站品牌粉仅用于指示器、选中描边、按钮填充等非正文文本场景，其上文字已用深字 `#4A0E24`（5.8:1）达标。secondary 一律取与 primary 协调但色相可区分的低饱和伴随色。

rose 粉：

Light：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| primary | 0.73 0.17 4 | `#FB7299` | B 站品牌粉：选中、主按钮、焦点（深字 `#4A0E24`，5.8:1） |
| primaryContainer | 0.92 0.04 2 | `#FFD9E2` | 粉弱底 |
| onPrimaryContainer | 0.24 0.10 359 | `#3E001D` | 粉弱底上的字 |
| secondary | 0.49 0.06 275 | `#565E85` | 黛蓝：链接、次级强调 |
| secondaryContainer | 0.92 0.03 284 | `#E0E1F9` | 黛蓝弱底 |
| onSecondaryContainer | 0.24 0.06 272 | `#141B3C` | 黛蓝弱底上的字 |

Dark：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| primary | 0.73 0.17 4 | `#FB7299` | B 站品牌粉（深浅同值，深底 7.7:1；深色字 `#4A0E24`） |
| primaryContainer | 0.32 0.11 359 | `#5C1132` | 粉弱底 |
| onPrimaryContainer | 0.92 0.04 2 | `#FFD9E2` | |
| secondary | 0.81 0.05 271 | `#B4C0E5` | 黛蓝 |
| secondaryContainer | 0.33 0.06 274 | `#2C3355` | |
| onSecondaryContainer | 0.92 0.03 284 | `#E0E1F9` | |

forest 墨绿：

Light：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| primary | 0.48 0.08 161 | `#2E6B4F` | 墨绿：选中、主按钮、焦点（白字） |
| primaryContainer | 0.91 0.07 160 | `#B8F0D0` | 绿弱底 |
| onPrimaryContainer | 0.30 0.07 157 | `#00391F` | 绿弱底上的字 |
| secondary | 0.46 0.06 73 | `#6D5433` | 墨赭：链接、次级强调 |
| secondaryContainer | 0.92 0.04 79 | `#F3E2C7` | 墨赭弱底 |
| onSecondaryContainer | 0.22 0.04 85 | `#241A04` | 墨赭弱底上的字 |

Dark：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| primary | 0.82 0.09 160 | `#8FD6B0` | 薄荷绿（深色字 #00391F） |
| primaryContainer | 0.38 0.07 159 | `#1E4E36` | 绿弱底 |
| onPrimaryContainer | 0.91 0.07 160 | `#B8F0D0` | |
| secondary | 0.83 0.06 76 | `#DCC29D` | 墨赭 |
| secondaryContainer | 0.34 0.04 79 | `#43341B` | |
| onSecondaryContainer | 0.92 0.04 79 | `#F3E2C7` | |

blue 蓝：

Light：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| primary | 0.53 0.16 264 | `#3B64C4` | 群青：选中、主按钮、焦点（白字） |
| primaryContainer | 0.92 0.04 275 | `#DBE2FF` | 蓝弱底 |
| onPrimaryContainer | 0.23 0.08 257 | `#001A41` | 蓝弱底上的字 |
| secondary | 0.47 0.07 43 | `#7A4E3C` | 陶土：链接、次级强调 |
| secondaryContainer | 0.92 0.03 50 | `#F4DFD4` | 陶土弱底 |
| onSecondaryContainer | 0.23 0.05 44 | `#2E150A` | 陶土弱底上的字 |

Dark：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| primary | 0.83 0.09 261 | `#A8C8FF` | 浅群青（深色字 #002D6B） |
| primaryContainer | 0.39 0.11 261 | `#22447F` | 蓝弱底 |
| onPrimaryContainer | 0.92 0.04 275 | `#DBE2FF` | |
| secondary | 0.83 0.07 41 | `#EFB9A5` | 陶土 |
| secondaryContainer | 0.39 0.05 47 | `#5B3B2B` | |
| onSecondaryContainer | 0.92 0.03 50 | `#F4DFD4` | |

teal 青：

Light：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| primary | 0.53 0.09 204 | `#007B84` | 孔雀青：选中、主按钮、焦点（白字） |
| primaryContainer | 0.90 0.06 201 | `#B0ECF0` | 青弱底 |
| onPrimaryContainer | 0.22 0.04 204 | `#002023` | 青弱底上的字 |
| secondary | 0.46 0.06 339 | `#6D4A62` | 梅紫：链接、次级强调 |
| secondaryContainer | 0.92 0.03 338 | `#F4DCEC` | 梅紫弱底 |
| onSecondaryContainer | 0.23 0.05 337 | `#2A1224` | 梅紫弱底上的字 |

Dark：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| primary | 0.80 0.12 183 | `#4FD8C6` | 湖水青（深色字 #003733） |
| primaryContainer | 0.39 0.07 193 | `#00504F` | 青弱底 |
| onPrimaryContainer | 0.90 0.06 201 | `#B0ECF0` | |
| secondary | 0.84 0.04 336 | `#DCBFD4` | 梅紫 |
| secondaryContainer | 0.38 0.05 340 | `#54364A` | |
| onSecondaryContainer | 0.92 0.03 338 | `#F4DCEC` | |

violet 紫：

Light：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| primary | 0.50 0.19 295 | `#6F42C1` | 鸢尾紫：选中、主按钮、焦点（白字） |
| primaryContainer | 0.92 0.05 301 | `#E9DEFF` | 紫弱底 |
| onPrimaryContainer | 0.24 0.13 291 | `#250058` | 紫弱底上的字 |
| secondary | 0.47 0.03 133 | `#55604E` | 苔绿：链接、次级强调 |
| secondaryContainer | 0.91 0.03 134 | `#DCE7D6` | 苔绿弱底 |
| onSecondaryContainer | 0.21 0.02 136 | `#131A10` | 苔绿弱底上的字 |

Dark：

| Token | OKLCH | Hex | 用途 |
|---|---|---|---|
| primary | 0.83 0.09 297 | `#CFBCFF` | 浅鸢尾紫（深色字 #2A0054） |
| primaryContainer | 0.36 0.17 294 | `#471C8B` | 紫弱底 |
| onPrimaryContainer | 0.92 0.05 301 | `#E9DEFF` | |
| secondary | 0.84 0.03 132 | `#C2CFB9` | 苔绿 |
| secondaryContainer | 0.38 0.03 135 | `#3B4536` | |
| onSecondaryContainer | 0.91 0.03 134 | `#DCE7D6` | |

## 2. 属性色（仅徽章 / 小标签 / Accent，禁止整页铺色）

solid 徽章底色 + 自动前景（白 / 深由亮度决定，见 tokens.dart 中 `typeFgOn`）：

| 属性 | Hex | 前景 | 属性 | Hex | 前景 |
|---|---|---|---|---|---|
| 一般 normal | `#7B705E` | white | 电 electric | `#E3C23B` | dark |
| 火 fire | `#D05320` | white | 草 grass | `#4E9A52` | white |
| 水 water | `#3082B5` | white | 冰 ice | `#87CBD7` | dark |
| 格斗 fighting | `#B8492E` | white | 毒 poison | `#9553A4` | white |
| 地面 ground | `#B99056` | white | 飞行 flying | `#7E9FD7` | dark |
| 超能力 psychic | `#C96598` | white | 虫 bug | `#869A3E` | white |
| 岩石 rock | `#A0783E` | white | 幽灵 ghost | `#725B9A` | white |
| 龙 dragon | `#4F679D` | white | 恶 dark | `#3A4258` | white |
| 钢 steel | `#6197CD` | white | 妖精 fairy | `#E4A0BF` | dark |

## 3. 几何与密度

- **Spacing**：xs=4, s=8, m=12, l=16, xl=24, xxl=32；页面水平留白 compact=16 / expanded=24。
- **Radius**：card=14, input/button=10, sheet=20（顶部）, chip/badge=full-pill；禁止 >16 的卡片圆角。
- **Elevation**：尽量用 surfaceContainer 色阶分层代替阴影；阴影只用于浮层（≤8px blur，禁止 1px 描边 + 大阴影同用）。
- **Breakpoint**：width < 600 → compact；600–840 → medium；≥840 → expanded；≥1080 → 详情页启用双栏（master-detail）。
- 栅格列数：compact 3 列（卡片），medium 4 列，expanded 5–6 列（随窗口宽度自适应 `maxCrossAxisExtent` ≈ 180–220）。

## 4. 字体与排版

- 字族 MiSans（内嵌 `assets/fonts/` 三档：MiSans-Regular=400 / MiSans-Medium=500 / MiSans-Demibold=600）。**不用展示字体做 UI 标签。**
- 槽位映射依据 MiSans 官方 CSS 惯例（Thin=100 / ExtraLight=200 / Light=300 / Normal=350 / Regular=400 / Medium=500 / **Demibold=600** / Bold=700 / Heavy=900），而非字体 OS/2 表数值——MiSans 全族 `OS/2.usWeightClass` 为非标准刻度（实测 Regular=330 / Medium=380 / Demibold=450 / Semibold=520 / Bold=630 / Heavy=700）。同目录 Semibold 为 Demibold 同槽位的不同世代 cut，不嵌入。
- 固定字号阶梯（比率 ≈1.18，不随窗口缩放）：
  display 32/38 w600 · title 22/28 w600 · heading 17/24 w600 · body 15/22 w400 ·
  label 13/18 w500 · caption 12/16 w400 · number-tabular 用于编号与数值（`FontFeature.tabularFigures`）。
- 正文章制：详情说明文字一行 max ≈ 65–75 字符（expanded 下限制文本区宽 ≤ 640px）。

## 5. 动效

- 时长：fast=150ms（chip/选中）、normal=220ms（面板/页面）、slow=300ms（大图淡入）。曲线统一 `Curves.easeOutCubic`。禁止弹跳/回弹。
- 动效只表达状态：选中态切换、面板展开、页面进出、图片淡入。**不做装饰性循环动画**；列表不做逐项入场编排。
- 页面过渡：compact 用平台默认（Android 向上推入），expanded 内 master-detail 切换用 fade-through（240ms）。
- 详情页立绘进入：150ms 淡入 + 8px 上移，一次性，不循环。

## 6. 组件状态词汇

每个可交互组件必须有：default / hover（桌面）/ focus（键盘）/ pressed / selected / disabled。加载用骨架（浅色容器脉冲 ≤200ms 循环可关），不用居中大转圈。空状态给出指引文案 + 操作入口（如“没有匹配的宝可梦，试试清除筛选”）。

## 7. 明令禁止（AI slop 防线）

- 侧边色条卡片（border-left 彩条）、渐变文字、玻璃拟态、斜纹背景、大圆角卡片(>16)。
- “大数字+渐变”英雄指标模板、同构卡片矩阵里再嵌卡片。
- 属性色铺满页面 / 整卡底色；属性色只允许出现在徽章、选中描边、细线 accent（≤2px）。
- 精灵球装饰泛滥、像素字体、无意义动画。
- 招式/种族值表格里 999/9999 式随手写的阴影与圆角。
