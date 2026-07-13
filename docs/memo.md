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

Coverage is low and non-random.The sample skews toward professional, office, and
technical work, tertiary educated, urban, younger, and English-fluent. Checking 
the occupation codes directly, the largest groups are computing, sales, office 
administration, management, and business, with substantial food service too, 
while manual, agricultural, and informal work is thin or absent (there is no 
farming, fishing, or forestry at all). Greece's economy isheavy on SMEs, 
tourism, shipping, self-employment, the public sector, and informal work, most 
of which is missing or badly undercounted here. Any statement we make describes 
the covered population, not Greek workers in general. This limits external 
validity for anything at the level of the national labour market.

## Geography quality

Regional analysis is only partly reliable, and which field you use matters. In
the individuals data, the metro_area field is not trustworthy: it reported only
47 Thessaloniki records while the city field showed 86,804 and the state field
showed 123,317 for the surrounding region. So metro_area disagrees badly with
city and state, and should not be used. The state field is reliable and shows a
strong Athens skew: Attica holds about 35 percent of records and Central
Macedonia about 9 percent, with everything else small and about 44 percent
carrying no state.

Missing geography is also encoded inconsistently: postings use the literal word
"empty" for a missing region, individuals use a blank (NA), so both forms have
to be caught. Postings geography is more complete than individuals (under 10
percent missing state, versus 44 percent). So regional analysis is feasible
using the state or city fields, not metro_area, and should account for the heavy
Athens concentration and the large share of records with no region.

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

The postings data covers 2010 to 2026, but only becomes usable from around 2021.
The earlier years are very thin, often only a few hundred postings for the 
entire country, which is too little to mean anything. From 2021 the volume grows
steadily, from about 69,000 to 455,000 by 2025, with 2026 partial because the 
year is incomplete. One year stands out: 2016 has 51,061 postings, sitting 
between years with only a few hundred. This is a data-source artefact, not real 
hiring: 51,041 of those postings (99.96 percent) came from Indeed, a single 
large dump. More broadly the sources change over time, LinkedIn does not appear 
until around 2020, and the share of postings with a company id swings year to 
year. So any cross-year comparison partly reflects changes in data sources, not 
the labour market.

Testing that directly confirms it. Comparing postings per year three ways, all 
postings, only those with a company id, and excluding Indeed, the 2016 spike of 
51,061 drops to 20 once Indeed is removed, so it was entirely a source dump. In 
recent years the effect is large too: 2023 and 2024 rise from 333,000 to 418,000
in the raw counts, but excluding Indeed they are flat at about 158,000 and 
160,000, so most of that apparent growth is Indeed being added, not more hiring.
There is genuine growth earlier (2020 to 2022 roughly doubles even without 
Indeed), but the raw series should not be read as a hiring trend. The safer 
series excludes Indeed or requires a company id.

The monthly view dates these source changes exactly. Indeed first appears in 
December 2015 (so the 2016 dump is Indeed switching on), and LinkedIn first 
appears in May 2020, which is when the 2020-2021 rise begins. Before 2016 only 
company sites and staffing firms feed the data, which is why the early years are
so thin. So the shape of the series tracks when each source came online as much 
as any change in hiring.

The postings-by-year figure in `output/` shows this, and carries the coverage 
caveat on its face.

## Consistency and linkage

The schema is consistent across years within each dataset. Individuals files
all share the same 29 columns and postings files the same 28, in the same order.
I checked this by comparing column names across years.

The two datasets share eleven columns, including the company id (rcid), the
ultimate parent, the role clusters (role_k1500_v2, role_k17000_v3), and
onet_code. So they use common company and role coding, which is what any linkage
between labour supply (individuals) and demand (postings) would rely on. The 
companies also overlap in practice: across all years there are about 33,700 
firms in the postings, and about 22,200 of them also appear in the individuals 
data, roughly two-thirds of posting firms.

Because the columns are identical across years, the yearly files stack (append)
cleanly into one dataset. The pipeline already treats them this way: postings
are combined across years into one table of 1,574,217 rows, and the individuals
files are opened together as a single dataset. I have not written a physically
merged individuals file, and would not without a plan for where 46 million
person-level rows should live.

Two limits. First, shared column names do not guarantee identical coding or
reliability underneath; I confirmed names, not values, and some shared fields
(metro_area) I already know are unreliable. Second, on matching people to jobs:
individuals are keyed by user_id and position_id, postings by job_id, and
nothing links a person to a specific posting. So we cannot match a person to an
individual job ad. Company-and-role linkage is possible, but only in the recent
window where both have real coverage (postings from about 2021), and both sides
are biased samples.

## Firm-level feasibility

Whether firms can be analysed over time depends on how much data each firm has.
Across all postings years there are 33,717 firms with a company id, but most are
thin: the median firm has 3 postings across 2 years, and about 46 percent
(15,601 firms) appear in only one year. So a panel over all firms would be
mostly noise.

A usable core does exist. About 10,800 firms appear in 3 or more years, 3,980 in
5 or more, and 2,483 have 50 or more total postings. So firm-level analysis is
feasible, but only for a filtered subset meeting a threshold (for example
appearing in several years or having enough postings), not the full firm set.
This narrows the linkage picture too: the firms usable for a linked firm panel
are those that both have enough postings and also appear in the individuals
data.

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
