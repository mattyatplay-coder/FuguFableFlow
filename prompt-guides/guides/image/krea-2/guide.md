---
id: krea-2
displayName: Krea 2
aliases:
  - krea
  - krea 2
  - krea two
  - krea turbo
  - krea 2 turbo
modality: image
tasks:
  - text-to-image
  - image-editing
summary: Use for Krea 2 image prompts with natural language, strong visual composition, faithful prompt expansion, and practical text rendering guidance.
---

# Krea 2 Prompt Builder Notes

For FuguFableFlow, use Krea 2 as a natural-language image prompt target. Preserve the user's subject, wardrobe, pose, prop, environment, graphic design, color palette, lighting, and spatial relationships. If the user provides a reference sheet and a target scene, use the target scene as the final image goal and use the reference sheet only for fidelity details. Do not turn a target scene into a reference sheet unless the user explicitly asks for a reference sheet, turnaround sheet, or character sheet.

Krea 2 generally responds well to one cohesive paragraph with grounded visual details. Avoid unrelated example content. Put requested visible text in quotes.

## Golden Reference-Sheet-To-Scene Pattern

When converting a reference sheet into a final Krea 2 scene, write one direct natural-language paragraph. Put the target scene first, then lock the important fidelity details: subject, hair, complexion, wardrobe, printed graphics, props, environment, lighting, camera, and forbidden visible text. If the reference sheet and target description conflict, the target description wins.

```text
create a cozy cinematic nighttime medium shot inside a dimly lit bedroom with rich wood-paneled accents, a neatly made low bed with green bedding, string lights on the wall, and a softly blurred gaming desk setup with dual monitors in the background. A young woman with long, slightly wavy brown hair parted down the middle and a warm complexion sits on the edge of the low bed, wearing the dark olive green short-sleeved t-shirt with the retro graphic of a bright orange sunset behind dark pine tree silhouettes and green rolling hills, paired with dark baggy cargo pants with large side pockets. She grips a sleek modern black video game controller tightly in both hands, thumbs actively pressing the thumbsticks, captured at the triumphant moment after intense focus: her face lit by the striking circular wall light above the bed, a warm yellow-orange neon ring casting vivid highlights across her cheeks and hair, her head tipped back slightly as she breaks into a joyful energetic laugh, then leans forward with a smug playful smile as if saying to an off-screen opponent, "Oh, you thought you had me cornered, didn't you?" and "Not today!" Keep the composition steady and static, camera at eye level, shallow depth of field, expressive face in sharp focus, atmospheric shadows, warm amber neon glow, cinematic contrast, realistic texture, natural skin detail, moody cozy gamer-bedroom ambience, no visible subtitles or speech bubbles.
```

You are an expert prompt engineer for text-to-image models. Your task is to expand the user's prompt into a highly effective image-generation prompt.

Think step by step about the request before writing the answer:
- What is the subject and mood?
- What visual styles, mediums, and lighting options would fit? Consider two or three alternatives and pick the one that best serves the caption.
- What composition, framing, and grounded details will help the text-to-image model?

Then output a single expanded prompt paragraph.

Follow these rules strictly:
1. **Faithfulness First:** Preserve all original subjects, actions, colors, and spatial relationships. Do not add new objects, props, characters, or animals unless the user clearly implies them.
2. **Practical T2I Structure:** Write a prompt that a text-to-image model can parse cleanly. Group subjects with their own attributes and actions. Use grounded phrasing for poses, interactions, and spatial layout.
3. **Style Planning Stays Internal:** Use your internal reasoning to choose style, medium, framing, and lighting. Do not emit planning tags or wrappers in the visible answer body.
4. **Text Rendering:** If the user requests visible text, quotes, labels, or typography, specify the exact text clearly and wrap requested words in quotes.
5. **Avoid Over-Specification:** Do not invent highly specific clothing, colors, materials, or scene details unless the input supports them.
6. **Structure:** Write one cohesive paragraph after the thinking block. No bullets, JSON, or markdown.
7. **Respect Existing Detail:** If the user's prompt is already detailed, lightly polish and finalize rather than heavily expanding — preserve their phrasing and direction.
8. **Respect the Human Form:** Treat depictions of people with dignity. Assume clothing covers genitals and intimate anatomy.
9. **Preserve User Medium:** When the user explicitly requests a medium (e.g. "photo of", "photograph of", "illustration of", "painting of", "sketch of", "3D render of"), honor it. Do not pivot to a different medium to avoid difficulty — match the user's stated intent.


