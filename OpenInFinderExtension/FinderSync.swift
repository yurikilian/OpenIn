import Cocoa
import FinderSync

final class FinderSync: FIFinderSync {

    private enum AppTarget: Int, CaseIterable {
        case vscode = 1
        case zed = 2
        case intellij = 3
        case orca = 4

        var name: String {
            switch self {
            case .vscode:
                return "Visual Studio Code"
            case .zed:
                return "Zed"
            case .intellij:
                return "IntelliJ IDEA"
            case .orca:
                return "Orca"
            }
        }

        var bundleIdentifier: String {
            switch self {
            case .vscode:
                return "com.microsoft.VSCode"
            case .zed:
                return "dev.zed.Zed"
            case .intellij:
                return "com.jetbrains.intellij"
            case .orca:
                return "com.stablyai.orca"
            }
        }

        var applicationURL: URL? {
            NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: bundleIdentifier
            )
        }
    }

    /*
     Ícones carregados uma vez: o Finder descarta o menu
     se menu(for:) demorar para responder.
     */
    private lazy var appIcons: [AppTarget: NSImage] = {
        var icons: [AppTarget: NSImage] = [:]

        for app in AppTarget.allCases {
            guard let applicationURL = app.applicationURL else {
                continue
            }

            let icon = NSWorkspace.shared.icon(forFile: applicationURL.path)
            icon.size = NSSize(width: 16, height: 16)
            icons[app] = icon
        }

        return icons
    }()

    override init() {
        super.init()

        /*
         Monitora o disco inteiro. Dentro do sandbox,
         homeDirectoryForCurrentUser aponta para o container
         da extensão, não para o ~ real.
         */
        FIFinderSyncController.default().directoryURLs = [
            URL(fileURLWithPath: "/", isDirectory: true)
        ]

        _ = appIcons
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {

        switch menuKind {
        case .contextualMenuForItems,
             .contextualMenuForContainer,
             .contextualMenuForSidebar:

            return makeOpenInMenu()

        default:
            return nil
        }
    }

    private func makeOpenInMenu() -> NSMenu? {

        let installedApps = AppTarget.allCases.filter {
            appIcons[$0] != nil
        }

        guard !installedApps.isEmpty else {
            return nil
        }

        let rootMenu = NSMenu()

        let openInItem = NSMenuItem(
            title: "Open in",
            action: nil,
            keyEquivalent: ""
        )

        let openInMenu = NSMenu(title: "Open in")

        for app in installedApps {
            addApp(app, to: openInMenu)
        }

        rootMenu.addItem(openInItem)
        rootMenu.setSubmenu(openInMenu, for: openInItem)

        return rootMenu
    }

    private func addApp(
        _ app: AppTarget,
        to menu: NSMenu
    ) {
        let item = NSMenuItem(
            title: app.name,
            action: #selector(openApplication(_:)),
            keyEquivalent: ""
        )

        item.target = self
        item.tag = app.rawValue

        item.image = appIcons[app]

        menu.addItem(item)
    }

    @objc
    private func openApplication(_ sender: NSMenuItem) {

        guard let app = AppTarget(rawValue: sender.tag) else {
            return
        }

        let targets = targetURLs()

        guard !targets.isEmpty else {
            NSLog("[OpenIn] No Finder target found")
            return
        }

        guard let applicationURL = app.applicationURL else {
            NSLog(
                "[OpenIn] Application not found: \(app.name) - \(app.bundleIdentifier)"
            )
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()

        NSWorkspace.shared.open(
            targets,
            withApplicationAt: applicationURL,
            configuration: configuration
        ) { _, error in

            if let error {
                NSLog(
                    "[OpenIn] Failed opening \(app.name): \(error.localizedDescription)"
                )
            }
        }
    }

    private func targetURLs() -> [URL] {

        let controller = FIFinderSyncController.default()

        /*
         Se clicou com botão direito em uma ou mais pastas,
         usa as pastas selecionadas.
         */
        if let selectedURLs = controller.selectedItemURLs(),
           !selectedURLs.isEmpty {

            return Array(Set(selectedURLs.map { normalizeToDirectory($0) }))
        }

        /*
         Se clicou no espaço vazio dentro de uma pasta,
         targetedURL() é a pasta atual.
         */
        if let targetedURL = controller.targetedURL() {
            return [normalizeToDirectory(targetedURL)]
        }

        return []
    }

    private func normalizeToDirectory(_ url: URL) -> URL {

        /*
         O sandbox pode negar stat fora do container;
         nesse caso confia no hasDirectoryPath que o Finder manda.
         */
        let isDirectory =
            (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory
            ?? url.hasDirectoryPath

        if isDirectory {
            return url
        }

        // Caso clique num arquivo,
        // abre a pasta que contém esse arquivo.
        return url.deletingLastPathComponent()
    }
}
