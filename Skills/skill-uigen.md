# Skill: uigen

## 技能名称

uigen（UI Generator for Health Apps）

---

## 描述

当用户需要为「拉了么」或同类健康记录应用生成 Flutter UI 组件时激活。适用于以下场景：

- 根据产品描述或 Figma 标注生成可编译的 Dart Widget 代码
- 构建首页数据卡片、统计图表、底部导航、操作按钮等界面元素
- 调整全局主题色、动态文案插槽或交互动画
- 将自然语言需求（如"做一个展示布里斯托分型的饼图页"）转化为完整代码

---

## 指令

激活时，模型应：

1. **优先使用 Riverpod 状态管理**，输出 `ConsumerWidget` 而非 `StatefulWidget`，禁止直接使用 `setState`
2. **严格遵循「拉了么」品牌规范**：主色使用暖棕色渐变（`Color(0xFFD4A574)` → `Color(0xFFF5E6D3)`），圆角统一 24dp，阴影使用 `Colors.brown.withOpacity(0.15)`
3. **图表必须使用 fl_chart 库**，根据需求自动选择 `BarChart`（周统计）、`LineChart`（年趋势）、`PieChart`（布里斯托分型）、`ScatterChart`（时段热力图）
4. **实现动态文案插槽**：根据数据状态（今日次数、历史规律、健康评级）自动切换问候语与副标题，禁止硬编码固定文案
5. **包含无障碍支持**：所有交互元素包裹 `Semantics`，颜色对比度 ≥ 4.5:1，适配系统字体缩放
6. **动画使用统一时长**：`AppTheme.animationDuration`（300ms），支持 Hero 转场、飘字动画（+14.9 分）、弹性缩放
7. **输出完整文件**：包含 import 分组、Widget 类、build 方法、私有辅助方法、主题常量引用，以及 3 行以内的使用示例