# Prompting guidelines

We recommend users to use natural language prompts to generate images.
The turbo model can generate up to 2k resolution images. Long detailed prompts yield best results, but the model is capable of generating high quality images with minimal prompt engineering. For text rendering, we recommend putting quotes around the words to be rendered.
The expansion guidance above can be used as the system prompt for an LLM before generating the final Krea 2 prompt.

## Examples

All examples are generated at 2k resolution with the turbo model.

`immense rocket launch exhaust as seen from extremely close up`

<img src="assets/takeoff.png" alt="takeoff"/>

<br/>

`3D rendered matte black designer toy figure, stylized round anthropomorphic shape, backward black baseball cap, oversized gold-rimmed aviator sunglasses, white traditional line-art tattoos of tiger and bird on torso, black studded belt with gold buckle, smooth vinyl texture, studio lighting, solid vibrant blue background, high contrast minimal composition`

<img src="assets/3d.png" alt="3d"/>

<br/>

`vintage analog collage, central irregularly shaped snowy mountain range with a section featuring distinct wavy edges, structured within a 12x16 grid of square tiles, composition fragments the subject by alternating tiles with solid azure blue background squares, thin white grid lines, grainy paper texture, retro aesthetic of mid-century print, vibrant cyan and warm neutral tones, experimental layout, tactile quality, high-contrast graphic composition`

<img src="assets/blocks.png" alt="blocks"/>

<br/>

`close-up anime portrait of a young woman, large amber-brown eyes with intricate sparkling reflections, index finger delicately touching a subtle smile, messy dark blue hair with loose strands crossing her face, white and navy school uniform, bright high-key lighting, luminous shadows with cool blue undertones, detailed digital painting, dynamic tilted framing, shallow depth of field on hand`

<img src="assets/anime.png" alt="anime"/>

<br/>

`A minimalist flat-color illustration of a person wading through expansive shallow ocean waves beneath a pale peach sky. The dark-skinned figure, wearing an orange swim cap, light blue top, and bright green shorts, steps carefully through knee-deep water. The ocean is rendered in muted mint green with delicate, thin black linework detailing the continuous ripples and gentle whitecaps. Soft pinkish-peach reflections echo the sky on the water's surface. A dark, jagged rock rests in the lower left foreground near a pale grey shoreline. The horizon features a solid purplish-blue landmass and a stylized, layered yellow and blue cloud. The high-angle wide perspective emphasizes the vast negative space of the water, utilizing a clean ligne claire drawing aesthetic with a subtle paper texture.`

<img src="assets/beach.png" alt="beach"/>

<br/>

`A tiny figure and a small white dog sit side-by-side in the deep green shadow of a massive tree on a sloping grassy hill. The enormous tree canopy dominates the upper composition, textured with thousands of stippled, light blue and yellow dabs representing leaves. A sharp diagonal line divides the vibrant, sunlit yellow-green grass in the foreground from the dark shade sheltering the pair. The stylized, painterly landscape features flattened perspective, visible brushstrokes, and intense color contrast.`

<img src="assets/dog.png" alt="dog"/>

<br/>

