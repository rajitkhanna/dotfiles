# Tracing

Capture execution traces for debugging. Traces include DOM snapshots, screenshots, network activity, and console logs.

## Basic Usage

```bash
playwright-cli tracing-start
playwright-cli open https://example.com
playwright-cli click e1
playwright-cli fill e2 "test"
playwright-cli tracing-stop
```

## What Traces Capture

- Actions (click/fill/nav)
- DOM state before and after actions
- Screenshots at each step
- Network request/response details
- Console output and timing

## Use Cases

- Debugging flaky or failing interactions
- Performance diagnosis via network timing
- Preserving proof artifacts for verification reports

## Notes

- Tracing adds runtime overhead
- Clean up old traces to reduce disk usage
