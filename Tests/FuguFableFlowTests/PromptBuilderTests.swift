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

        XCTAssertEqual(messages.first?["role"], "system")
        XCTAssertTrue(messages.first?["content"]?.contains("untrusted reference notes") == true)
        XCTAssertTrue(messages.last?["content"]?.contains("Target generation model: Flux") == true)
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
