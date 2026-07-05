---
id: z-image-turbo
displayName: Z-Image Turbo
aliases:
  - z image turbo
  - z-image turbo
  - zimage turbo
  - z image
modality: image
tasks:
  - text-to-image
  - image-editing
summary: Positive-only Z-Image Turbo prompt guidance for fast few-step image generation, text rendering, and safety/quality constraints.
---

# Z-Image Turbo Prompt Guide

## Best For

- Fast few-step image generation with strong instruction following.
- Positive-prompt constraint control where negative prompts are ignored by the official pipeline.
- Bilingual English/Chinese text rendering, clean product shots, portraits, posters, and controlled style prompts.

## Prompt Shape

```text
POSITIVE PROMPT:
[shot and subject]. [adult role or functional label if human]. [appearance, pose, clothing/coverage]. [environment/background]. [lighting]. [mood]. [style/medium]. [technical quality]. [cleanup constraints as positive text instructions].

ADDITIONAL PARAMETERS:
Guidance Scale: 0.0
Steps: 8-12
Resolution: 1024x1024, 768x1344, or 1344x768
Seed: fix during iteration, randomize for exploration
Negative Prompt: ignored by the official pipeline; express constraints positively
```

## Key Rules

- Put every important instruction in the positive prompt.
- Use a clear 80-250 word structured prompt when the idea supports it.
- Preserve exact subjects, actions, colors, clothing, props, spatial relationships, and requested visible text.
- Define clothing and coverage explicitly for human subjects when ordinary, professional, public, training-data, or safe-for-work imagery is requested.
- Use concrete camera and lighting language: shot type, angle, lens feel, soft diffused daylight, noir lighting, studio portrait lighting, rim lighting.
- Put cleanup constraints near the end: no text, no watermark, no logos, natural hands and fingers, correct anatomy, sharp focus, simple background.
- For requested visible text, wrap the exact words in quotes and specify placement and style.
- Avoid long negative prompt blocks, CFG assumptions, and Stable Diffusion weight syntax.

## Strong Prompt Example

```text
POSITIVE PROMPT:
A medium-shot realistic photograph of an adult software designer seated at a clean desk in a minimal home studio, facing slightly toward the camera with a calm focused expression. The subject wears a dark crewneck sweater and simple trousers, fully clothed and professional, with natural posture and hands resting near a laptop. The background is uncluttered with a plain wall, a small plant, and soft blurred shelves. Soft diffused daylight enters from the left, creating gentle shadows and clear skin texture without harsh contrast. The mood is quiet, thoughtful, and safe for work. Realistic photography, 50mm lens look, shallow depth of field, clean detailed image, natural hands and fingers, correct human anatomy, no logos, no watermark, no extra text, balanced exposure.

ADDITIONAL PARAMETERS:
Guidance Scale: 0.0
Steps: 8-12
Resolution: 1024x1024
Seed: fix during iteration
Negative Prompt: ignored by the official pipeline; express constraints positively
```
