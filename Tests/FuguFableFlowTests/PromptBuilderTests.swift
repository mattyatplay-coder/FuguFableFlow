import Foundation
import XCTest
@testable import FuguFableFlow

final class PromptBuilderTests: XCTestCase {
    func testParserFindsSeedanceImageToVideoTarget() {
        let command = PromptBuilderCommandParser().parse(
            "Turn this into a strong image-to-video prompt for a cinematic product shot, for Seedance 2."
        )

        XCTAssertEqual(command.targetModel?.id, "seedance-2.0")
        XCTAssertEqual(command.task, .imageToVideo)
    }

    func testParserFindsSpokenLTXAlias() {
        let command = PromptBuilderCommandParser().parse(
            "Rewrite this as an image to video prompt for LTX two point three"
        )

        XCTAssertEqual(command.targetModel?.id, "ltx-2.3")
        XCTAssertEqual(command.task, .imageToVideo)
    }

    func testParserFindsKreaTwoAlias() {
        let command = PromptBuilderCommandParser().parse(
            "Turn this into a strong Krea 2 image prompt using the clipboard image"
        )

        XCTAssertEqual(command.targetModel?.id, "krea-2")
        XCTAssertEqual(command.targetModel?.displayName, "Krea 2")
        XCTAssertEqual(command.task, .textToImage)
    }

    func testParserFindsFluxDevAndFluxKleinAliases() {
        let fluxDevCommand = PromptBuilderCommandParser().parse(
            "Turn this into a cinematic image prompt for Flux.1 Dev"
        )
        let fluxKleinCommand = PromptBuilderCommandParser().parse(
            "Turn this into a fast neon image prompt for Flux.2 Klein"
        )

        XCTAssertEqual(fluxDevCommand.targetModel?.id, "flux-1-dev")
        XCTAssertEqual(fluxDevCommand.targetModel?.displayName, "Flux.1 Dev")
        XCTAssertEqual(fluxKleinCommand.targetModel?.id, "flux-2-klein")
        XCTAssertEqual(fluxKleinCommand.targetModel?.displayName, "Flux.2 Klein")
    }

    func testParserFindsZImageTurboAlias() {
        let command = PromptBuilderCommandParser().parse(
            "Make this a 120 word positive prompt for Z-Image Turbo"
        )

        XCTAssertEqual(command.targetModel?.id, "z-image-turbo")
        XCTAssertEqual(command.targetModel?.displayName, "Z-Image Turbo")
        XCTAssertEqual(command.task, .generic)
    }

    func testParserFindsACEWorkflowAlias() {
        let command = PromptBuilderCommandParser().parse(
            "Turn this into an ACE-Step music prompt with local model constraints"
        )

        XCTAssertEqual(command.targetModel?.id, "ace-step-1.5")
        XCTAssertEqual(command.targetModel?.displayName, "ACE-Step 1.5")
        XCTAssertEqual(command.task, .textToMusic)
    }

    func testGuideSearchSkipsMediaAndOversizedFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let guide = root.appendingPathComponent("seedance-guide.md")
        try """
        Seedance 2.0 image to video prompts should describe subject, camera motion,
        scene continuity, product details, lighting, and motion intent.
        """.write(to: guide, atomically: true, encoding: .utf8)

        let media = root.appendingPathComponent("seedance-demo.mp4")
        try Data(repeating: 1, count: 128).write(to: media)

        let huge = root.appendingPathComponent("seedance-huge.md")
        try String(repeating: "Seedance ", count: 2_000).write(to: huge, atomically: true, encoding: .utf8)

        let command = PromptBuilderCommandParser().parse("Make this image to video for Seedance 2")
        let service = PromptGuideSearchService(
            configuration: PromptGuideSearchConfiguration(
                maxFileBytes: 512,
                maxTotalBytes: 2_048,
                maxFilesScanned: 20,
                maxResults: 5,
                maxSnippetCharacters: 200
            )
        )

        let results = try service.search(roots: [root], command: command)

