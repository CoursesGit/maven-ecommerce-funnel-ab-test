# Maven Fuzzy Factory Billing Page A/B Test Analysis

基于 Maven Fuzzy Factory 历史 Billing Page 实验数据，完成 A/B Test 效果评估、实验有效性检查和业务分析。本项目是对既有历史实验的复盘，不声称设计、执行随机分流或负责实验上线。

## Project Overview

### Business Background

Maven Fuzzy Factory 是一个模拟电商网站。用户沿购买路径浏览商品、进入购物车、填写配送信息并到达 Billing 页面。历史数据中同时存在 `/billing` 与 `/billing-2` 两个页面版本，因此可以重构 Billing Page 实验样本，评估两个版本在购买转化和商业指标上的差异。

### Analysis Objective

- 理解四张核心业务表及数据质量。
- 使用购买漏斗说明 Billing 环节的业务价值，但不把漏斗诊断当作实验结果。
- 根据首次 Billing 页面曝光重构 Session 级实验样本。
- 检查 SRM、协变量平衡和用户跨组问题。
- 评估购买转化、收入和退款相关指标。
- 在证据边界内提出分阶段推广和持续监控建议。

## Experiment Overview

| Item | Definition |
|---|---|
| Control | `/billing` |
| Treatment | `/billing-2` |
| Experiment unit | Session-level Billing Page exposure |
| Assignment reconstruction | Each Session's first eligible Billing exposure |
| Experiment period | 2012-09-10 to 2012-11-10 (end exclusive) |

本项目没有原始随机化日志或事前实验文档。Control 与 Treatment 是依据历史页面曝光重构，而不是由本项目重新分流。

当前分析窗口为2012-09-10（含）至2012-11-10（不含），窗口内`/billing`与`/billing-2`均存在曝光。由于缺少原始实验配置、随机化日志和窗口外完整运行记录，本项目不能证明该区间覆盖完整实验生命周期；该区间应被理解为历史实验复盘窗口。

## Data Sources

| Table | Grain | Purpose |
|---|---|---|
| `website_sessions` | One website Session | User, device, repeat-session and acquisition attributes |
| `website_pageviews` | One pageview | Page sequence and Billing exposure |
| `orders` | One order | Purchase and gross revenue |
| `order_item_refunds` | One refund record | Refund amount and net revenue |

字段说明见 `data/reference/maven_fuzzy_factory_data_dictionary.csv`。大型原始 CSV 放在本地 `data/raw/`，该目录不进入 GitHub。

## Analysis Workflow

1. Business Context
2. Data Understanding
3. Funnel Diagnosis
4. Experiment Reconstruction
5. Experiment Validity Check
6. Metric Analysis
7. Business Recommendation

## Metrics Framework

### Primary Metric

- **Billing-to-Purchase Conversion Rate** = purchased Billing Sessions / eligible Billing Sessions

### Diagnostic Metric

- **Billing Abandonment Rate** = Billing Sessions without purchase / eligible Billing Sessions

### Guardrail Metrics

- **Revenue per Billing Session** = gross revenue / eligible Billing Sessions
- **Net Revenue per Billing Session** = (gross revenue - refunds) / eligible Billing Sessions
- **Refund Rate** = refunded orders / purchased orders

## Experiment Validity

Before effect estimation, the project checks:

- Sample Ratio Mismatch using a chi-square test.
- Balance in `device_type`, `is_repeat_session`, `utm_source`, `utm_campaign`, and experiment date.
- Session cross-exposure and user crossover.
- Sensitivity under all Sessions, exclusion of crossover users, and first experiment Session per user.

Passing these checks supports interpretation of the reconstructed sample, but does not replace an original randomization log.

## Key Results

| Metric | Result |
|---|---:|
| Control conversion rate | 45.66% |
| Treatment conversion rate | 62.69% |
| Absolute Lift | **+17.03 pp** |
| Relative Lift | **+37.29%** |
| Revenue per Billing Session improvement | **+$8.51** |

The primary conversion difference is statistically significant and the sensitivity analyses are directionally consistent. Revenue and net revenue per Billing Session also improve in the historical sample. Treatment has a higher observed refund rate, so refund performance remains a rollout guardrail rather than being ignored.

## Business Recommendation

The historical evidence supports gradually expanding traffic to the treatment experience within a controlled rollout. Continue monitoring conversion, gross and net revenue per Billing Session, and refund rate; retain rollback criteria and validate longer-term outcomes before broader adoption.

## Project Structure

```text
maven_ecommerce_ab/
├── README.md
├── data/
│   ├── raw/                              # local only; ignored by Git
│   └── reference/
│       └── maven_fuzzy_factory_data_dictionary.csv
├── notebooks/
│   ├── 00_Business_Context.ipynb
│   ├── 01_Data_Understanding_and_Audit.ipynb
│   ├── 02_Funnel_Diagnosis.ipynb
│   ├── 03_Experiment_Design_and_Sample.ipynb
│   ├── 04_Experiment_Analysis.ipynb
│   └── 05_Business_Recommendation.ipynb
├── sql/
│   ├── 00_create_and_import.sql
│   ├── 01_data_quality.sql
│   ├── 02_funnel_diagnosis.sql
│   ├── 03_experiment_sample.sql
│   └── 04_experiment_validation.sql
└── output/
    └── tables/
```

## Reproducibility

1. Download the source data separately and place the four raw CSV files under `data/raw/`.
2. Replace the local data directory placeholder in `sql/00_create_and_import.sql` with the absolute path used by the local MySQL client.
3. Run SQL scripts in numeric order.
4. Open the notebooks from the `notebooks/` directory so relative paths such as `../output/tables` resolve correctly.

## Limitations

- **Historical experiment reconstruction:** this is a retrospective analysis of an existing experiment.
- **No original randomization log:** assignment mechanics cannot be fully verified.
- **Session-level experiment unit:** repeated Sessions from the same user are not fully independent user-level assignments.
- **User crossover limitation:** a small number of users appear in both groups; sensitivity analysis reduces but cannot erase this implementation limitation.
- **Long-term effect not evaluated:** the available analysis does not establish long-term repeat purchase, customer value, or refund effects.
- **Simulated-data external validity:** Maven Fuzzy Factory为教学模拟数据，观察到的效果幅度可能高于真实线上环境，不应直接作为其他业务场景的提升预期。

## Technical Skills

- SQL and relational data modeling
- Python and Pandas
- Funnel and cohort analysis
- SRM and covariate balance checks
- Two-proportion Z-test and confidence intervals
- Bootstrap analysis for revenue metrics
- Experiment sensitivity analysis
