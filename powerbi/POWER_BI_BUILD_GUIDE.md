# Maven Fuzzy Factory Power BI 搭建指南

## 1. Dashboard 范围

最终 Dashboard 固定为 3 页，不增加第 4 页：

1. Business Overview
2. Conversion Funnel
3. Billing A/B Test

业务主线固定为：整体业务长期总体改善 → 购买漏斗识别结构性流失 → 评估新版 Billing 页面 → 根据转化、收入和退款 Guardrail 提出推广建议。

## 2. 导入数据

从 `output/tables` 导入以下 4 个 CSV：

| CSV | 用途 | 行数 |
|---|---|---:|
| `overall_metrics.csv` | Page 1 整体 KPI | 1 |
| `monthly_metrics.csv` | Page 1 月度趋势 | 37 |
| `funnel_metrics.csv` | Page 2 购买漏斗 | 7 |
| `ab_test_summary.csv` | Page 3 A/B Test 和 Refund Guardrail | 2 |

这些表都是独立汇总结果表，不需要创建表关系。不要导入原始百万行 CSV，也不要在 Power BI 中重新定义业务口径。

### 字段类型与格式

- 整数：`sessions`、`users`、`orders`、`purchasing_sessions`、`reached_sessions`、`refunded_orders`、`step_number`
- 日期：`monthly_metrics[month]`，格式 `yyyy-MM`
- 百分比：所有名称包含 `rate`、`lift`、`ci_lower`、`ci_upper` 的字段，格式 `0.00%`
- 金额：`revenue`、`revenue_per_session`、`revenue_per_billing_session`、`revenue_per_billing_session_difference`、`aov`，格式 `$#,##0.00`
- 统计量：`z_statistic`、`refund_z_statistic` 格式 `0.0000`
- p-value：`p_value`、`srm_p_value`、`refund_p_value` 保持小数；展示时按下面的要求处理
- 分类文本：`billing_version`、`funnel_stage`、`pageview_url`

视觉统一使用简洁商务风格：白色或浅灰背景、深蓝为主色、青绿色作为 Treatment 强调色、灰色作为 Control；统一字体、标题层级、卡片尺寸和间距。不要使用渐变、3D、饼图、Gauge、装饰图片或大量颜色。

---

## 3. Page 1 - Business Overview

### 3.1 页面目标与标题

本页只回答：网站整体业务表现怎么样？

- 页面名称：`Business Overview`
- 主标题：`E-Commerce Business Overview`
- 副标题：`Overall performance and monthly conversion trend`
- 业务表达：整体业务健康增长，后续通过漏斗寻找结构性优化空间
- 禁止描述为增长缓慢、业务恶化、转化突然下降或需要救火

### 3.2 数据类型检查

在 Power BI 的 **Data view / Column tools** 中逐项确认：

| 表 | 字段 | Data type | 建议格式 |
|---|---|---|---|
| `overall_metrics` | `sessions` | Whole number | `#,##0` |
| `overall_metrics` | `orders` | Whole number | `#,##0` |
| `overall_metrics` | `purchase_conversion_rate` | Decimal number | Percentage，2 decimals |
| `overall_metrics` | `revenue` | Decimal number | Currency |
| `overall_metrics` | `revenue_per_session` | Decimal number | Currency，2 decimals |
| `monthly_metrics` | `month` | Date（推荐） | `yyyy-MM` |
| `monthly_metrics` | `sessions` | Whole number | `#,##0` |
| `monthly_metrics` | `orders` | Whole number | `#,##0` |
| `monthly_metrics` | `purchase_conversion_rate` | Decimal number | Percentage，2 decimals |
| `monthly_metrics` | `revenue` | Decimal number | Currency |
| `monthly_metrics` | `revenue_per_session` | Decimal number | Currency，2 decimals |

`monthly_metrics[month]` 在 CSV 中保存为每月第一天，例如 `2012-04-01`，适合直接设置为 Date 后作为 X-axis。格式设为 `yyyy-MM`，使用字段本身而不是自动 Date hierarchy，并按 `month` Ascending 排序。

如果 `month` 当前为 Text，不修改原始值，可在 Power Query 中仅将 Data type 改为 Date。若必须保留 Text，则创建排序列：

```DAX
Month Sort =
DATE(
    VALUE(LEFT(monthly_metrics[month], 4)),
    VALUE(MID(monthly_metrics[month], 6, 2)),
    1
)
```

随后选中 `month` → **Column tools** → **Sort by column** → `Month Sort`。这样 2012-04、2012-05 … 2015-02 会按真实月份顺序显示，原始月份值不变。

### 3.3 16:9 页面布局

