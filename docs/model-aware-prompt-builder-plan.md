# Model-Aware Prompt Builder Plan

Status: slices 1-4 implemented locally; vision and guide refresh still planned
Last updated: 2026-07-05
Target app: FuguFableFlow

## Goal

Add a Command Mode path that turns spoken rough intent into model-aware prompts for current image, video, speech, and music generation models while preserving FuguFableFlow's low-memory identity.

The key product distinction is:

- Target generation model: Seedance 2.0, LTX-2.3, Wan 2.7, GPT Image 2, Suno V5.5, etc.
- Brain model: the text/vision model used to rewrite the prompt, such as deterministic local templates, OpenRouter, Hugging Face, OpenAI, or local Ollama.

Example spoken command:

```text
Turn this into a strong image-to-video prompt for a cinematic product shot, for Seedance 2.
```

## Source Leaderboards Checked

- Artificial Analysis text-to-image leaderboard: GPT Image 2 leads; open-weights leader is Cosmos3-Super-Text2Image.
- Artificial Analysis image editing leaderboard: GPT Image 2 and GPT Image 1.5 lead; open-weights leader is HunyuanImage 3.0 Instruct.
- Artificial Analysis text-to-video leaderboard: Dreamina Seedance 2.0 leads with audio; HappyHorse leads without audio; LTX is the leading open-weights family.
- Artificial Analysis image-to-video leaderboard: Dreamina Seedance 2.0 leads; LTX-2.3 and Cosmos3 are key open-weights entries.
- Artificial Analysis speech-to-text leaderboard: Fun-Realtime-ASR-preview leads accuracy; Voxtral Small is the top open-weights ASR entry.
- Artificial Analysis text-to-speech leaderboard: Gemini 3.1 Flash TTS leads; Step Audio EditX is the top open-weights TTS entry.
- Artificial Analysis music leaderboards: Suno V5.5 leads both instrumental and vocals.
- Arena AI overview: useful cross-check for GPT Image 2, Seedance 2.0, HappyHorse, Veo, Sora, Wan, GPT-5.4, Gemma-4-31B, and other current frontier entries.
- Intelligence/Design Arena image page was checked, but the public page rendered only loading placeholders from the static fetch. Treat it as a source to re-check with browser automation later.

## Current Priority Model Families

### Image Generation And Editing

| Family | Type | Priority | Guide Status | Local Evidence |
|---|---|---:|---|---|
| GPT Image 2 / GPT Image 1.5 | proprietary | P0 | partial | `vibeboard_docs/prompt_guides/fal/skills/skills/fal-prompting/references/gpt-image-2.md` |
| Reve 2.0 | proprietary | P0 | missing | only incidental matches |
| MAI-Image-2.5 | proprietary | P0 | missing | no direct guide hit |
| Nano Banana 2 / Nano Banana Pro / Gemini image | proprietary | P0 | partial | `seedance-master-director/references/nano-banana-pro.md`, Gemini system notes |
| Qwen Image / Qwen Image Edit Plus | mixed/open-ish by route | P0 | strong | `vibeboard_docs/prompt_guides/Qwen/` |
| Flux / Flux.2 | mixed/open/proprietary by route | P0 | strong | `vibeboard_docs/prompt_guides/Flux/Flux Schema/` |
| HiDream-O1 Image | open/proprietary routes | P1 | missing | no direct guide hit |
| HunyuanImage 3.0 Instruct | open weights | P1 | missing | no direct guide hit |
| Z-Image | open weights | P1 | strong | `vibeboard_docs/prompt_guides/z-image/` |
| Krea 2 | proprietary | P2 | partial | `vibeboard_docs/prompt_guides/krea2/` |

### Video Generation

| Family | Type | Priority | Guide Status | Local Evidence |
|---|---|---:|---|---|
| Dreamina Seedance 2.0 | proprietary | P0 | strong | `vibeboard_docs/prompt_guides/seedance/` |
| LTX-2.3 / LTX-2 | open weights | P0 | strong | `vibeboard_docs/prompt_guides/ltx-2.3/` and `Vibeboard/vibeboard-development/prompt_guides/ltx-2.3/` |
| Wan 2.7 / Wan 2.6 / Wan 2.2 | mixed/open routes | P0 | needs refresh | `vibeboard_docs/prompt_guides/wan/`, but newer Wan 2.7 needs a focused guide |
| HappyHorse 1.0 / 1.1 | proprietary | P0 | missing | no operational guide hit |
| Kling 3.0 | proprietary | P0 | partial | scattered competitor/workflow mentions; no clean guide |
| Veo 3.1 | proprietary | P0 | partial | scattered Veo prompt generator/workflow notes; no clean guide |
| Sora 2 / Sora 2 Pro | proprietary | P1 | missing | only incidental competitor mentions |
| Grok Imagine Video | proprietary | P1 | missing | no clean guide |
| PixVerse V6 | proprietary | P1 | missing | no clean guide |
| Vidu Q3 Pro | proprietary | P1 | missing | no clean guide |
| Runway Gen-4 / Aleph video edit | proprietary | P1 | missing | no clean guide |
| Cosmos3-Super-Image2Video | open weights | P1 | missing | no direct guide hit |

