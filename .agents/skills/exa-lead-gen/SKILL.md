---
name: exa-lead-gen
description: Generate enriched lead lists using Exa deep search. Finds companies matching an ICP, enriches with signals/news/scores, and outputs CSV. Use for lead gen, prospect lists, outbound research, or ICP-based company discovery.
license: MIT
metadata:
  audience: go-to-market teams
  workflow: lead-generation
---

# Documentation Index

Fetch the complete documentation index first:

`https://exa.ai/docs/llms.txt`

Use that file to discover all available pages before exploring further.

# Lead Generation with Exa Deep Search

This skill generates large, enriched lead lists by running parallel Exa deep searches across micro-verticals derived from an ICP.

## Prerequisites

- Exa API key from `https://dashboard.exa.ai/api-keys`
- Exa MCP server installed and reachable
- A deep search tool exposed by your harness (name can vary)

If the deep search MCP tool is unavailable, tell the user:

> You need the Exa MCP server installed with your API key.
> Instructions: https://docs.exa.ai/reference/exa-mcp

Then stop.

## Harness-Agnostic Tooling

- Use your harness's Exa deep search MCP tool (often named similar to `deep_search_exa`)
- Use agent/subagent orchestration if available for batching
- Use file write/edit tools for temporary JSON files
- Use shell only for Python CSV compilation

Do not depend on Claude-specific tool names or Claude-only commands.

## Architecture: Subagent-Driven Lead Gen

Main orchestrator stays lean; workers process raw lead payloads.

1. ICP research (1 deep search call)
2. Micro-vertical generation (LLM reasoning)
3. Output schema design (LLM reasoning)
4. Batch workers (5 micro-verticals per worker)
5. Python CSV compiler (dedupe/sort/export)
6. Final summary

Workers should write raw structured outputs to `/tmp/exa_leads_batch_{batch}_{index}.json` and report only counts.

## Deep Search Parameter Model

Each deep search call uses three distinct parameters:

- `objective`: embedding-space retrieval query
- `systemPrompt`: extraction/scoring behavior
- `outputSchema`: strict output structure

Required on every production lead-gen call:

- `structuredOutput: true`
- `numResults: 50`
- `highlightMaxCharacters: 1`
- `type: "deep"`

Keep `numResults` and prompt target aligned: ask for exactly 50 companies.

## Output Schema Constraints

- Max 10 properties total across all nesting levels
- Array items must be flat objects with primitive fields only
- Root must be `{ "type": "object" }`
- Allowed field types: `string`, `integer`, `boolean`, `array` of `string`

All string fields must include explicit length limits in descriptions (for example: "12 words or less").

## Step 1: ICP Research Call

Run one deep search call:

- `objective`: `About {company_name}, {company_name} customers`
- `systemPrompt`: infer product, customers, ICP, sub-verticals, enrichments
- `outputSchema`: include company description, product description, existing customers, ICP, sub-verticals, demographic signals, useful enrichments
- `structuredOutput: true`, `numResults: 10`, `type: "deep"`, `highlightMaxCharacters: 1`

Then ask user to confirm/refine:

- ICP accuracy
- sub-vertical additions/removals
- exclusions (competitors/current customers)
- lead target count (default 200)
- priority enrichment columns

## Step 2: Micro-Vertical Expansion

Generate micro-verticals internally (no API call).

Target count: `ceil(requested_leads / 35)`.

Expansion patterns:

- competitor mining
- geography slices
- stage slices
- technology stack slices
- use-case decomposition
- buyer persona targeting

Quality bar per query:

- 4-8 descriptive keywords
- minimal overlap
- specific but not too narrow

## Step 3: Output Schema Design

Always include core fields:

- `company_name` (string, 5 words or less)
- `website` (string, homepage URL)
- `product_description` (string, 12 words or less)
- `icp_fit_score` (integer, 1-10)
- `icp_fit_reasoning` (string, 20 words or less)

Then add campaign-specific enrichments while keeping item-level fields at 9 or fewer.

Warn about latency when enrichment columns are high.

## Step 4: Batch Workers

Group micro-verticals into batches of 5.

Worker behavior:

- run one deep call per micro-vertical
- use required params (`structuredOutput`, `numResults`, `highlightMaxCharacters`, `type`)
- run calls in parallel per worker when possible
- write each structured output payload to `/tmp/exa_leads_batch_{batch}_{index}.json`
- return summary only: counts + file glob

If call fails, skip and report failure count. Do not retry identical query.

For 10+ workers, launch in waves of about 6.

## Step 5: CSV Compilation with Python

Compile with Python script that:

- reads `/tmp/exa_leads_batch_*.json`
- extracts company arrays from common response shapes
- deduplicates by normalized company name (strip legal suffixes)
- keeps duplicate with higher `icp_fit_score`
- sorts descending by `icp_fit_score`
- joins array columns with ` | `
- writes `{target_company}_leads_{YYYY-MM-DD}.csv` via `csv.writer`
- prints totals, dedupe count, score distribution
- deletes temp batch files

## Step 6: Final Output Block

Return:

`Lead Generation Complete`

- total leads
- duplicates removed
- ICP score distribution
- deep calls made
- worker batches used
- CSV output filename

## Performance and Failure Handling

- Typical deep call latency: 4-12s (higher with larger schemas)
- Typical yield: about 35-48 companies/call when asking for 50
- If more than 50% calls fail, notify user and suggest smaller run
- Continue through partial failures when under that threshold

## Generic MCP Configuration Example

Use your harness config format to register an Exa MCP HTTP server pointing to:

`https://mcp.exa.ai/mcp?tools=deep_search_exa&exaApiKey=YOUR_EXA_API_KEY`

Note: exact config keys depend on your harness.

## Post-Install Note

After adding or changing MCP server config, restart your agent/CLI session so tool registry refreshes.
