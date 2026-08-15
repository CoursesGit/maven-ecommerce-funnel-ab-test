# 电商转化漏斗诊断与 Billing Page A/B 测试分析

**SQL + Python/Pandas + Power BI**

本项目基于 Maven Analytics 的 Maven Fuzzy Factory 教学模拟电商数据库，复盘网站整体经营表现、购买漏斗以及历史 Billing Page A/B Test。业务目标是识别高价值转化损失，并判断新版结算页是否带来可验证的增量转化与收入。

> 核心结论：网站整体经营表现长期改善，但购买路径仍存在结构性流失。新版 Billing 页面将 Billing-to-Purchase Conversion Rate 从 **45.66%** 提升至 **62.69%**，Absolute Lift 为 **+17.03 pp**，Revenue per Billing Session 增加 **$8.51**。

## 核心业务问题

1. 网站整体经营与转化表现如何？
2. 用户购买路径中的主要结构性流失发生在哪里？
3. 新版 Billing 页面是否显著提升最终购买转化及商业价值？

## 数据

| 表 | 行数 | 说明 |
|---|---:|---|
| website_sessions | 472,871 | 网站会话、用户及流量属性 |
| website_pageviews | 1,188,124 | Session 内页面访问记录 |
| orders | 32,313 | 订单与收入 |
| order_item_refunds | 1,731 | 退款记录 |