        XCTAssertEqual(results.map(\.fileURL.lastPathComponent), ["seedance-guide.md"])
        XCTAssertTrue(results[0].snippet.contains("camera motion"))
    }

    func testGuideSearchRespectsResultCap() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        for index in 0..<5 {
            try "Flux image prompt guide \(index)"
                .write(to: root.appendingPathComponent("flux-\(index).md"), atomically: true, encoding: .utf8)
        }

        let command = PromptBuilderCommandParser().parse("Make this a text to image prompt for Flux")
        let service = PromptGuideSearchService(
            configuration: PromptGuideSearchConfiguration(maxResults: 2)
        )

        let results = try service.search(roots: [root], command: command)

        XCTAssertEqual(results.count, 2)
    }

    func testLocalTemplateIncludesGuideAndWeightReferences() throws {
        let command = PromptBuilderCommandParser().parse("Turn this into a strong image to video prompt for Seedance 2")
        let guide = PromptGuideSearchResult(
            fileURL: URL(fileURLWithPath: "/tmp/seedance-guide.md"),
            score: 12,
            snippet: "Describe product material, controlled camera motion, continuity, and lighting."
        )
        let weights = PromptModelWeightSummary(
            roots: ["/models"],
            fileCount: 1,
            totalBytes: 1024,
            extensions: ["gguf"],
            scannedAt: Date()
        )

        let output = PromptBuilderService.localTemplate(
            selectedText: "A matte black espresso machine on a marble counter.",
            command: command,
            guideResults: [guide],
            weightSummary: weights
        )

        XCTAssertTrue(output.contains("Seedance 2.0"))
        XCTAssertTrue(output.contains("camera motion"))
        XCTAssertTrue(output.contains("does not load model weights"))
    }

    func testProviderMessagesTreatGuideTextAsUntrustedContext() {
        let command = PromptBuilderCommandParser().parse("Make a text to image prompt for Flux")
        let messages = PromptBuilderService.messages(
            selectedText: "A compact dictation app in a menu bar.",
            command: command,
            guideResults: [],
            weightSummary: nil
        )

        XCTAssertEqual(messages.first?["role"] as? String, "system")
        XCTAssertTrue((messages.first?["content"] as? String)?.contains("untrusted reference notes") == true)
        XCTAssertTrue((messages.last?["content"] as? String)?.contains("Target generation model: Flux") == true)
    }

    func testCommandRequestsClipboardImageReferenceOnlyWhenExplicit() {
        let withImage = PromptBuilderCommandParser().parse(
            "Turn this into an image to video prompt for Seedance 2 using the clipboard image"
        )
        let withoutImage = PromptBuilderCommandParser().parse(
            "Turn this into an image to video prompt for Seedance 2"
        )

        XCTAssertTrue(withImage.requestsClipboardImageReference)
        XCTAssertFalse(withoutImage.requestsClipboardImageReference)
    }

    func testProviderMessagesAttachClipboardImageAsImageURL() {
        let command = PromptBuilderCommandParser().parse(
            "Make this an image to video prompt for Seedance 2 using this image"
        )
        let image = PromptBuilderImageReference(
            mimeType: "image/jpeg",
            base64Data: "abc123",
            width: 512,
            height: 384,
            byteCount: 42
        )

        let messages = PromptBuilderService.messages(
            selectedText: "Premium espresso machine.",
            command: command,
            guideResults: [],
            weightSummary: nil,
            imageReference: image
        )

        let userContent = messages.last?["content"] as? [[String: Any]]
        XCTAssertEqual(userContent?.count, 2)
        XCTAssertEqual(userContent?.first?["type"] as? String, "text")
        XCTAssertEqual(userContent?.last?["type"] as? String, "image_url")
        let imageURL = userContent?.last?["image_url"] as? [String: String]
        XCTAssertEqual(imageURL?["url"], "data:image/jpeg;base64,abc123")
        XCTAssertEqual(imageURL?["detail"], "low")
    }

    func testProviderMessageIncludesReferenceSheetGuardrails() {
        let command = PromptBuilderCommandParser().parse(
            "Turn this into a strong Krea 2 image prompt using the clipboard image"
        )
        let messages = PromptBuilderService.messages(
            selectedText: "### Reference Sheet Description\nCharacter and props.\n### Target Description\nFinal scene.",
            command: command,
            guideResults: [],
            weightSummary: nil,
            imageReference: nil
        )

        let content = messages.last?["content"] as? String
        XCTAssertTrue(content?.contains("Target generation model: Krea 2") == true)
        XCTAssertTrue(content?.contains("use the Target Description as the main output goal") == true)
        XCTAssertTrue(content?.contains("Do not generate a reference-sheet layout") == true)
        XCTAssertTrue(content?.contains("For Krea 2, prefer one cohesive natural-language paragraph") == true)
    }

    func testTargetSpecificSystemPromptsAndTemperature() {
        let kreaCommand = PromptBuilderCommandParser().parse(
            "Turn this into a strong Krea 2 image prompt"
        )
        let ltxCommand = PromptBuilderCommandParser().parse(
            "Turn this into a strong image to video prompt for LTX 2.3"
        )
        let fluxDevCommand = PromptBuilderCommandParser().parse(
            "Turn this into a strong image prompt for Flux.1 Dev"
        )
        let fluxKleinCommand = PromptBuilderCommandParser().parse(
            "Turn this into a strong image prompt for Flux.2 Klein"
        )
        let zImageCommand = PromptBuilderCommandParser().parse(
            "Turn this into a strong image prompt for Z-Image Turbo"
        )
        let seedanceCommand = PromptBuilderCommandParser().parse(
            "Turn this into a strong Seedance 2 image to video prompt"
        )

        XCTAssertEqual(PromptBuilderService.temperature(for: kreaCommand), 1.0)
        XCTAssertEqual(PromptBuilderService.temperature(for: seedanceCommand), 0.35)
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: kreaCommand).contains("expert prompt engineer for text-to-image models"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: kreaCommand).contains("Then output a single expanded prompt paragraph"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: seedanceCommand).contains("Seedance 2.0 scene direction API"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: seedanceCommand).contains("single-line JSON array"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: ltxCommand).contains("LTX2PromptArchitect"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: ltxCommand).contains("Scene 1 [00:00-00:05]"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: fluxDevCommand).contains("FluxPromptArchitect"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: fluxDevCommand).contains("Guidance Scale: 3.5"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: fluxKleinCommand).contains("Flux2KleinPromptArchitect"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: fluxKleinCommand).contains("Variant: [4B for speed or 9B for higher detail]"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: zImageCommand).contains("ZImageTurboPromptArchitect"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: zImageCommand).contains("Guidance Scale: 0.0"))
        XCTAssertTrue(PromptBuilderService.systemPrompt(for: zImageCommand).contains("80-250 word range"))
    }

    func testGuideIndexScansMetadataWithoutReadingMedia() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try "Flux prompt guide"
            .write(to: root.appendingPathComponent("flux.md"), atomically: true, encoding: .utf8)
        try Data(repeating: 1, count: 512)
            .write(to: root.appendingPathComponent("preview.png"))
        try String(repeating: "large", count: 1_000)
            .write(to: root.appendingPathComponent("huge.md"), atomically: true, encoding: .utf8)

        let summary = try PromptGuideIndexService(
            configuration: PromptGuideIndexConfiguration(maxFileBytes: 100, maxFilesScanned: 10)
        ).index(roots: [root])

        XCTAssertEqual(summary.fileCount, 1)
        XCTAssertEqual(summary.skippedLargeFiles, 1)
    }

    func testModelWeightScannerOnlyTracksSupportedWeightFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try Data(repeating: 1, count: 64)
            .write(to: root.appendingPathComponent("tiny.gguf"))
        try Data(repeating: 1, count: 64)
            .write(to: root.appendingPathComponent("notes.md"))

        let summary = try PromptModelWeightScanner().scan(roots: [root])

        XCTAssertEqual(summary.fileCount, 1)
        XCTAssertEqual(summary.extensions, ["gguf"])
    }
}
