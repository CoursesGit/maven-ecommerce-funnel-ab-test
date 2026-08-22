# Maven Fuzzy Factory Billing Page A/B Test Analysis

基于 Maven Fuzzy Factory 历史 Billing Page 实验数据，完成 A/B Test 效果评估、实验有效性检查和业务分析。

本项目属于**既有历史实验的复盘分析**，不声称参与原始实验设计、随机分流执行或页面上线。

---

## Project Overview

### Business Background

Maven Fuzzy Factory 是一个模拟电商网站。

用户沿购买路径浏览商品、进入购物车、填写配送信息，并最终到达 Billing 页面完成结算。

历史数据中同时存在两个 Billing 页面版本：

- `/billing`
- `/billing-2`

因此可以基于页面曝光日志重构历史实验样本，评估两个页面版本在购买转化、收入效率和退款风险方面的差异。

### Analysis Objective

本项目主要回答以下问题：

1. 四张核心业务表能否支持历史实验复盘？
2. Billing 环节为什么具有业务分析价值？
3. 如何根据页面曝光日志重构 Control 与 Treatment？
4. 重构后的实验样本是否存在明显分流或组间失衡问题？
5. 新版 Billing 页面是否提高购买转化率？
6. 转化提升是否同时带来更高的 Session 级收入？
7. 是否存在退款率上升等业务风险？
8. 在历史实验信息不完整的情况下，结果是否具有足够稳健性支持后续决策？

---

## Experiment Overview

| Item | Definition |
|---|---|
| Control | `/billing` |
| Treatment | `/billing-2` |
| Experiment Unit | Session-level Billing Page exposure |
| Assignment Reconstruction | Each Session's first eligible Billing Page exposure |
| Analysis Window | 2012-09-10 to 2012-11-10, end exclusive |
| Primary Metric | Billing-to-Purchase Conversion Rate |

本项目没有原始随机化日志或事前实验设计文档。

Control 与 Treatment 是根据历史页面曝光进行重构，而不是由本项目重新执行随机分流。

当前分析窗口为：

> 2012-09-10（含）至 2012-11-10（不含）

在该窗口内，`/billing` 与 `/billing-2` 均持续存在曝光。

由于缺少原始实验配置、随机化日志以及窗口外完整运行记录，本项目**不能证明该区间覆盖完整实验生命周期**。

因此，该时间范围应被理解为：

> **历史实验复盘窗口（Historical Review Window）**

而不是由本项目确认的完整线上实验周期。

---

## Data Sources

项目使用四张核心业务表：

| Table | Rows | Grain | Purpose |
|---|---:|---|---|
| `website_sessions` | 472,871 | One website Session | 用户、设备、新老访问及流量来源属性 |
| `website_pageviews` | 1,188,124 | One pageview | 页面访问顺序与 Billing 页面曝光 |
| `orders` | 32,313 | One order | 购买结果与订单收入 |
| `order_item_refunds` | 1,731 | One refund record | 退款金额与净收入分析 |

字段说明见：

`data/reference/maven_fuzzy_factory_data_dictionary.csv`

大型原始 CSV 文件仅保存在本地：

`data/raw/`

该目录已通过 `.gitignore` 排除，不上传 GitHub。

---

## Data Relationship

核心数据关系为：

```text
website_sessions
        │
        ├── website_pageviews
        │
        └── orders
                │
                └── order_item_refunds