`A close-up portrait of a young East Asian woman with straight black hair, loose strands sweeping across her fair skin, and an intense gaze. She wears a light grey collared shirt with a black tie. A vibrant bouquet of pink and orange lilies with lush green leaves sits in the blurred right foreground. The background is a solid, striking crimson red. Soft, directional studio lighting highlights her facial features, creating a high-contrast composition with a shallow depth of field.`

<img src="assets/flowers.png" alt="flowers"/>

<br/>

`A tiny, russet-brown harvest mouse clings to a slender diagonal branch amid vibrant green lobed leaves and small round buds. The mouse has soft textured fur, glossy black eyes, a pink nose, fine whiskers, and delicate pink paws firmly gripping the wood. In this macro photograph, an extremely shallow depth of field sharply focuses on the animal's face. The deep green background dissolves into a smooth, creamy bokeh, illuminated by soft, diffused natural lighting that highlights the intricate details of the fur and foliage.`

<img src="assets/mouse.png" alt="mouse"/>

<br/>

`A dynamic digital painting of a joyful girl in a sailor uniform stretching her arms high against a solid vibrant blue background. She has short dark windblown hair, amber eyes, and a bright smile. She wears a white shirt, striped blue collar, flowing red neckerchief, and a billowing blue pleated skirt. Expressive thick brushstrokes and bold shading emphasize energetic motion.`

<img src="assets/sailor.png" alt="sailor"/>

<br/>

`stylized digital painting of a dark convertible on a winding coastal cliff road, high-angle perspective, blocky painterly brushstrokes, golden hour sunlight hitting rocky orange terrain and green vegetation, flock of white abstract birds flying in foreground, blinding bright sun reflection on vast ocean, vibrant warm color palette, sharp graphic shadows`

<img src="assets/ride.png" alt="ride"/>

<br/>

`An extreme low-angle close-up captures a colossal, weathered stone and bronze guardian towering in a dark, cavernous ruin. The foreground is dominated by a massive circular shield, deeply engraved with intricate spiral motifs, geometric borders, and a central star emblem. To the right, a massive gauntlet grips a textured staff. Cinematic shafts of light pierce the dusty gloom, highlighting the rough, aged textures of the ancient armor while the background fades into deep shadows through a shallow depth of field.`

<img src="assets/statue.png" alt="statue"/>

<br/>

`A stylized jungle illustration densely packed with oversized flora and surreal characters, rendered with smooth geometric shapes and granular stippled shading. Two pale figures with flowing, star-speckled black hair navigate the lush environment in blue garments. On the left, a figure grasps a vine as a white, long-beaked bird perches on their outstretched hand. On the right, the second figure reclines beside a sleek, pinkish-orange fox. The dense surroundings feature sweeping green stalks and colossal blooms in brilliant golden yellow, coral pink, and deep red. A second white bird emerges from the lower foliage. The vibrant composition forms a seamless tapestry, utilizing rich colors and volumetric grain to create a dreamlike, textured depth.`

<img src="assets/fox.png" alt="fox"/>

<br/>

`A surreal retro-futuristic space scene features liquid chrome forming an abstract face merging with a glowing planetary horizon. The foreground is dominated by swirling, highly reflective metallic fluid that distorts into a stylized, melting facial profile with deep shadows and bright silver highlights. This undulating chrome form rests against the curved, atmospheric edge of a massive planet bathed in a soft electric blue and purple glow. Above the primary planet, a smaller eclipsed celestial sphere sits in the upper center, crowned by a sharp, cross-shaped starburst flare. Two additional radiant flares burst from the left and right edges of the horizon. Set against a deep black starfield, the artwork employs a vintage 1980s airbrush aesthetic with smooth gradients, ethereal lighting, and high-contrast metallic rendering.`

<img src="assets/future.png" alt="future"/>

<br/>

`An extreme close-up portrait featuring pale, freckled skin and a single blue eye wrapped in reflective metallic gold ribbons. Thin gold strips crisscross diagonally over the cheek and forehead, casting sharp, hard shadows onto the face. Strands of copper hair frame the top edge while the left ear softly blurs out of focus. Harsh, direct lighting highlights intricate skin pores and bright golden reflections, isolating the brightly lit features against a pitch-black background in a bold, high-contrast macro editorial style.`

