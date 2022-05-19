import Foundation
import ProjectDescription
import TuistCore
import TuistGraph
import TuistSupport
import TuistSupportTesting
import XCTest

@testable import TuistLoader

final class WorkspaceGenerationOptionsManifestMapperTests: TuistTestCase {
    func test_from_whenAutomaticXcodeSchemeIsDefault() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        let manifest = ProjectDescription.Workspace.GenerationOptions.options(
            enableAutomaticXcodeSchemes: nil,
            autogeneratedWorkspaceSchemes: .disabled,
            lastXcodeUpgradeCheck: .init("1.2.3"),
            renderMarkdownReadme: false
        )

        // When
        let actual = try TuistGraph.Workspace.GenerationOptions.from(manifest: manifest, generatorPaths: generatorPaths)

        // Then
        XCTAssertEqual(
            actual,
            .init(
                enableAutomaticXcodeSchemes: nil,
                autogeneratedWorkspaceSchemes: .disabled,
                disableStaticProductsLint: false,
                lastXcodeUpgradeCheck: .init("1.2.3"),
                renderMarkdownReadme: false
            )
        )
    }

    func test_from_whenAutomaticXcodeSchemeIsDisabled() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        let manifest = ProjectDescription.Workspace.GenerationOptions.options(
            enableAutomaticXcodeSchemes: false,
            autogeneratedWorkspaceSchemes: .disabled
        )

        // When
        let actual = try TuistGraph.Workspace.GenerationOptions.from(manifest: manifest, generatorPaths: generatorPaths)

        // Then
        XCTAssertEqual(
            actual,
            .init(
                enableAutomaticXcodeSchemes: false,
                autogeneratedWorkspaceSchemes: .disabled,
                disableStaticProductsLint: false,
                lastXcodeUpgradeCheck: nil,
                renderMarkdownReadme: false
            )
        )
    }

    func test_from_whenAutomaticXcodeSchemeIsEnabled() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        let manifest = ProjectDescription.Workspace.GenerationOptions.options(
            enableAutomaticXcodeSchemes: true,
            autogeneratedWorkspaceSchemes: .disabled,
            renderMarkdownReadme: false
        )

        // When
        let actual = try TuistGraph.Workspace.GenerationOptions.from(manifest: manifest, generatorPaths: generatorPaths)

        // Then
        XCTAssertEqual(
            actual,
            .init(
                enableAutomaticXcodeSchemes: true,
                autogeneratedWorkspaceSchemes: .disabled,
                disableStaticProductsLint: false,
                lastXcodeUpgradeCheck: nil,
                renderMarkdownReadme: false
            )
        )
    }

    func test_from_whenAutogenerationOptionsIsEnabled() throws {
        // Given
        let temporaryPath = try temporaryPath()
        let generatorPaths = GeneratorPaths(manifestDirectory: temporaryPath)
        let manifest = ProjectDescription.Workspace.GenerationOptions.options(
            enableAutomaticXcodeSchemes: true,
            autogeneratedWorkspaceSchemes: .enabled(
                codeCoverageMode: .all,
                testingOptions: [.parallelizable, .randomExecutionOrdering]
            )
        )

        // When
        let actual = try TuistGraph.Workspace.GenerationOptions.from(manifest: manifest, generatorPaths: generatorPaths)

        // Then
        XCTAssertEqual(
            actual,
            .init(
                enableAutomaticXcodeSchemes: true,
                autogeneratedWorkspaceSchemes: .enabled(
                    codeCoverageMode: .all,
                    testingOptions: [.parallelizable, .randomExecutionOrdering]
                ),
                disableStaticProductsLint: false,
                lastXcodeUpgradeCheck: nil,
                renderMarkdownReadme: false
            )
        )
        // Then
        XCTAssertEqual(
            actual,
            .init(
                enableAutomaticXcodeSchemes: true,
                autogeneratedWorkspaceSchemes: .enabled(
                    codeCoverageMode: .all,
                    testingOptions: [.parallelizable, .randomExecutionOrdering]
                ),
                disableStaticProductsLint: false,
                lastXcodeUpgradeCheck: nil,
                renderMarkdownReadme: false
            )
        )
    }
}