在 **Format page → Canvas settings → Type** 选择 `16:9`。以下位置以 1280 × 720 画布为参考：

| 区域 | 建议位置与尺寸 |
|---|---|
| 主标题 | X 40，Y 22，W 1200，H 32 |
| 副标题 | X 40，Y 55，W 1200，H 22 |
| 5 个 KPI Cards | Y 92，H 86；X 分别为 40、282、524、766、1008；等宽约 224 |
| Monthly Sessions & Orders | X 40，Y 202，W 730，H 358 |
| Monthly Purchase Conversion Rate | X 790，Y 202，W 450，H 166 |
| Monthly Revenue per Session | X 790，Y 386，W 450，H 174 |
| 业务结论与脚注 | X 40，Y 585，W 1200，H 74 |

图表边缘对齐，Visual 之间保留约 18–24 px。页面背景建议浅灰 `#F5F7FA`，Visual 背景白色。不使用复杂背景、3D、饼图、Gauge 或装饰图表。

### 3.4 顶部 5 个 KPI Cards

全部使用 `overall_metrics`，字段汇总方式使用 `Max`。从左到右固定为：

| 顺序 | Card 标题 | 字段 | Visual 显示设置 | 校验值 |
|---:|---|---|---|---:|
| 1 | `Sessions` | `sessions` | Display units None；0 decimals；Thousands separator On | 472,871 |
| 2 | `Orders` | `orders` | Display units None；0 decimals；Thousands separator On | 32,313 |
| 3 | `Purchase CR` | `purchase_conversion_rate` | Percentage；2 decimals | 6.83% |
| 4 | `Revenue` | `revenue` | Currency；Display units Millions；2 decimals | $1.94M |
| 5 | `Revenue / Session` | `revenue_per_session` | Currency；Display units None；2 decimals | $4.10 |

建议 Callout value 26–30 pt，Category label 11–12 pt；白色背景、轻微边框或阴影、统一圆角。不要展示 AOV，不增加第 6 个 Card。所有值来自字段，不硬编码。

### 3.5 图表 1：Monthly Sessions & Orders

- 表：`monthly_metrics`
- Visual：`Line and clustered column chart`
- X-axis：`month`（不使用 Date hierarchy）
- Column y-axis：`sessions`
- Line y-axis：`orders`
- 标题：`Monthly Sessions & Orders`
- 排序：`month` → Ascending
- Sessions：Column，主 Y-axis，Whole number
- Orders：Line，打开 Secondary y-axis，Whole number
- 建议颜色：Sessions 深蓝 `#1F4E78`；Orders 青绿 `#2A9D8F`
- X-axis type：Continuous（当 `month` 为 Date）
- 不使用同比、环比、移动平均或预测

Visual-level filter：对 `month` 使用 Basic filtering，取消选择 `2012-03-01` 和 `2015-03-01`。若界面显示月份标签，则排除 `2012-03` 和 `2015-03`。

### 3.6 图表 2：Monthly Purchase Conversion Rate

- 表：`monthly_metrics`
- Visual：`Line chart`
- X-axis：`month`（不使用 Date hierarchy）
- Y-axis：`purchase_conversion_rate`
- 标题：`Monthly Purchase Conversion Rate`
- 排序：`month` → Ascending
- Y-axis：Percentage，2 decimals
- X-axis type：Continuous（当 `month` 为 Date）
- 使用单一深蓝折线，可保留小型 Marker，不添加异常点标记
- 不使用同比、环比、移动平均或预测

Visual-level filter：排除 `2012-03-01` 和 `2015-03-01`，与图表 1 一致。

### 3.7 图表 3：Monthly Revenue per Session

- 表：`monthly_metrics`
- Visual：`Line chart`
- X-axis：`month`（不使用 Date hierarchy）
- Y-axis：`revenue_per_session`
- 标题：`Monthly Revenue per Session`
- 排序：`month` → Ascending
- Y-axis：Currency，2 decimals
- X-axis type：Continuous（当 `month` 为 Date）
- 使用单一深蓝或青绿折线，不添加异常点标记
- 不使用同比、环比、移动平均或预测

Visual-level filter：排除 `2012-03-01` 和 `2015-03-01`，与另外两张月度图一致。

### 3.8 业务结论与说明

添加简短 Text box：

> Traffic volume, purchase conversion, and revenue per session improved over time, indicating healthy overall growth with further room for funnel optimization.

下方增加较小字号说明：

> *Monthly trends exclude partial months Mar-2012 and Mar-2015.*

正文建议 12–13 pt，脚注 9–10 pt、灰色。不要增加其他长段落，不把正常月度波动描述为异常事故。

### 3.9 实际搭建顺序（Page 1）

