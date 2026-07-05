---
id: suno-v5.5
displayName: Suno V5.5
aliases:
  - suno
  - suno 5.5
  - suno v5.5
  - suno music
modality: music
tasks:
  - text-to-music
summary: Structured Suno music prompt guidance for genre, vocals, instrumentation, production, lyrics, and quality controls.
---

# Suno V5.5 Prompt Guide

## Best For

- Complete songs from structured style, vocal, instrumentation, production, mood, and lyric direction.
- Personalized generations using selected Voices, Custom Models, or My Taste.
- Professional song briefs where genre gravity, lyric bleed, and unwanted generic production need active control.

## Prompt Shape

Use periods instead of comma-heavy tag lists. Put the most important musical identity first.

```text
Genre: "[specific genre and subgenre with useful influences]."
Vocal: "[voice type, delivery, harmony style, intensity]."
Instrumentation: "[priority instruments and how they are played]."
Production: "[recording/mix character, space, stereo width, saturation, fidelity]."
Mood: "[emotional intent and energy arc]."
Structure: "[intro, verse, chorus, bridge, outro direction if needed]."
Constraints: "[no trap, no pop gloss, no generic saw synth, no lyric bleed, no unwanted instruments]."
```

## Key Rules

- Suno behaves like a style-association model, not a literal instruction follower. Popular tags pull generations toward their common neighbors.
- "Pop" is a gravity well. If a track should avoid pop structure or polish, say that directly and reinforce the alternative.
- Use structured metadata-like prompts. Dense technical style descriptions are less likely to be sung as lyrics.
- Always put something in the lyrics box when using custom lyrics. Empty lyrics can cause prompt text to bleed into the song.
- Use exclusions as concrete style controls: `no trap`, `no pop gloss`, `no generic saw synth`, `no EDM drop`, `no heavy drums`.
- For realism, stack physical recording detail: room sound, mic distance, performance dynamics, analog character, live instrument behavior.
- For electronic music, do not ask synths to sound "real." Specify oscillator type, filter motion, bass behavior, transient shape, stereo width, and high-end texture.

## Strong Prompt Example

```text
Genre: "outlaw country with 70s singer-songwriter phrasing and dry Americana grit."
Vocal: "baritone male vocal with slight rasp, close-mic presence, restrained vibrato, human breath and imperfect phrasing."
Instrumentation: "single dreadnought acoustic guitar with fingerpicking, upright bass supporting the groove, brushed snare, sparse pedal steel."
Production: "small room acoustics, tape warmth, dry vocal upfront, narrow stereo image, natural dynamics, no glossy pop polish."
Mood: "late-night regret, steady and intimate, emotional without melodrama."
Constraints: "no trap, no EDM drums, no pop chorus gloss, no lyric bleed."
```

## Lyric Box Divider

Use a divider when lyric bleed is a risk:

```text
[LYRICS BEGIN]

[Verse 1]
...
```

## Source Notes

Full source exports are stored under `prompt-guides/sources/music/`.
