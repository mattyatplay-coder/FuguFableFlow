# FuguFableFlow Prompt Guides

This folder is the low-effort authoring area for public Prompt Builder guides.

Drop Markdown guides into `guides/`, keep the tiny front matter block at the top,
then run:

```bash
./script/publish_prompt_guides.sh MikoMurra/FuguFableFlow-Prompt-Guides
```

That script regenerates `manifest.json` and uploads this folder to a Hugging Face
Dataset repo. It excludes `sources/**` by default, so the public bucket contains
the compact app-readable guides instead of the full research exports.

## One-Time Setup

Install and log in to the Hugging Face CLI:

```bash
curl -LsSf https://hf.co/cli/install.sh | bash
hf auth login
```

Create or use the public Dataset repo on Hugging Face:

```text
MikoMurra/FuguFableFlow-Prompt-Guides
```

After that, publishing is just:

```bash
./script/publish_prompt_guides.sh MikoMurra/FuguFableFlow-Prompt-Guides
```

If the Dataset repo accidentally contains a full app checkout, run the cleanup
publish once:

```bash
./script/publish_prompt_guides.sh --clean MikoMurra/FuguFableFlow-Prompt-Guides
```

Clean mode deletes known app-repo folders from the remote Dataset and republishes
only the prompt-guide payload.

Or set it once in your shell:

```bash
export HF_PROMPT_GUIDES_REPO="MikoMurra/FuguFableFlow-Prompt-Guides"
./script/publish_prompt_guides.sh
```

## Add A Guide

1. Copy `templates/guide-template.md`.
2. Put it under `guides/<modality>/<model-name>.md`.
3. Fill in the front matter.
4. Write the guide in normal Markdown.
5. Run the publish script.

Example:

```text
guides/video/seedance-2.md
guides/image/flux.md
guides/music/suno-v5-5.md
```

The app should consume `manifest.json` first, then fetch only the guide files it
needs. No crawling. No surprise downloads. No model weights.

## Source Documents

Put large Notion exports, upstream docs, and rough research captures under
`sources/`. These files are for authoring and review. They are not included in
the generated manifest, and the publish script does not upload them.