1. 将页面重命名为 `Business Overview`，并把 Canvas 设置为 16:9。
2. 添加主标题 `E-Commerce Business Overview` 和副标题 `Overall performance and monthly conversion trend`。
3. 在 Data view 中检查 `overall_metrics` 与 `monthly_metrics` 的数据类型和格式，确认 `month` 可按真实日期排序。
4. 添加并等距排列 5 个 KPI Cards，按 Sessions、Orders、Purchase CR、Revenue、Revenue / Session 配置。
5. 创建 `Monthly Sessions & Orders` 组合图，将 Orders 放在 Secondary y-axis。
6. 创建 `Monthly Purchase Conversion Rate` 折线图，设置 Percentage、2 decimals。
7. 创建 `Monthly Revenue per Session` 折线图，设置 Currency、2 decimals。
8. 在三张月度图的 Visual-level filter 中排除 Mar-2012 和 Mar-2015，并按 `month` 升序排列。
9. 添加业务结论和 partial-month 脚注，统一卡片尺寸、字体、颜色、边距与对齐。
10. 检查 KPI 是否为 472,871、32,313、6.83%、$1.94M、$4.10，并确认没有 AOV 或额外分析。

Page 1 不增加 AOV、渠道、设备、用户分层、异常诊断或任何 Page 2 / Page 3 内容。

---
## 4. Page 2：Conversion Funnel

### 页面问题

用户主要在哪里流失？

### Cohort 说明

页面副标题必须注明：

> Cohort: 2012-08-05 (inclusive) to 2012-09-05 (exclusive), gsearch / nonbrand

不要将此漏斗描述为三年全站漏斗。

### 页面布局

- 左侧或中央，占主要空间：Conversion Funnel
- 右侧：Drop-off Rate by Step
- 底部：业务结论文本

### Conversion Funnel

- CSV：`funnel_metrics.csv`
- Visual：Funnel
- Group：`funnel_stage`
- Values：`reached_sessions`
- 排序：使用 `step_number` 将 `funnel_stage` 按 1 至 7 排序
- 标题：`Purchase Conversion Funnel`
- 打开 Data labels，显示 Reached Sessions
- 不加入其他阶段或全站筛选器

### Drop-off Rate by Step

- CSV：`funnel_metrics.csv`
- Visual：Horizontal bar chart
- Y Axis：`funnel_stage`
- X Axis：`drop_off_rate`
- Visual filter：排除 `step_number = 1`，因为 Landing 没有上一阶段
- 排序：`step_number` 升序，不按数值大小重新排序
- 数值格式：`0.00%`
- 标题：`Drop-off Rate by Step`
- 使用统一中性色并打开数据标签。不要通过颜色暗示 Billing 是最大流失点
- 每一行的 Drop-off Rate 表示“上一阶段 → 当前阶段”的流失率

校验重点：

- Product Detail → Cart：56.41%
- Billing → Purchase：56.23%

### 必须显示的业务结论

> 漏斗显示 Product Detail → Cart 和 Billing → Purchase 是两个最明显的结构性流失环节。Billing 位于购买路径末端，进入该阶段的用户购买意图较强，因此进一步评估 Billing 页面优化是否能够减少末端流失。

不要写“Billing 是最大的漏斗瓶颈”。

---

## 5. Page 3：Billing A/B Test

### 页面问题

新版 Billing 页面是否真正提升购买转化，并带来商业价值？

Control 为 `/billing`，Treatment 为 `/billing-2`；实验单位为 `website_session_id`。

### 页面布局

- 顶部：4 个等宽主要 KPI Cards
- 中间左侧：Billing-to-Purchase Conversion Rate
- 中间右侧：Revenue per Billing Session，并显示 Difference
- 底部左侧：Statistical Evidence 信息区
- 底部右侧：Refund Guardrail 信息区
- 页面最下方：最终业务结论

Page 3 是视觉重点，但仍保持留白，不堆叠无关图表。

### 顶部 4 个 KPI Cards

CSV 均为 `ab_test_summary.csv`。

| 图表标题 | 字段与筛选 | 格式 |
|---|---|---|
| Control Purchase CR | `purchase_conversion_rate`；Visual filter：`billing_version = control` | `0.00%` |
| Treatment Purchase CR | `purchase_conversion_rate`；Visual filter：`billing_version = treatment` | `0.00%` |
| Absolute Lift | `absolute_lift`，聚合 `Max` | `+0.00 pp;-0.00 pp`，见下方显示 Measure |
| Relative Lift | `relative_lift`，聚合 `Max` | `+0.00%;-0.00%` |

Absolute Lift 原始字段为比例数值。为正确显示百分点，可建立仅用于展示的 Measure：

