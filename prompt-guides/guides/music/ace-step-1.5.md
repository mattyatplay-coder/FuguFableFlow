---
id: ace-step-1.5
displayName: ACE-Step 1.5
aliases:
  - ace-step
  - ace step
  - ace-step 1.5
  - ace music
modality: music
tasks:
  - text-to-music
summary: Local open-source music generation guidance for ACE-Step 1.5 text-to-music, remix, repaint, layer, extract, and completion workflows.
---

# ACE-Step 1.5 Prompt Guide

## Best For

- Local, open-source music generation where the user wants ownership, offline use, and low-cost iteration.
- Human-centered workflows: generate, listen, adjust, cover, repaint, add layers, or complete accompaniment.
- Detailed prompts where the user can act as the planner instead of relying fully on the model's language-model planning stage.

## Prompt Shape

```text
Task: "[text to music, remix, repaint, add layer, extract, complete]."
Style: "[genre, subgenre, era, production family]."
Tempo and Key: "[BPM, key, meter if known]."
Vocal: "[singer type, delivery, harmony, language, lyric density]."
Instrumentation: "[instruments in priority order and performance style]."
Structure: "[intro, verse, chorus, bridge, outro, energy curve]."
Production: "[mix, room, saturation, stereo field, loudness, texture]."
Lyrics: "[lyrics or instrumental/no vocals]."
Constraints: "[what to keep, what to change, section range for repaint, layer target]."
```

## Key Rules

- ACE-Step has an optional planner and a diffusion executor. Use the planner for fast ideation; skip or constrain it when you already know the exact blueprint.
- Treat prompt writing as steering an instrument, not ordering a service. Iterate quickly and judge by listening.
- For Cover or Remix, describe what should change and what should stay: structure, melody contour, rhythm, vocal phrasing, instrumentation, mix, or mood.
- For Repaint, name the exact time range and the intended local fix.
- For Add Layer or Complete, describe the existing audio's role and the added part's frequency range, rhythm, and mix placement.
- For local memory pressure, prefer Turbo for speed and use base/SFT modes only when the workflow needs layer, extract, complete, or higher-control iteration.

## Strong Prompt Example

```text
Task: "text to music."
Style: "melancholic indie folk with subtle electronic ambience."
Tempo and Key: "76 BPM, A minor, 4/4."
Vocal: "soft alto vocal, intimate and close, restrained vibrato, clear English diction."
Instrumentation: "fingerpicked acoustic guitar first, warm upright bass, brushed percussion, faint tape-warped synth pad behind the chorus."
Structure: "short instrumental intro, two verses, lift into a memorable chorus, quiet bridge, final chorus with wider harmonies."
Production: "small room realism, dry vocal, gentle tape saturation, narrow verses opening slightly in the chorus."
Lyrics: "reflective lyrics about trying again after a long winter."
Constraints: "no glossy EDM drop, no trap drums, no oversized arena reverb."
```

## Source Notes

Full source exports are stored under `prompt-guides/sources/music/`.
