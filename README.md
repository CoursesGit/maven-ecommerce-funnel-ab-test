# 电商转化漏斗诊断与 Billing Page A/B 测试分析

**SQL + Python/Pandas + Power BI**

本项目基于 Maven Analytics 的 Maven Fuzzy Factory 教学模拟电商数据库，对网站整体经营表现、购买转化漏斗及历史 Billing Page A/B Test 进行复盘分析。

项目目标不是寻找一次“业务暴跌”，而是沿着完整的数据分析业务链路：

> **监控整体经营表现 → 识别结构性转化损失 → 聚焦高价值结算环节 → 复盘历史 A/B 实验 → 量化页面优化效果 → 形成推广策略 → 持续监控 → 进入下一轮优化。**

## 核心结论

- 网站整体流量、购买转化率和 Revenue per Session 长期总体改善；
- 漏斗中 **Product Detail → Cart（56.41%）** 与 **Billing → Purchase（56.23%）** 是两个主要结构性流失点；
- 新版 Billing 页面将 Billing-to-Purchase Conversion Rate 从 **45.66% 提升至 62.69%**；
- Absolute Lift 为 **+17.03 pp**，Relative Lift 为 **+37.29%**；
- 95% Confidence Interval 为 **+11.71 pp 至 +22.34 pp**，`p < 0.001`；
- Revenue per Billing Session 从 **$22.83 提升至 $31.34**，增加 **$8.51**；
- Refund Rate 从 **6.67% 上升至 9.51%**，但差异未达到统计显著水平（`p = 0.175`）；
- 综合转化与收入表现，建议优先采用新版 Billing 页面，并在上线后持续监控退款护栏指标。

---

## 1. 核心业务问题

本项目主要回答三个问题：

1. 网站整体经营与购买转化表现如何？
2. 用户购买路径中的主要结构性流失发生在哪里？
3. 新版 Billing 页面是否显著提高最终购买转化，并产生商业价值？

---

## 2. 数据

项目使用四张核心数据表：

| 数据表 | 行数 | 主要用途 |
|---|---:|---|
| `website_sessions` | 472,871 | Session、用户及流量属性 |
| `website_pageviews` | 1,188,124 | Session 内页面访问行为 |
| `orders` | 32,313 | 订单及收入 |
| `order_item_refunds` | 1,731 | 退款记录 |

主要观察期：

**2012-03-19 至 2015-03-19**

退款数据包含额外的后续观察窗口。

> 数据来自 Maven Analytics 教学模拟电商数据库，并非真实企业生产数据。

官方数据来源：

