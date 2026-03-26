# Video Recording

Capture browser automation sessions as WebM files for demos or bug evidence.

## Basic Recording

```bash
playwright-cli video-start
playwright-cli open https://example.com
playwright-cli snapshot
playwright-cli click e1
playwright-cli fill e2 "test input"
playwright-cli video-stop demo.webm
```

## Best Practices

- Use descriptive filenames with context and date
- Keep videos short and task-focused
- Use tracing (not only video) when deep debugging is needed

## Video vs Trace

- Video: best for visual playback and demos
- Trace: best for root-cause analysis (DOM/network/console)
