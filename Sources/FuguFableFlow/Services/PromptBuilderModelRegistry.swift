import Foundation

struct PromptBuilderModelRegistry: Sendable {
    let profiles: [PromptBuilderModelProfile]

    init(profiles: [PromptBuilderModelProfile] = Self.defaultProfiles) {
        self.profiles = profiles
    }

    func resolveModel(in text: String) -> PromptBuilderModelProfile? {
        let normalizedText = Self.normalized(text)
        return profiles
            .flatMap { profile in
                profile.aliases.map { alias in
                    (profile: profile, alias: Self.normalized(alias))
                }
            }
            .sorted { lhs, rhs in
                if lhs.alias.count == rhs.alias.count {
                    lhs.profile.priority < rhs.profile.priority
                } else {
                    lhs.alias.count > rhs.alias.count
                }
            }
            .first { candidate in
                guard !candidate.alias.isEmpty else { return false }
                return Self.containsPhrase(candidate.alias, in: normalizedText)
            }?
            .profile
    }

    func profile(id: String) -> PromptBuilderModelProfile? {
        let normalizedID = Self.normalized(id)
        return profiles.first { profile in
            Self.normalized(profile.id) == normalizedID
                || profile.aliases.contains { Self.normalized($0) == normalizedID }
        }
    }

    static func normalized(_ text: String) -> String {
        let folded = text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
        let scalars = folded.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        }
        return String(scalars)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func containsPhrase(_ phrase: String, in text: String) -> Bool {
        text == phrase || text.hasPrefix("\(phrase) ") || text.hasSuffix(" \(phrase)") || text.contains(" \(phrase) ")
    }

    static let defaultProfiles: [PromptBuilderModelProfile] = [
        PromptBuilderModelProfile(
            id: "seedance-2.0",
            displayName: "Seedance 2.0",
            aliases: ["seedance", "seedance 2", "seedance 2.0", "seedance two", "dreamina seedance", "dreamina seedance 2"],
            modalities: [.video],
            guidePathHints: ["seedance"],
            isOpenWeights: false,
            priority: 0
        ),
        PromptBuilderModelProfile(
            id: "ltx-2.3",
            displayName: "LTX-2.3",
            aliases: ["ltx", "ltx 2", "ltx 2.3", "ltx two point three", "ltx23", "ltx 23"],
            modalities: [.video],
            guidePathHints: ["ltx-2.3", "ltx"],
            isOpenWeights: true,
            priority: 0
        ),
        PromptBuilderModelProfile(
            id: "wan-2.7",
            displayName: "Wan 2.7",
            aliases: ["wan", "wan 2", "wan 2.7", "wan two point seven", "wan 2.6", "wan 2.2", "wan two point two"],
            modalities: [.video],
            guidePathHints: ["wan"],
            isOpenWeights: false,
            priority: 0
        ),
        PromptBuilderModelProfile(
            id: "gpt-image-2",
            displayName: "GPT Image 2",
            aliases: ["gpt image", "gpt image 2", "gpt image two", "chatgpt image", "openai image"],
            modalities: [.image],
            guidePathHints: ["gpt-image-2", "fal-prompting"],
            isOpenWeights: false,
            priority: 0
        ),
        PromptBuilderModelProfile(
            id: "nano-banana",
            displayName: "Nano Banana",
            aliases: ["nano banana", "nano banana 2", "nano banana pro", "gemini image", "gemini 3 pro image"],
            modalities: [.image],
            guidePathHints: ["nano-banana", "gemini"],
            isOpenWeights: false,
            priority: 1
        ),
        PromptBuilderModelProfile(
            id: "flux-1-dev",
            displayName: "Flux.1 Dev",
            aliases: ["flux 1 dev", "flux.1 dev", "flux one dev", "flux dev", "flux1 dev", "flux 1"],
            modalities: [.image],
            guidePathHints: ["flux-1-dev", "flux.1-dev", "flux"],
            isOpenWeights: true,
            priority: 0
        ),
        PromptBuilderModelProfile(
            id: "flux",
            displayName: "Flux",
            aliases: ["flux", "flux 2", "flux.2", "flux max", "flux dev", "flux schnell"],
            modalities: [.image],
            guidePathHints: ["Flux", "flux"],
            isOpenWeights: true,
            priority: 1
        ),
        PromptBuilderModelProfile(
            id: "flux-2-klein",
            displayName: "Flux.2 Klein",
            aliases: ["flux 2 klein", "flux.2 klein", "flux2 klein", "flux klein", "flux two klein"],
            modalities: [.image],
            guidePathHints: ["flux-2-klein", "flux.2-klein", "flux"],
            isOpenWeights: true,
            priority: 0
        ),
        PromptBuilderModelProfile(
            id: "krea-2",
            displayName: "Krea 2",
            aliases: ["krea", "krea 2", "krea two", "krea turbo", "krea 2 turbo"],
            modalities: [.image],
            guidePathHints: ["krea-2", "krea"],
            isOpenWeights: true,
            priority: 1
        ),
        PromptBuilderModelProfile(
            id: "z-image-turbo",
            displayName: "Z-Image Turbo",
            aliases: ["z image turbo", "z-image turbo", "zimage turbo", "z image", "z-image", "zimage"],
            modalities: [.image],
            guidePathHints: ["z-image-turbo", "z-image", "zimage"],
            isOpenWeights: true,
            priority: 0
        ),
        PromptBuilderModelProfile(
            id: "qwen-image",
            displayName: "Qwen Image",
            aliases: ["qwen", "qwen image", "qwen image edit", "qwen edit"],
            modalities: [.image, .speech],
            guidePathHints: ["Qwen", "qwen"],
            isOpenWeights: true,
            priority: 1
        ),
        PromptBuilderModelProfile(
            id: "suno-v5.5",
            displayName: "Suno V5.5",
            aliases: ["suno", "suno 5", "suno 5.5", "suno v5", "suno v5.5"],
            modalities: [.music],
            guidePathHints: ["suno", "Audio & TTS"],
            isOpenWeights: false,
            priority: 1
        ),
        PromptBuilderModelProfile(
            id: "ace-step-1.5",
            displayName: "ACE-Step 1.5",
            aliases: ["ace step", "ace-step", "ace step 1.5", "ace-step 1.5", "ace music"],
            modalities: [.music],
            guidePathHints: ["ace-step", "ace step", "Audio & TTS"],
            isOpenWeights: true,
            priority: 0
        ),
        PromptBuilderModelProfile(
            id: "veo-3.1",
            displayName: "Veo 3.1",
            aliases: ["veo", "veo 3", "veo 3.1", "veo three point one"],
            modalities: [.video],
            guidePathHints: ["veo"],
            isOpenWeights: false,
            priority: 2
        ),
        PromptBuilderModelProfile(
            id: "kling-3.0",
            displayName: "Kling 3.0",
            aliases: ["kling", "kling 3", "kling 3.0", "kling three"],
            modalities: [.video],
            guidePathHints: ["kling"],
            isOpenWeights: false,
            priority: 2
        ),
        PromptBuilderModelProfile(
            id: "happyhorse",
            displayName: "HappyHorse",
            aliases: ["happyhorse", "happy horse", "happyhorse 1", "happyhorse 1.1"],
            modalities: [.video],
            guidePathHints: ["happyhorse"],
            isOpenWeights: false,
            priority: 2
        )
    ]
}
