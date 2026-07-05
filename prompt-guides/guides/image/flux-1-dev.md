---
id: flux-1-dev
displayName: Flux.1 Dev
aliases:
  - flux 1 dev
  - flux.1 dev
  - flux dev
  - flux one dev
modality: image
tasks:
  - text-to-image
  - image-editing
summary: Natural-language Flux.1 Dev prompt guidance for cinematic image generation, lighting, materials, color, and positive constraint phrasing.
---

# Flux.1 Dev Prompt Guide

## Best For

- Rich image prompts written as natural cinematic prose.
- Scenes that need strong lighting, reflections, material behavior, atmosphere, or surreal styling.
- Positive constraint phrasing instead of native negative prompts.

## Prompt Shape

```text
POSITIVE PROMPT:
[main subject and action]. [environment and spatial layout]. [lighting source, direction, color, glow, reflections]. [atmosphere and mood]. [composition and framing]. [material and texture details]. masterpiece, best quality, ultra-detailed, sharp focus, vibrant colors, high contrast, cinematic lighting, flawless composition.

POSITIVE AVOIDANCE PHRASING:
[clean anatomy, sharp focus, clean edges, balanced exposure, no unwanted text or watermarks phrased as desired outcomes]

ADDITIONAL PARAMETERS:
Guidance Scale: 3.5
Steps: 20-50
Aspect Ratio: [3:4, 9:16, or 16:9]
Style Strength: [High artistic or Balanced]
```

## Key Rules

- Lead with the main subject. Word order matters.
- Use vivid present-tense prose, not rigid token lists.
- Preserve the user's characters, wardrobe, props, actions, colors, and spatial relationships.
- Avoid native negative prompts. Reinforce desired outcomes positively.
- Describe lighting quality, color temperature, glow, reflections, bloom, rim light, and material interaction.
- Use precise spatial language: foreground, background, centered, symmetrical, leading lines, depth.
- Add useful material details: fabric texture, individual hair strands, wet gloss, worn metal, surface reflections.

## Strong Prompt Example

```text
POSITIVE PROMPT:
A young woman sits on the edge of a low bed in a cozy wood-paneled bedroom at night, gripping a black game controller with both hands while leaning forward with a triumphant playful smile. The room is arranged with green bedding in the foreground and a softly blurred dual-monitor gaming desk in the background. A circular amber wall light above the bed casts warm neon rim light across her face, hair, controller, and shirt graphic, with soft bloom on the wood panels and gentle reflections on the controller's glossy plastic. The mood is intimate, cinematic, and focused, framed as an eye-level medium shot with shallow depth of field and realistic skin texture, fabric weave, natural hair detail, atmospheric shadows, masterpiece, best quality, ultra-detailed, sharp focus, vibrant warm color, high contrast, cinematic lighting, flawless composition.

POSITIVE AVOIDANCE PHRASING:
clean natural anatomy, accurate hands on the controller, sharp facial focus, balanced exposure, clean image without unwanted text or watermarks, coherent room geometry.

ADDITIONAL PARAMETERS:
Guidance Scale: 3.5
Steps: 20-50
Aspect Ratio: 4:3
Style Strength: Balanced
```
