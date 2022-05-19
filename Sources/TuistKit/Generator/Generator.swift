import Foundation
import ProjectDescription
import TSCBasic
import TuistCore
import TuistDependencies
import TuistGenerator
import TuistGraph
import TuistLoader
import TuistPlugin
import TuistSigning
import TuistSupport

protocol Generating {
    @discardableResult
    func load(path: AbsolutePath) async throws -> Graph
    func generate(path: AbsolutePath) async throws -> AbsolutePath
    func generateWithGraph(path: AbsolutePath) async throws -> (AbsolutePath, Graph)
}

class Generator: Generating {
    private let graphLinter: GraphLinting = GraphLinter()
    private let environmentLinter: EnvironmentLinting = EnvironmentLinter()
    private let generator: DescriptorGenerating = DescriptorGenerator()
    private let writer: XcodeProjWriting = XcodeProjWriter()
    private let swiftPackageManagerInteractor: TuistGenerator.SwiftPackageManagerInteracting = TuistGenerator
        .SwiftPackageManagerInteractor()
    private let signingInteractor: SigningInteracting = SigningInteractor()
    private let sideEffectDescriptorExecutor: SideEffectDescriptorExecuting
    private let configLoader: ConfigLoading
    private let manifestGraphLoader: ManifestGraphLoading
    private var lintingIssues: [LintingIssue] = []

    init(
        manifestLoader: ManifestLoading,
        manifestGraphLoader: ManifestGraphLoading
    ) {
        sideEffectDescriptorExecutor = SideEffectDescriptorExecutor()
        configLoader = ConfigLoader(
            manifestLoader: manifestLoader,
            rootDirectoryLocator: RootDirectoryLocator(),
            fileHandler: FileHandler.shared
        )
        self.manifestGraphLoader = manifestGraphLoader
    }

    func generate(path: AbsolutePath) async throws -> AbsolutePath {
        let (generatedPath, _) = try await generateWithGraph(path: path)
        return generatedPath
    }

    func generateWithGraph(path: AbsolutePath) async throws -> (AbsolutePath, Graph) {
        let (graph, sideEffects) = try await load(path: path)

        // Load
        let graphTraverser = GraphTraverser(graph: graph)

        // Lint
        try lint(
            graphTraverser: graphTraverser,
            disableStaticProductsLint: graph.workspace.generationOptions.disableStaticProductsLint
        )

        // Generate
        let workspaceDescriptor = try generator.generateWorkspace(graphTraverser: graphTraverser)

        // Write
        try writer.write(workspace: workspaceDescriptor)

        // Mapper side effects
        try sideEffectDescriptorExecutor.execute(sideEffects: sideEffects)

        // Post Generate Actions
        try await postGenerationActions(
            graphTraverser: graphTraverser,
            workspaceName: workspaceDescriptor.xcworkspacePath.basename
        )

        printAndFlushPendingLintWarnings()

        return (workspaceDescriptor.xcworkspacePath, graph)
    }

    func load(path: AbsolutePath) async throws -> Graph {
        try await load(path: path).0
    }

    func load(path: AbsolutePath) async throws -> (Graph, [SideEffectDescriptor]) {
        let (graph, sideEffectDescriptors, issues) = try await manifestGraphLoader.load(path: path)
        lintingIssues.append(contentsOf: issues)
        return (graph, sideEffectDescriptors)
    }

    private func lint(graphTraverser: GraphTraversing, disableStaticProductsLint: Bool) throws {
        let config = try configLoader.loadConfig(path: graphTraverser.path)

        let environmentIssues = try environmentLinter.lint(config: config)
        try environmentIssues.printAndThrowErrorsIfNeeded()
        lintingIssues.append(contentsOf: environmentIssues)

        let graphIssues = graphLinter.lint(graphTraverser: graphTraverser, disableStaticProductsLint: disableStaticProductsLint)
        try graphIssues.printAndThrowErrorsIfNeeded()
        lintingIssues.append(contentsOf: graphIssues)
    }

    private func postGenerationActions(graphTraverser: GraphTraversing, workspaceName: String) async throws {
        let config = try configLoader.loadConfig(path: graphTraverser.path)

        lintingIssues.append(contentsOf: try signingInteractor.install(graphTraverser: graphTraverser))
        try await swiftPackageManagerInteractor.install(
            graphTraverser: graphTraverser,
            workspaceName: workspaceName,
            config: config
        )
    }

    private func printAndFlushPendingLintWarnings() {
        // Print out warnings, if any
        lintingIssues.printWarningsIfNeeded()
        lintingIssues.removeAll()
    }
}