[Maven Analytics — Toy Store E-Commerce Database](https://mavenanalytics.io/data-playground/toy-store-e-commerce-database)

字段定义：

`data/maven_fuzzy_factory_data_dictionary.csv`

由于原始 Pageview 等数据规模较大，本仓库不重复托管大型原始 CSV，可通过官方数据页面获取。

---

## 3. 分析工具

- **MySQL / SQL**：数据导入、数据质量检查、核心业务指标、购买漏斗、A/B 实验样本提取
- **Python / Pandas**：A/B 实验数据处理与结果汇总
- **statsmodels / scipy**：Two-Proportion Z-Test、Confidence Interval、SRM、Refund Guardrail
- **Power BI**：整体业务表现、转化漏斗与 A/B 实验结果展示

---

## 4. 分析流程

~~~text
数据理解与质量检查
        ↓
整体业务指标监控
        ↓
完整季度经营趋势
        ↓
购买漏斗诊断
        ↓
识别结构性流失
        ↓
聚焦 Billing 高价值末端环节
        ↓
历史 Billing Page A/B Test 复盘
        ↓
统计显著性与置信区间
        ↓
Revenue Impact
        ↓
Refund Guardrail
        ↓
推广策略与上线监控
        ↓
下一轮漏斗优化
~~~

---

## 5. 数据质量检查

正式分析前，对四张核心表进行了数据量、时间范围、主键、NULL、表关联完整性和数值字段检查。

检查结果：

- 四张表导入行数与原始 CSV 一致；
- 主键重复记录 = **0**；
- 核心字段 NULL = **0**；
- Pageview → Session 孤儿记录 = **0**；
- Order → Session 孤儿记录 = **0**；
- Refund → Order 孤儿记录 = **0**；
- 金额与数量字段未发现基础异常；
- `device_type`、`is_repeat_session` 等主要分类字段取值正常。

因此，数据本身质量较高，没有为了展示“数据清洗”而进行无意义的数据删除、填补或修改，而是保留原始数据进入后续分析。

---

## 6. 整体业务表现

完整观察期结果：

| 指标 | 结果 |
|---|---:|
| Sessions | 472,871 |
| Users | 394,318 |
| Orders | 32,313 |
| Purchase Conversion Rate | 6.83% |
| Revenue | $1,938,509.75 |
| Revenue per Session | $4.10 |
| AOV | $59.99 |

顶部总体指标覆盖完整观察期。

为了保证不同时间段之间的可比性，经营趋势仅使用完整季度：

**2012 Q2 至 2014 Q4**

排除：

- **2012 Q1**：原始数据从 2012-03-19 开始，该季度不完整；
- **2015 Q1**：原始数据仅覆盖至 2015-03-19，该季度不完整。

季度趋势显示：

- Sessions 总体扩大；
- Purchase Conversion Rate 总体提高；
- Revenue per Session 总体提高。

因此，本项目不围绕一次业务异常或持续性恶化展开，而是进一步寻找仍然存在的**结构性转化优化空间**。

---

## 7. 购买转化漏斗

三年观察期内 Landing Page 和部分页面版本存在变化，因此没有直接构建三年全站统一漏斗，而是选择页面路径相对稳定的固定 cohort。

### 分析样本

- 时间：**2012-08-05 至 2012-09-04**
- 流量：**gsearch + nonbrand**
- 分析单位：**Session**

漏斗结果：

| 阶段 | 到达 Sessions | Step CR |
|---|---:|---:|
| Landing | 4,493 | — |
| Products | 2,115 | 47.07% |
| Product Detail | 1,567 | 74.09% |
| Cart | 683 | 43.59% |
| Shipping | 455 | 66.62% |
| Billing | 361 | 79.34% |
| Purchase | 158 | 43.77% |

两个主要结构性流失点：

- **Product Detail → Cart：56.41% Drop-off**
- **Billing → Purchase：56.23% Drop-off**

Billing 并不是唯一或最大的漏斗瓶颈。

进一步分析 Billing 的原因是：

1. Billing 已位于购买路径末端；
2. 进入该阶段的用户已经表现出较强购买意图；
3. 这一阶段的流失更接近最终订单损失，商业价值较高；
4. 数据中存在对应的历史 Billing 页面 A/B 实验，可以进一步验证页面优化效果。

因此，下一阶段并不是直接认定 Billing 页面存在问题，而是把：

> **“新版结算页是否能够降低高购买意图用户的末端转化摩擦？”**

作为需要通过实验数据验证的业务假设。

---

## 8. Billing Page A/B Test

本项目对数据中已有的 Billing 页面历史实验进行复盘分析。

### 实验定义

- 实验窗口：**2012-09-10 至 2012-11-09**
- Control：`/billing`
- Treatment：`/billing-2`
- 实验对象：实际进入 Billing 实验页面的 Sessions
- 实验单位：**Session**

实验样本：

| Group | Sessions |
|---|---:|
| Control | 657 |
| Treatment | 654 |

Cross Exposure Sessions：

**0**

这里的 Purchase Conversion Rate 指：

> **Billing-to-Purchase Conversion Rate**

而不是全站 Purchase Conversion Rate。

本项目是对公开历史实验进行复盘分析，并非本人设计、分流或上线该实验。

---

## 9. A/B 实验结果

Primary Metric：

**Billing-to-Purchase Conversion Rate**

| 统计量 | 结果 |
|---|---:|
| Control CR | 45.66% |
| Treatment CR | 62.69% |
| Absolute Lift | +17.03 pp |
| Relative Lift | +37.29% |
| Z statistic | 6.19 |
| p-value | < 0.001 |
| 95% Confidence Interval | +11.71 pp 至 +22.34 pp |
| SRM p-value | 0.934 |

Two-Proportion Z-Test 显示两组 Purchase CR 差异具有统计显著性。

同时：

> **95% Confidence Interval 完全高于 0。**

在当前样本下，新版 Billing 页面的真实转化提升具有明确的正向统计证据。

SRM 检查结果：

`p = 0.934`

未发现明显的样本比例失配证据。

需要注意：

> SRM 正常并不等于证明随机化过程完全没有问题，只说明当前 Control / Treatment 样本比例没有表现出明显异常。

---

## 10. 商业价值

除了 Purchase CR，本项目进一步比较 Revenue per Billing Session：

| 指标 | Control | Treatment | Difference |
|---|---:|---:|---:|
| Revenue per Billing Session | $22.83 | $31.34 | +$8.51 |

新版页面不仅提高了购买概率，同时提高了每个 Billing Session 创造的平均收入。

因此，实验效果不仅具有统计意义，也表现出了明确的商业价值：

> **Treatment 每个 Billing Session 平均多产生约 $8.51 的收入。**

---

## 11. Refund Guardrail

为了避免只关注转化率而忽略潜在副作用，对退款表现进行 Guardrail 检查。

| 指标 | Control | Treatment | Difference |
|---|---:|---:|---:|
| Orders | 300 | 410 | — |
| Refund Rate | 6.67% | 9.51% | +2.85 pp |

Refund Rate Test：

**p = 0.175**

实验组退款率点估计高于对照组，但差异未达到统计显著水平。

因此，更严谨的解释是：

> 当前数据未提供足够证据表明新版页面导致退款率显著恶化，但退款率点估计确实有所上升，因此不能认为退款风险已经被完全排除。

这也是为什么最终业务决策不能只依据 Purchase CR，而需要在推广阶段继续监控 Refund Rate。

---

## 12. 策略落地与持续监控

综合 Purchase CR、Confidence Interval、Revenue per Billing Session 和 Refund Guardrail，本项目建议：

### 12.1 推广策略

优先采用新版 Billing 页面。

主要依据：

- Billing-to-Purchase Conversion Rate 从 **45.66% 提升至 62.69%**；
- Absolute Lift 为 **+17.03 pp**；
- 95% Confidence Interval 完全为正；
- `p < 0.001`；
- Revenue per Billing Session 从 **$22.83 提升至 $31.34**；
- SRM 未发现明显样本比例失配；
- Refund Rate 虽然点估计较高，但当前差异未达到统计显著水平。

实际业务落地时，不建议只依据一次历史实验后立即完全替换旧页面，更稳妥的方式是分阶段扩大新版页面流量：

~~~text
新版页面实验胜出
        ↓
小流量 / 分阶段扩大覆盖
        ↓
确认 Purchase CR 提升是否保持
        ↓
同步监控 Revenue 与 Refund Guardrail
        ↓
未出现明显副作用
        ↓
继续扩大新版页面覆盖
        ↓
逐步替换旧 Billing 页面
~~~

---

### 12.2 上线后持续监控

重点持续监控三个指标：

#### 核心转化指标

- **Billing-to-Purchase Conversion Rate**

回答：

> 新版页面的转化优势在真实扩大流量后是否仍然保持？

#### 商业价值指标

- **Revenue per Billing Session**

回答：

> 转化提升是否继续产生实际收入价值？

#### 护栏指标

- **Refund Rate**

回答：

> 转化提高是否伴随着退款风险明显恶化？

尤其考虑到 Treatment Refund Rate 点估计高于 Control，上线扩大流量后仍需要持续观察退款表现。

如果出现：

- Purchase CR 优势明显消失；
- Revenue per Billing Session 不再改善；
- Refund Rate 出现具有业务意义的明显恶化；

则需要重新评估推广范围，而不是因为历史实验曾经显著就永久不再检查。

---

### 12.3 下一轮优化

Billing 页面并不是购买路径中唯一存在明显流失的环节。

漏斗中：

> **Product Detail → Cart Drop-off = 56.41%**

仍然是非常明显的结构性损失。

因此，Billing 页面优化完成后，下一轮分析可以进一步聚焦：

~~~text
Product Detail
        ↓
Cart
~~~

进一步研究商品详情页到加购阶段可能存在的转化摩擦，例如：

- 商品信息是否足够清晰；
- 商品选择流程是否复杂；
- Add to Cart 行为是否存在页面交互摩擦；
- 页面内容是否能够有效推动购买意图形成。

在形成新的页面优化假设后，再通过下一轮实验验证。

至此形成完整分析闭环：

> **监控 → 诊断 → 定位问题 → 提出假设 → 实验验证 → 策略推广 → 上线监控 → 下一轮优化**

---

## 13. Power BI Dashboard

Power BI Dashboard 共 3 页。

### Page 1｜电商业务概览

主要展示：

- Sessions
- Orders
- Purchase Conversion Rate
- Revenue
- Revenue per Session
- 完整季度 Sessions / Orders 趋势
- 季度 Purchase Conversion Rate
- 季度 Revenue per Session

目的：

> 判断整体业务是否存在持续性恶化，并建立后续分析背景。

---

### Page 2｜购买转化漏斗

主要展示：

- 各漏斗阶段到达 Sessions
- 各步骤 Drop-off Rate
- Product Detail → Cart
- Billing → Purchase

目的：

> 定位购买路径中的主要结构性转化损失。

---

### Page 3｜结算页 A/B 测试

主要展示：

- Control / Treatment Purchase CR
- Absolute Lift
- Relative Lift
- Revenue per Billing Session
- p-value
- 95% Confidence Interval
- SRM
- Refund Guardrail

目的：

> 判断新版 Billing 页面是否真正改善最终购买转化，并评估商业价值与潜在副作用。

---

仓库保留可进行版本控制的 PBIP、PBIR 与 Semantic Model 文件。

首次在其他电脑打开 Power BI 项目时，需要将数据源重新映射至本项目：

`output/tables/`

目录。

---

## 14. Repository Structure

~~~text
maven-ecommerce-funnel-ab-test/
│
├── README.md
├── .gitignore
│
├── data/
│   └── maven_fuzzy_factory_data_dictionary.csv
│
├── sql/
│   ├── 00_create_and_import.sql
│   ├── 01_data_quality.sql
│   ├── 02_core_metrics.sql
│   ├── 03_funnel_analysis.sql
│   └── 04_ab_test.sql
│
├── notebooks/
│   └── 01_ab_test.ipynb
│
├── output/
│   └── tables/
│       ├── overall_metrics.csv
│       ├── monthly_metrics.csv
│       ├── quarterly_metrics.csv
│       ├── funnel_metrics.csv
│       ├── ab_experiment_sample.csv
│       └── ab_test_summary.csv
│
└── powerbi/
    ├── Maven_Ecommerce_AB.pbip
    ├── Maven_Ecommerce_AB.Report/
    ├── Maven_Ecommerce_AB.SemanticModel/
    └── POWER_BI_BUILD_GUIDE.md
~~~

---

## 15. 项目边界 / Limitations

1. 数据来自 Maven Analytics 教学模拟电商数据库，并非真实企业生产数据。
2. 漏斗使用固定 `gsearch + nonbrand` cohort，以尽量保证页面路径版本的一致性，因此漏斗结果不应直接解释为整个三年全站用户行为。
3. 本项目复盘已有 Billing 页面历史实验，并非本人设计、随机分流或上线该实验。
4. Refund Rate 的组间差异未达到统计显著水平，但 Treatment 点估计较高，因此当前结果不能证明退款风险不存在。
5. 本项目的业务建议属于基于历史实验数据的分析复盘，实际生产环境中的上线决策仍应结合实时业务表现、实验运行环境及持续监控结果。

---

## 16. 最终项目结论

本项目完成了一条完整的电商数据分析业务链路：

~~~text
整体经营监控
        ↓
发现业务总体健康增长
        ↓
购买漏斗诊断
        ↓
定位结构性转化损失
        ↓
聚焦 Billing 高价值末端环节
        ↓
复盘历史 A/B 实验
        ↓
Purchase CR 显著提升
        ↓
Revenue 同步提高
        ↓
Refund Guardrail 检查
        ↓
形成分阶段推广建议
        ↓
上线后持续监控
        ↓
Product Detail → Cart 下一轮优化
~~~

最终结果表明：

> **新版 Billing 页面将 Billing-to-Purchase Conversion Rate 从 45.66% 提升至 62.69%，绝对提升 17.03 个百分点，相对提升 37.29%；Revenue per Billing Session 同时从 $22.83 提升至 $31.34。**

在当前实验样本下，该转化提升具有明确统计证据。

Refund Rate 虽然点估计有所上升，但差异未达到统计显著水平，因此最终建议是：

> **优先采用新版 Billing 页面，通过分阶段扩大流量进行推广，并持续监控 Purchase CR、Revenue per Billing Session 和 Refund Rate；完成该轮优化后，再将 Product Detail → Cart 作为下一轮漏斗优化候选。**
