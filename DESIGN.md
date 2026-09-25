# DESIGN.md — 琥珀图鉴 Design System

本文件是全项目唯一视觉事实来源。所有 UI 代码必须引用这里定义的 Token（`lib/app/theme/tokens.dart`、`app_colors.dart`），禁止在组件里硬编码颜色 / 圆角 / 时长。

## 1. 品牌色（OKLCH 推导，落地为 sRGB）

Light：

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

Dark：

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

填充上写字的规则：饱和中亮度（L 0.42–0.78 且 C≥0.08）一律**白字**；浅色填充（L>0.85）或近中性填充用**深字**。禁止深字压饱和暖色。

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

- 单一字族：系统默认（Android: Roboto+NotoCJK / Windows: Segoe UI+雅黑回退）。**不打包字体、不用展示字体做 UI 标签。**
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