```DAX
Absolute Lift Display = FORMAT(MAX(ab_test_summary[absolute_lift]) * 100, "+0.00;-0.00") & " pp"
```

### Billing-to-Purchase Conversion Rate

- CSV：`ab_test_summary.csv`
- Visual：Clustered column chart
- X Axis：`billing_version`
- Y Axis：`purchase_conversion_rate`
- 格式：`0.00%`
- 标题：`Billing-to-Purchase Conversion Rate`
- Control 使用灰色，Treatment 使用统一强调色
- 不使用饼图

### Revenue per Billing Session

- CSV：`ab_test_summary.csv`
- Visual：Clustered column chart
- X Axis：`billing_version`
- Y Axis：`revenue_per_billing_session`
- 格式：`$0.00`
- 标题：`Revenue per Billing Session`
- 在图表旁使用一个小 Card 显示 `revenue_per_billing_session_difference`，聚合 `Max`，格式 `+$0.00;-$0.00`

### Statistical Evidence

使用 `ab_test_summary.csv`，用紧凑的 Cards 或 Multi-row card 展示：

| 显示项 | 字段与筛选 | 格式 |
|---|---|---|
| Control Sessions | `sessions`；筛选 `billing_version = control` | 整数 |
| Treatment Sessions | `sessions`；筛选 `billing_version = treatment` | 整数 |
| Z statistic | `z_statistic`，聚合 `Max` | `0.0000` |
| p-value | `p_value`，聚合 `Max` | 小于 0.001 时显示 `< 0.001` |
| 95% CI | `ci_lower` 和 `ci_upper`，聚合 `Max` | 百分点文本 |
| SRM p-value | `srm_p_value`，聚合 `Max` | `0.000000` |

为避免将极小 p-value 显示为 0，可创建展示 Measure：

```DAX
P-value Display =
IF(
    MAX(ab_test_summary[p_value]) < 0.001,
    "< 0.001",
    FORMAT(MAX(ab_test_summary[p_value]), "0.000")
)
```

```DAX
95% CI Display =
FORMAT(MAX(ab_test_summary[ci_lower]) * 100, "+0.00;-0.00")
& " pp to " &
FORMAT(MAX(ab_test_summary[ci_upper]) * 100, "+0.00;-0.00")
& " pp"
```

不要加入 Power、MDE 或复杂统计图。

### Refund Guardrail

使用 `ab_test_summary.csv`，以紧凑信息区展示：

| 显示项 | 字段与筛选 | 格式 |
|---|---|---|
| Control Orders | `orders`；筛选 `billing_version = control` | 整数 |
| Treatment Orders | `orders`；筛选 `billing_version = treatment` | 整数 |
| Control Refund Rate | `refund_rate`；筛选 `billing_version = control` | `0.00%` |
| Treatment Refund Rate | `refund_rate`；筛选 `billing_version = treatment` | `0.00%` |
| Difference | `refund_rate_difference`，聚合 `Max` | 百分点，使用下方 Measure |
| Refund p-value | `refund_p_value`，聚合 `Max` | `0.000000` |

```DAX
Refund Rate Difference Display =
FORMAT(MAX(ab_test_summary[refund_rate_difference]) * 100, "+0.00;-0.00") & " pp"
```

必须显示准确解释：

> Treatment 的退款率点估计较高，但差异未达到统计显著水平，因此当前数据没有提供明确证据表明 Treatment 导致退款率显著恶化。

不要写“退款率没有变化”，也不要写“证明 Treatment 不会导致更多退款”。

### 必须显示的最终业务结论

> 新版 Billing 页面将 Billing-to-Purchase Conversion Rate 从 45.66% 提升至 62.69%，绝对提升 17.03 个百分点，相对提升约 37.29%。该差异统计显著，且 Revenue per Billing Session 从 $22.83 提升至 $31.34。退款率点估计有所上升，但当前差异未达到统计显著水平。综合转化和收入表现，建议优先采用新版 Billing 页面，并在上线后持续监控转化、收入和退款表现。

---

## 6. 全局禁止项

不要增加以下内容：

- 第 4 页或任何额外页面
- AARRR、North Star Metric、LTV、PCR、用户聚类
- 第二个 A/B Test
- Device、Traffic Source、New / Repeat 分层页面
- Refund 专题页面
- 数据清洗、SQL 或 Python 技术展示页面
- Power、MDE、预测模型或机器学习
- 预测线、移动平均、同比或环比
- 3D 图、饼图、Gauge、复杂背景图片或无意义装饰

不要修改既定业务故事，不要把不完整月份描述成业务下滑，也不要把 Billing 描述为最大的漏斗瓶颈。