<img src="assets/goldface.png" alt="goldface"/>

<br/>

`Stylized digital painting of a menacing jester figure rendered with bold, expressive brushstrokes and a vibrant, almost psychedelic color palette against a pitch-black background. Dynamic low-angle perspective forces a dramatic, imposing composition as the character leans forward, one leg raised high. The jester wears a classic multi-pointed hat with bells, a ruffled collar, puffed sleeves, harlequin-patterned shorts in muted gold and dark brown, and striped tights in alternating shades of purple, blue, and chartreuse. A heavily textured, flowing cape billows outward to the left, decorated with abstract, fluid patterns of saturated purples, greens, and iridescent hues resembling oil slicks or marbled paper. The figure's face is completely obscured, appearing as a smooth, faceless, pale mauve mask with a single, glowing bright white point of light in the center. In its right hand, clad in a grey-blue gauntlet, the jester grips a massive, ornate sword with a wide, glowing, ethereal white blade, its crossguard intricately sculpted. Lighting is dramatic and theatrical, casting strong shadows and highlighting the painterly texture, giving the artwork a dark fantasy, surreal aesthetic reminiscent of concept art.`

<img src="assets/jester.png" alt="jester"/>

<br/>

`high-fashion editorial portrait of a young East Asian woman, short choppy platinum blonde bob with heavy bangs, looking over her bare shoulder to the right, lips playfully pursed, wearing a structured black top with an architectural protruding bust detail and thin straps, delicate gold hoop earrings, arm bent with hand resting on hip, warm skin tones, solid striking crimson red background, soft directional studio lighting, cinematic color palette, medium close-up shot`

<img src="assets/red.png" alt="red"/>

<br/>

`A surreal black-and-white ink illustration of three interlocking, heavily wrinkled elderly faces merging into a landscape. The top face covers one eye, crowned by dense leaves, a live bird, and a skeletal bird. It flows into a profile face and a third face featuring a solid black eye and a hand on its cheek. The bottom neck plunges into a cross-section of earth, morphing into swirling subterranean roots, buried bones, and abstract organic forms. Above ground, weathered wooden cabins and tall grass flank the facial monolith. Meticulous stippling and cross-hatching define the high-contrast, intricate vertical composition.`

<img src="assets/tree.png" alt="tree"/>

<br/>

`1990s vintage anime style cel animation, densely packed crowd of teenagers in summer uniforms, central boy with short black hair raising a clenched right fist, squinting one eye with a determined expression, wearing a white short-sleeve shirt and solid green necktie, surrounding students looking in various directions, girls in white sailor blouses with green striped collars and neckerchiefs, light blue skirts and trousers, tightly framed medium shot, flat shading, soft muted retro.`

<img src="assets/cel.png" alt="cel"/>

<br/>

`young woman looking over her right shoulder, anime-style illustration, messy black hair blowing dynamically in the wind, striking green eyes, subtle neutral expression, oversized white button-down collared shirt with soft blue shadows, vibrant deep blue sky background, bright fluffy white cumulus clouds, silhouetted utility poles with power lines, low angle portrait, cinematic sunlight, crisp cel-shaded aesthetic`

<img src="assets/wind.png" alt="wind"/>

<br/>

`extreme close-up of a woman's face partially obscured by tousled dark brown hair, soft parted lips, smooth skin on lower cheek and jawline, stray hair strands falling loosely across the nose, deep moody shadows enveloping the left frame, cinematic warm lighting, delicate highlights on the mouth, muted earthy color palette, sepia-toned warmth, intimate portrait photography, macro lens, shallow depth of field, distinct film grain texture, vintage atmospheric aesthetic`

<img src="assets/face.png" alt="face"/>
