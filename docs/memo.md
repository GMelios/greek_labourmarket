---
editor_options: 
  markdown: 
    wrap: 72
---

# Data quality and feasibility memo

Katerina Roumbos. 2 July 2026. This memo is descriptive. It records what
the data is, where it is weak, and what it can and cannot support. It
makes no causal claim and recommends no model.

## Summary

The Revelio Greek data is usable for describing a specific, narrow slice
of professional activity that appears on public profiles and job boards.
It is not a picture of the Greek labour market. Its most important
fields for wage or demographic work are modelled, not observed. Any
analysis has to be built around these two facts rather than despite
them.

## What is on disk

I verified 77 individuals files (yearly parquet, 1950-2026, about 46.5
million job-spell rows) and 13 postings files (yearly zipped csv,
2010-2026, with 2011- 2014 missing, about 1.57 million rows). Row
counts, formats, and sizes are in `docs/inventory.md` and
`output/inventory_by_file.csv`. Individuals is person-level; postings is
firm-and-posting level. I counted the postings two ways and both agree
on 1,574,217 rows.

## Coverage and selection

Coverage is low and non-random.The sample skews white-collar, tertiary
educated, urban (Athens and Thessaloniki), younger, techn and finance
and multinational employers, and English-fluent. Greece's economy is
heavy on SMEs, tourism, shipping, self-employment, the public sector,
and informal work, most of which is missing or badly undercounted here.
Any statement we make describes the covered population, not Greek
workers in general. This limits external validity for anything at the
level of the national labour market.

A geographic breakdown of the 2020 individuals file supports this. Attica
(Athens) holds about 35 percent of records and Central Macedonia (Thessaloniki's
region) about 9 percent, with every other region small and 44 percent of records
carrying no state at all. This is a strong Athens skew. Checking geography also
surfaced a data-quality problem: the metro_area field is unreliable. It reported
only 47 Thessaloniki records, while the city field showed 86,804 and the state
field showed 123,317 for Central Macedonia. Geography should be taken from state
or city, not metro_area.

## Modelled fields

Salary and the role clusters (role_k1500_v2, role_k17000_v3), plus
seniority, the sampling weight, and the onet occupation code, are
estimated or inferred, not observed. The codebook records each in the
`observed_or_modelled` column: 19 of 57 variables are flagged modelled
and 38 are left as observed-unverified. I flagged the ones the brief
named, plus a few others, by name. The 38 still need confirming against
Revelio's documentation, so that count is a starting point, not a final
split.

Salary needs care. In the 2025 postings, the salary_predicted flag is
true for 95.8 percent of rows, so almost all salary values are predicted
rather than taken from the posting. In the individuals data the salary
and compensation fields are populated for nearly every row, which is
unusual for a wage that is normally not observed, and suggests these are
modelled as well. Because salary appears to be generated from fields
like title, seniority, and geography, using it as a wage outcome against
those same fields would risk circularity. There is a small subset of
postings, around 4 percent, where salary is not predicted, but it is
likely self selected, and I have not yet confirmed with the data
documentation what the non-predicted flag actually represents.

## Backfill and survivorship

The individuals data runs from 1950, but it cannot be read as a history
of the Greek labour market. The row counts rise smoothly every year,
from 316,600 in 1950 to around 1.5 million by 2024, with no interruption
for major events like the war years or the financial crisis. A real
labour market does not grow in a clean line like that. What the data
actually shows is that people active on the platform today have listed
jobs going back decades, so the early years reflect who built a profile
recently and chose to report an old ob, not who was working at the time.
In line with the data note, I treat counts before roughly 2012 as mainly
reflecting platform adoption rather than the labour market.

## Postings coverage over time

The postings data covers 2010 to 2026, but only becomees usable from
around 2021. The earlier years are very thin, often only a few hundred
postings for the entire country, which is too little to mean anything.
From 2021 the volume grows steadily, from about 69,000 to 455,000 by
2025, with 2026 partial because the year is incomplete. One year stands
out: 2016 has around 51,000 postings, sitting between years with only a
few hundred. I cannot explain that spike yet, so I would flag it and
undretsnad where it comes from before using that year. The
postings=by-year figure in `output/` shows this, and carries the
coverage caveat on its face.

## Governance

Licensed WRDS / Revelio data and person-level EU data. Raw files stay on
laptops, never in the repo, never leave the project. Only aggregates
appear in any output. Demographic inference is sensitive under GDPR. The
repo `.gitignore` blocks all raw data formats, and the codebook redacts
identifier and free-text example values.

## Feasibility

What the data can support right now: description of the covered
population, counts and distributions of postings from about 2021 onward,
and the structure of the profile and position records, all with the
coverage caveat attached.

What it cannot support without more work: anything treating the modelled
fields as measured, wage analysis that uses salary as an outcome, and
any historical claim from the pre-2012 individuals years or the thin
pre-2021 postings years. These are not ruled out forever, but they need
the confirmations and decisions noted below first.

## Next steps

Confirm the modelled-field flags and the open data questions with the
supervisor, then decide what quesitons are answerable within these
limits. No modelling decisions until that is settled.
