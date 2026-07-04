# Security and Privacy

FuguFableFlow is designed to be privacy-first and memory-light, but it is not a zero-network app in every mode. This document describes the current security posture and data boundaries.

## Current audit summary

Last reviewed: 2026-07-04

Reviewed areas:

- outbound network calls
- API-key storage
- transcript persistence
- clipboard handling
- diagnostic logging
- generated app bundle metadata

Findings:

- FuguFableFlow has no backend service.
- FuguFableFlow has no analytics or telemetry service.
- Normal dictation uses Apple's Speech framework.
- Command Mode is off by default.
- Hosted Command Mode providers send selected text and the spoken command only to the provider selected by the user.
- Local Ollama sends Command Mode requests to `localhost` only and requires the user to run Ollama separately.
- Provider API keys are stored in macOS Keychain.
- Legacy OpenAI keys previously stored under the earlier PersonalFlow app identity are migrated to the FuguFableFlow Keychain entries where possible.
- Transcript history is not written to disk by the app.
- Diagnostic logs avoid transcript content and API keys.
- Clipboard contents may be temporarily held in memory only when Restore Clipboard is enabled, so the app can restore the user's clipboard after paste.

## Network behavior

The app has these network-capable paths:

- Apple Speech framework for normal dictation.
- `https://openrouter.ai/api/v1/chat/completions` when Command Mode provider is OpenRouter.
- `https://router.huggingface.co/v1/chat/completions` when Command Mode provider is Hugging Face.
- `https://api.openai.com/v1/chat/completions` when Command Mode provider is OpenAI.
- `http://localhost:11434/api/chat` when Command Mode provider is Local Ollama.

FuguFableFlow does not start Ollama, bundle model weights, or proxy data through an app-owned server.

## Local storage

Stored locally:

- user settings in macOS preferences
- provider API keys in macOS Keychain
- current transcript preview in memory
- last transcript in memory for Copy Last Transcript
- temporary clipboard snapshot in memory when clipboard restoration is enabled

Not stored by FuguFableFlow:

- transcript history files
- audio recordings
- analytics events
- API keys in repository files

## Reporting issues

For a public repository, use GitHub private vulnerability reporting if enabled. Otherwise, open a minimal issue that does not include secrets, transcripts, API keys, or private text.
