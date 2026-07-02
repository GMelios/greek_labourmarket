# Data quality and feasibility memo

Draft. Fill the bracketed numbers from `output/` after running the pipeline.
This memo is descriptive. It records what the data is, where it is weak, and
what it can and cannot support. It makes no causal claim and recommends no
model.

## Summary

The Revelio Greek data is usable for describing a specific, narrow slice of
professional activity that appears on public profiles and job boards. It is not
a picture of the Greek labour market. Its most important fields for wage or
demographic work are modelled, not observed. Any analysis has to be built
around these two facts rather than despite them.

## What is on disk

We verified [N] individuals files (yearly parquet, [year range]) and [M]
postings files (yearly zipped csv, [year range], with 2011-2014 missing). Row
counts, formats, and sizes are in `docs/inventory.md` and
`output/inventory_by_file.csv`. Individuals is person-level; postings is
firm-and-posting level.

## Coverage and selection

Coverage is low and non-random. The sample skews white-collar, tertiary
educated, urban (Athens and Thessaloniki), younger, tech and finance and
multinational employers, and English-fluent. Greece's economy is heavy on SMEs,
tourism, shipping, self-employment, the public sector, and informal work, most
of which is missing or badly undercounted here. Any statement we make describes
the covered population, not Greek workers in general. This limits external
validity for anything at the level of the national labour market.

## Modelled fields

Salary and the role clusters (role_k1500_v2, role_k17000_v3), plus seniority,
the sampling weight, and the onet occupation code, are estimated or inferred,
not observed. The codebook flags each in the `observed_or_modelled` column.
[State how many fields are flagged modelled and how many still sit at the
default observed_unverified pending confirmation.]

Salary is the sharpest case. It is a prediction from title, seniority, and
geography. Using it as the outcome in a wage regression is close to circular,
because the same inputs that would sit on the right-hand side of such a
regression already generated the number on the left. If salary is ever used, it
needs deliberate handling and an explicit statement of what it actually
measures.

## Backfill and survivorship

Profiles are observed as of the crawl date. Positions reaching back decades and
education reaching back further are retrospective self-report by profiles that
are active now. Any "1990s sample" is whoever survived, later built a profile,
and listed an old job. Counts before roughly 2012 mostly track platform
adoption, not the labour market. The postings-by-year figure in `output/`
carries this caveat on its face. Historical trend claims need extreme caution
and, in the early years, should not be made at all.

## Governance

Licensed WRDS / Revelio data and person-level EU data. Raw files stay on
laptops, never in the repo, never leave the project. Only aggregates appear in
any output. Demographic inference is sensitive under GDPR. The repo `.gitignore`
blocks all raw data formats, and the codebook redacts identifier and free-text
example values.

## Feasibility

What the data can support right now: description of the covered population,
counts and distributions of postings, and structure of the profile and position
records, all with the coverage caveat attached.

What it cannot support without further work or may not support at all:
[fill in after descriptives, for example wage analysis given the modelled and
circular salary, demographic breakdowns given inferred gender, and any
pre-2012 historical trend given survivorship].

## Next steps

Confirm the dataset mapping and the modelled-field flags with the supervisor,
then decide, dataset by dataset, what questions are answerable within these
limits. No modelling decisions until that is settled.
