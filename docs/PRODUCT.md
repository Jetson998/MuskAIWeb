# Musk WebAI Product Notes

## Product Positioning

Musk WebAI is a self-hosted AI workbench based on Open WebUI, customized for business users who need practical analysis workflows instead of generic chat prompts.

The first-screen experience is designed around three high-value scenarios:

1. Tencent equity research
2. AI startup scouting
3. Procurement contract review

The goal is to make each starter prompt feel like a professional service entry point: the user clicks once, then the assistant follows a structured workflow, asks for missing materials only when needed, and produces a usable business output.

## Current Homepage Starters

### Tencent Holdings Deep Dive

Card title:

```text
腾讯控股深度拆解
财报、回购与增长变量一页看懂
```

Purpose:

- Analyze Tencent Holdings, 0700.HK, with a Tencent-specific TMT research framework.
- Force live freshness checks before analysis.
- Require source-backed financial data.
- Separate GAAP and Non-GAAP figures.
- Focus on valuation drivers: games, advertising, FBS, margin, buyback, shareholder return, and key risks.

Expected output:

- Core conclusions
- Revenue and profit changes
- Tencent-specific segment analysis: games, advertising, FBS
- Margin and expense changes
- Cash flow, buyback, dividend
- Tencent-specific risks
- Next-quarter KPIs
- Plain-language investor summary

Important behavior:

If the latest reliable financial report cannot be retrieved, the assistant must stop and ask the user to upload a PDF or provide an HKEX disclosure link.

### Global AI Project Radar

Card title:

```text
全球AI项目雷达
从开发者热榜发现早期机会
```

Purpose:

- Find one high-potential AI or frontier technology project from Hacker News Show HN.
- Use a stable public API path instead of a long list of noisy websites.
- Avoid analysis when valid data is unavailable.

Primary data path:

```text
https://hn.algolia.com/api/v1/search?tags=show_hn&hitsPerPage=20
```

Screening rules:

- Choose one project only.
- Prefer projects with points >= 50 or comments >= 30.
- Exclude pure demos, tutorials, and personal toy projects.
- Prefer AI, developer tools, SaaS, infrastructure, or similar technology categories.

Expected output:

- Project name and links
- Core problem
- Target users
- Product highlights
- Reason for recent attention
- Commercialization potential
- Competitors
- Investment highlights
- Key risks
- Follow-up due diligence recommendation
- Source list

### Procurement Contract Risk Review

Card title:

```text
采购合同风险体检
定位风险、改条款、给谈判话术
```

Purpose:

- Review B2B procurement contracts from a mainland China buyer-side perspective.
- Combine legal risk, procurement execution risk, and negotiation strategy.
- Produce actionable redlines, replacement clauses, and business-facing negotiation language.

Default stance:

- Buyer/procurement side, unless the user explicitly says they represent the supplier.
- Mainland China law only.

Core review areas:

- Payment terms
- Acceptance standards
- Delivery milestones
- Warranty responsibility
- Breach liability
- Termination
- Confidentiality
- Intellectual property
- Data compliance
- Dispute resolution
- Jurisdiction

Expected output:

- Signing recommendation
- Risk table with exact source location
- Eleven-clause checklist
- Procurement execution risks
- Overall contract optimization
- Action list for business colleagues

Important behavior:

- Every response must include the AI/legal disclaimer.
- Every risk must cite a clause number or text anchor.
- Offshore governing law or offshore arbitration is a blocking risk.
- Data processing, cross-border transfer, and system integration must trigger PIPL/Data Security Law checks.

## Branding Requirements

Visible product name:

```text
Musk WebAI
```

External links previously pointing to Open WebUI domains should point to:

```text
http://www.muskapis.com
```

Known branding decisions:

- Top-left product name uses Musk WebAI.
- Frontend Open WebUI-related external links are replaced with muskapis.com.
- The `/workspace/models` community promotional block is disabled.
- The visible model page text `Made by ... Community`, `Discover a model`, and related community discovery text is removed from the models page.

## Non-Goals

- This project is not intended to expose Open WebUI marketplace/community navigation to end users.
- The current customization should not leak API keys, server passwords, or admin-only provider credentials.
- The homepage should not become a long prompt library; the current product direction is three focused, high-quality entry points.