- 主要观察期：**2012-03-19 至 2015-03-19**
- 退款表包含额外的后续观察窗口
- 数据为教学 / 模拟电商数据库，不是真实公司生产数据
- 官方来源：[Maven Analytics — Toy Store E-Commerce Database](https://mavenanalytics.io/data-playground/toy-store-e-commerce-database)
- 字段定义见 data/maven_fuzzy_factory_data_dictionary.csv

大型原始 CSV 未包含在仓库中，可通过官方数据页面获取。

## 工具

- SQL / MySQL
- Python / Pandas
- statsmodels / scipy
- Power BI（PBIP / PBIR）

## 分析流程

数据质量检查 → 整体业务指标 → 完整季度经营趋势 → 购买漏斗诊断 → 定位结构性流失 → Billing Page A/B Test → 统计检验 → Refund Guardrail → 业务建议

## 数据质量

- 四张表导入行数与原始 CSV 一致
- 主键重复 = 0
- 核心字段 NULL = 0
- Pageview → Session 孤儿记录 = 0
- Order → Session 孤儿记录 = 0
- Refund → Order 孤儿记录 = 0
- 金额与数量字段基础异常 = 0

数据质量较高，因此没有为了展示技术而进行无意义删除、填补或修改。

## 整体业务表现

| 指标 | 结果 |
|---|---:|
| Sessions | 472,871 |
| Users | 394,318 |
| Orders | 32,313 |
| Purchase Conversion Rate | 6.83% |
| Revenue | $1,938,509.75 |
| Revenue per Session | $4.10 |
| AOV | $59.99 |

总体指标覆盖完整观察期。趋势分析仅使用 **2012 Q2 至 2014 Q4** 的完整季度，排除数据不完整的 2012 Q1 与 2015 Q1。

流量规模、Purchase Conversion Rate 和 Revenue per Session 总体呈上行趋势。因此，本项目不围绕业务异常“救火”，而是进一步寻找结构性优化空间。

## 购买漏斗

为避免三年内 Landing Page 和页面版本变化干扰，漏斗采用固定 cohort：

- 时间：2012-08-05 至 2012-09-04
- 流量：gsearch + nonbrand
- 分析单位：Session

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

- Product Detail → Cart：**56.41% Drop-off**
- Billing → Purchase：**56.23% Drop-off**

Billing 并不是唯一或最大的瓶颈。进一步分析该环节，是因为它位于购买路径末端、用户购买意图更强、流失具有较高商业价值，且数据中存在对应的历史 Billing 页面实验。

## Billing Page A/B Test

- 实验窗口：2012-09-10 至 2012-11-09
- Control：/billing
- Treatment：/billing-2
- 实验对象：实际进入 Billing 实验页面的 Sessions
- 实验单位：Session
- Control Sessions：657
- Treatment Sessions：654
- Cross Exposure Sessions：0

这里的 Purchase CR 指 **Billing-to-Purchase Conversion Rate**，不是全站 Purchase Conversion Rate。本项目基于公开历史实验数据进行复盘分析，并非本人设计和上线实验。

## A/B 实验结果

Primary Metric：**Billing-to-Purchase Conversion Rate**

| 统计量 | 结果 |
|---|---:|
| Control | 45.66% |
| Treatment | 62.69% |
| Absolute Lift | +17.03 pp |
| Relative Lift | +37.29% |
| Z statistic | 6.19 |
| p-value | < 0.001 |
| 95% Confidence Interval | +11.71 pp 至 +22.34 pp |
| SRM p-value | 0.934 |

Two-Proportion Z-Test 显示差异具有统计显著性；95% Confidence Interval 完全高于 0。SRM 检查未发现明显样本比例失配证据，但这不等同于证明随机化完全正确。

## 商业价值

| 指标 | Control | Treatment | Difference |
|---|---:|---:|---:|
| Revenue per Billing Session | $22.83 | $31.34 | +$8.51 |

新版页面不仅提高购买概率，同时提升了单位 Billing Session 的收入。

## Refund Guardrail

| 指标 | Control | Treatment | Difference |
|---|---:|---:|---:|
| Orders | 300 | 410 | — |
| Refund Rate | 6.67% | 9.51% | +2.85 pp |

Refund Test：**p = 0.175**。

实验组退款率点估计较高，但差异未达到统计显著水平。当前数据未提供足够证据表明新版页面导致退款率显著恶化；这也不代表退款风险不存在，建议上线后持续监控。

## 最终建议

建议采用新版 Billing 页面，理由如下：

- Billing-to-Purchase Conversion Rate 显著提高
- 95% Confidence Interval 明确为正
- Revenue per Billing Session 同步提升
- SRM 未发现明显异常
- Refund Rate 点估计较高，但尚无显著恶化证据

上线后持续监控 Billing-to-Purchase Conversion Rate、Revenue per Billing Session 与 Refund Rate。

## Power BI Dashboard

Dashboard 共 3 页：

1. 电商业务概览
2. 购买转化漏斗
3. 结算页 A/B 测试

仓库保留可版本控制的 PBIP、PBIR 与 Semantic Model 文件。首次在其他电脑打开时，需要将 Power BI 数据源路径重新映射到本项目的 output/tables 目录。

## Repository Structure

    maven-ecommerce-funnel-ab-test/
    ├── README.md
    ├── .gitignore
    ├── data/
    │   └── maven_fuzzy_factory_data_dictionary.csv
    ├── sql/
    │   ├── 00_create_and_import.sql
    │   ├── 01_data_quality.sql
    │   ├── 02_core_metrics.sql
    │   ├── 03_funnel_analysis.sql
    │   └── 04_ab_test.sql
    ├── notebooks/
    │   └── 01_ab_test.ipynb
    ├── output/
    │   └── tables/
    │       ├── overall_metrics.csv
    │       ├── monthly_metrics.csv
    │       ├── quarterly_metrics.csv
    │       ├── funnel_metrics.csv
    │       ├── ab_experiment_sample.csv
    │       └── ab_test_summary.csv
    └── powerbi/
        ├── Maven_Ecommerce_AB.pbip
        ├── Maven_Ecommerce_AB.Report/
        ├── Maven_Ecommerce_AB.SemanticModel/
        └── POWER_BI_BUILD_GUIDE.md

## 项目边界 / Limitations

1. 数据来自 Maven Analytics 教学模拟电商数据库，不是真实公司生产数据。
2. 漏斗使用固定 gsearch nonbrand cohort，以保证购买路径版本相对一致。
3. 本项目复盘已有 Billing 页面历史实验，并非本人设计和上线实验。
