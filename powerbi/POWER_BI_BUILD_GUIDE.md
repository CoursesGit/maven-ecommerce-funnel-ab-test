# Maven Billing Page A/B Test Decision Dashboard

Open `Maven_Ecommerce_AB.pbip` with a Power BI Desktop version that supports PBIP/PBIR projects.

## Dashboard pages

1. **Experiment Overview** — conversion KPIs, lift, p-value, sample size, experiment definition, and Control/Treatment comparison.
2. **Business Impact** — conversion, abandonment, gross and net revenue per Billing Session, and refund-rate monitoring.
3. **Experiment Quality** — SRM, sample shares, covariate balance, and user crossover.

## Data sources

The semantic model uses only the following current experiment outputs:

- `experiment_primary_metric.csv`
- `experiment_guardrail_metrics.csv`
- `experiment_diagnostic_metrics.csv`
- `experiment_srm_check.csv`
- `experiment_balance_summary.csv`
- `experiment_user_crossover_check.csv`
- `experiment_exposure_audit.csv`

All files are under `output/tables/`. The report does not use `ab_test_summary.csv`, legacy operating metrics, or the old funnel output.

## Refresh on another computer

PBIP stores local CSV locations in the semantic model partitions. After cloning, update each partition's `File.Contents` path to the repository's local `output/tables/` directory, then refresh the model.

The dashboard reports a historical experiment reconstruction. It does not represent ownership of randomization or rollout.
