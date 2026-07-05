---
id: flux-2-klein
displayName: Flux.2 Klein
aliases:
  - flux 2 klein
  - flux.2 klein
  - flux2 klein
  - flux klein
modality: image
tasks:
  - text-to-image
  - image-editing
summary: Fast flowing-prose prompt guidance for FLUX.2 Klein 4B and 9B variants, including reference-image roles and low-step settings.
---

# Flux.2 Klein Prompt Guide

## Best For

- Fast sub-second or low-step image generation on consumer hardware.
- Flowing prose prompts for text-to-image and image editing with up to four references.
- Neon, glow, reflections, volumetric lighting, surreal scenes, and material interactions.

## Prompt Shape

```text
POSITIVE PROMPT:
[flowing prose: subject first, environment, lighting/color interactions, sensory material details, atmosphere, composition, quality]

POSITIVE AVOIDANCE PHRASING:
[concise positive guidance for anatomy, focus, details, exposure, glow, reflections, and clean composition]

ADDITIONAL PARAMETERS:
Steps: 4-8 distilled or 20-50 base
Guidance Scale: 1.0-3.5
Aspect Ratio: [3:4, 9:16, or 16:9]
Variant: [4B for speed or 9B for higher detail]
```

## Key Rules

- Write connected prose paragraphs, not token lists.
- Lead with the main subject and exact view.
- Preserve the user's stated characters, wardrobe, props, actions, colors, and spatial relationships.
- For reference images, assign roles clearly: composition, subject, wardrobe, palette, material, lighting, or mood.
- Describe lighting source, direction, color temperature, glow, bloom, reflections, and material interaction.
- Use positive phrasing instead of native negative prompts.
- Include at least one useful texture, one reflective quality, and an atmospheric feel when relevant.

## Strong Prompt Example

```text
POSITIVE PROMPT:
A young woman with long slightly wavy brown hair sits at the edge of a low bed in a cozy nighttime gamer bedroom, holding a sleek black controller in both hands while leaning forward with a confident playful grin. The green bedding, wood-paneled wall, circular amber wall light, string lights, and softly blurred dual-monitor desk create a warm layered room behind her. The circular light glows at roughly 2700K, spilling yellow-orange bloom across the wood grain, catching subtle reflections on the controller plastic, and rim-lighting strands of hair around her face. The shirt fabric reads as soft dark olive cotton with a clear retro sunset and pine graphic, paired with dark loose cargo pants. The atmosphere feels intimate, competitive, and cinematic, composed as a steady eye-level medium shot with shallow depth of field, sharp facial focus, high contrast, vibrant warm glow, ultra-detailed realistic texture, flawless composition.

POSITIVE AVOIDANCE PHRASING:
accurate hands and controller grip, natural anatomy, crisp facial detail, balanced warm exposure, clean image without stray text or watermark, coherent bedroom layout.

ADDITIONAL PARAMETERS:
Steps: 4-8 distilled
Guidance Scale: 2.0
Aspect Ratio: 4:3
Variant: 9B for higher detail
```
