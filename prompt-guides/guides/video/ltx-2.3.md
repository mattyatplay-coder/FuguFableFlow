---
id: ltx-2.3
displayName: LTX-2.3
aliases:
  - ltx
  - ltx 2.3
  - ltx two point three
  - ltx video
modality: video
tasks:
  - text-to-video
  - image-to-video
summary: Cinematic Prompt Relay guidance for LTX-2.3 video prompts with timecoded scenes, camera motion, sound, and temporal consistency.
---

# LTX-2.3 Prompt Guide

## Best For

- Detailed image-to-video or text-to-video prompts with strong temporal control.
- Cinematic scenes that need camera movement, subject motion, sound, and continuity.
- Prompt Relay style output with global persistent traits and timecoded scene changes.

## Prompt Shape

```text
POSITIVE PROMPT:
Global Prompt:
[persistent style, subject identity, reference-image adherence, lighting, lens, quality, sound bed]

Scene 1 [00:00-00:05]:
[initial static state, spatial blocking, first action, camera, sound]

Scene 2 [00:05-00:10]:
[only what changes: motion, expression, camera, physics, sound, dialogue]

NEGATIVE PROMPT:
[temporal, anatomy, watermark, flicker, jitter, and artifact controls]

FPS:
24

LORA TRIGGERS APPLIED:
[exact triggers or none]
```

## Key Rules

- Use present tense only.
- Preserve exact user keywords, clothing, props, actions, names, and LoRA triggers.
- If a first frame or reference image is supplied, anchor identity, wardrobe, pose, lighting, props, and environment to it.
- Always include a specific lens and aperture, natural motion blur, and 24 fps with a 1/48 shutter equivalent.
- Sound is mandatory. Describe physical sound events and their timing.
- Use precise spatial blocking: foreground, background, left, right, distance, facing direction.
- Avoid high-frequency clothing or background patterns unless required.
- Do not use weight syntax such as `(word:1.2)` or `[word]`.
- Do not write fade-outs, final summaries, or poetic endings.

## Strong Prompt Example

```text
POSITIVE PROMPT:
Global Prompt:
A cozy cinematic gamer-bedroom scene at night, faithful to the reference image for subject, wardrobe, controller, bed, wall light, and desk layout. Shot on an 85mm f/1.8 lens with shallow depth of field, natural motion blur, 24 fps with a 1/48 shutter equivalent, warm amber neon ring light casting highlights across the subject's face and hair, soft controller button clicks and a low game-audio bed in the room.

Scene 1 [00:00-00:05]:
The woman sits on the edge of the low green bed in the foreground, facing camera at eye level, both hands gripping the black controller. The gaming desk stays softly blurred in the back right. Her thumbs tap quickly as her jaw tightens and the neon ring hums faintly.

Scene 2 [00:05-00:10]:
The camera makes a slow controlled push-in as she breaks into a triumphant laugh, leans forward, and gives a smug playful grin toward an unseen opponent. Controller clicks become faster for a beat, then settle under the warm room tone.

NEGATIVE PROMPT:
watermark, text, signature, duplicate, static, no motion, frozen, bad anatomy, deformed hands, extra limbs, micro jitter, flickering, strobing, aliasing, high frequency patterns, motion artifacts, temporal inconsistency, frame stuttering

FPS:
24

LORA TRIGGERS APPLIED:
none
```