### Speech, Audio, And Music

| Family | Type | Priority | Guide Status | Local Evidence |
|---|---|---:|---|---|
| Apple Speech | native OS | P0 | app integrated | FuguFableFlow uses Apple Speech for dictation |
| Fun-Realtime-ASR-preview | proprietary | P1 | missing | no guide hit |
| ElevenLabs Scribe v2 | proprietary | P1 | partial | catalog mentions only |
| MAI-Transcribe | proprietary | P1 | missing | no guide hit |
| Voxtral Small / Voxtral Mini Transcribe | open weights | P1 | missing | no guide hit |
| Parakeet TDT | open weights | P1 | partial | external dictation competitors mention it; no Fugu guide |
| Gemini 3.1 Flash TTS | proprietary | P1 | missing | no TTS guide |
| Sonic 3.5 / Cartesia | proprietary | P1 | missing | no TTS guide |
| Step Audio EditX | open weights | P1 | missing | no TTS guide |
| Suno V5.5 / V5 | proprietary | P0 | missing | only incidental planning mentions |
| Mureka V8 | proprietary | P1 | missing | no guide hit |
| Lyria 3 Pro | proprietary | P1 | partial | fal audio catalog mention only |
| MiniMax Music 2.5+ / Music 2.6 | proprietary | P1 | missing | no guide hit |
| ACE-Step / Stable Audio / Fish Audio | open/local/community | P2 | existing | `vibeboard_docs/prompt_guides/Audio & TTS/` |

## Existing Prompt Guide Assets Worth Reusing

- Seedance: `vibeboard_docs/prompt_guides/seedance/seedance-2-guide/SEEDANCE_2_GUIDE_EN.md`
- Seedance master director skill: `vibeboard_docs/prompt_guides/seedance/seedance-master-director/SKILL.md`
- LTX-2.3 schemas/workflows/optimization: `vibeboard_docs/prompt_guides/ltx-2.3/`
- Wan guides/workflows: `vibeboard_docs/prompt_guides/wan/`
- Flux schemas: `vibeboard_docs/prompt_guides/Flux/Flux Schema/`
- Qwen image/edit schemas: `vibeboard_docs/prompt_guides/Qwen/`
- z-image schemas: `vibeboard_docs/prompt_guides/z-image/`
- fal catalog and prompt skills: `vibeboard_docs/prompt_guides/fal/skills/skills/`
- Smart Prompt Builder audit: `vibeboard_docs/prompt_guides/general-prompt-engineering/_from-vibeboard-docs/audits/SMART_PROMPT_BUILDER_AUDIT.md`

## Missing Guide Backlog

P0 guide gaps:

1. Reve 2.0 image generation.
2. MAI-Image-2.5 image generation and editing.
3. Clean GPT Image 2 guide outside the fal skill tree.
4. Clean Nano Banana 2 / Nano Banana Pro guide.
5. HappyHorse 1.0 / 1.1 video.
6. Kling 3.0 video.
7. Veo 3.1 video.
8. Wan 2.7 refresh, distinct from Wan 2.2.
9. Suno V5.5 music prompt guide.

P1 guide gaps:

1. Sora 2 / Sora 2 Pro.
2. Grok Imagine Video.
3. PixVerse V6.
4. Vidu Q3 Pro.
5. Runway Gen-4 / Aleph video edit.
6. Cosmos3 image/video open-weights family.
7. HiDream-O1 and HunyuanImage.
8. Gemini 3.1 Flash TTS, Sonic 3.5, Step Audio EditX.
9. Voxtral/Parakeet STT guide for optional future dictation providers.

## Proposed Product Behavior

Command Mode gains a Prompt Builder mode.

Input sources:

- Spoken command.
- Selected text.
- Clipboard fallback.
- Last transcript fallback.

Parser extracts:

- Task: text-to-image, image editing, text-to-video, image-to-video, video edit, text-to-music, TTS, STT/transcription profile.
- Target generation model: Seedance 2.0, LTX-2.3, Wan 2.7, GPT Image 2, Suno V5.5, etc.
- Intent: cinematic product shot, fashion ad, character sheet, soundtrack cue, voiceover, etc.
- Output shape: prompt only, prompt plus negative prompt, prompt plus settings, storyboard, shot list, music brief, voice direction.

Example routing:

```json
{
  "spokenCommand": "Turn this into a strong image-to-video prompt for a cinematic product shot, for Seedance 2",
  "targetModel": "seedance-2.0",
  "task": "image-to-video",
  "guidePaths": ["prompt_guides/seedance"],
  "brainProvider": "local-template-or-configured-provider"
}
```

## Low-Memory Architecture

Hard rules:

1. FuguFableFlow must not bundle model weights.
2. FuguFableFlow must not start Ollama, Whisper, Parakeet, or any local model daemon.
3. FuguFableFlow must not load the full prompt-guide corpus at startup.
4. FuguFableFlow must not index image/video/audio binaries.
5. Hosted provider calls are opt-in and provider-specific.

Components:

1. `PromptGuideManifestService`
   - Loads a small JSON manifest only.
   - Contains model aliases, modalities, guide paths, source metadata, confidence, and last verified date.

2. `PromptGuideSearchService`
   - On demand only.
   - Searches allowed `.md`, `.txt`, and small `.json` files under selected guide roots.
   - Excludes media and large workflow blobs by default.
   - Caps read size per file and total snippets per command.

3. `PromptBuilderCommandParser`
   - Local deterministic parser first.
   - Extracts "for <model>" and task phrases without a model call.

4. `PromptBuilderService`
   - Builds a compact context packet.
   - Uses local templates if provider is Off.
   - Uses configured provider only if enabled.

5. `PromptBuilderResult`
   - Strict structured output, similar to the older Vibeboard Smart Prompt Builder audit.
   - Contains prompt, optional negative prompt, settings, warnings, model fit, and evidence.

Memory budget:

| Area | Target |
|---|---:|
| Startup manifest | under 250 KB |
| In-memory snippet cache | under 2 MB |
| Per-command guide context | 8-16 KB text cap |
| Transcript retention | no new history |
| Binary media indexing | none |
| Local model memory | outside app only, user-started |

## Build Slices

### Slice 1: Manifest And Parser

- Add model-family manifest schema.
- Add aliases: "seedance", "seedance two", "ltx", "ltx 2.3", "wan", "wan two point seven", "gpt image", "suno", etc.
- Add parser tests for spoken "for <model>" commands.
- Implemented.

### Slice 2: Local Guide Search

- Add Prompt Guide folder setting.
- Build on-demand text search over selected guide roots.
- Return top guide excerpts with source paths.
- Exclude binary and oversized files.
- Implemented.

### Slice 3: Local Template Prompt Builder

- Build model-aware prompt templates for P0 models.
- Work with provider Off.
- Return structured prompt output.
- Paste into current app through existing text insertion path.
- Implemented.

### Slice 4: Provider-Assisted Rewrite

- Reuse existing Command Mode providers.
- Send only selected snippets, selected text, and spoken instruction.
- Add warning when provider is hosted.
- Add source evidence in output.
- Implemented with existing Command Mode provider settings.

### Slice 5: Vision-Optional Prompt Builder

- If user supplies a screenshot/image, optionally call a configured vision model.
- Do not auto-upload screenshots.
- Do not keep image history.
- Show exact provider and privacy warning.

### Slice 6: Guide Refresh Workflow

- Add a small guide manifest updater command or script.
- Validate missing paths, stale dates, and duplicate aliases.
- Do not fetch or update guides automatically inside the app.

## Acceptance Proof Table

| Requirement | Proof |
|---|---|
| Parses target model from spoken command | Unit tests for aliases and "for model" grammar |
| Works with provider Off | Local template test generates model-aware prompt |
| Does not load corpus at startup | Memory/initialization test proves only manifest loaded |
| Does not index media files | Fixture ladder with `.mp4`, `.png`, huge `.json`, `.md` |
| Hosted calls are opt-in | Settings and service tests for provider Off |
| Keeps memory pressure low | RSS check before/after 20 prompt-builder commands |
| Handles stale/missing guide | Warning result, no crash, generic fallback |
| Preserves existing dictation | Existing `swift build` plus manual dictation smoke test |

## Security And Privacy Notes

- Prompt guide contents are local data and should be treated as untrusted input.
- Retrieved guide snippets must be delimited as context, not instructions.
- Hosted provider requests must include only selected snippets, user-selected text, and the spoken command.
- No automatic upload of the full guide library.
- No transcript or prompt history unless a future setting explicitly enables it.
- API keys remain in Keychain through existing Command Mode storage.

## Recommended First Implementation Slice

Start with Slice 1 and Slice 2 only:

1. Manifest schema.
2. Model alias resolver.
3. Spoken command parser.
4. Local guide search with strict caps.
5. A debug-only result preview in Settings or logs.

Do not start with model calls. The value is routing and guide retrieval. Provider calls can be added after the local path proves useful and memory stays small.
