import Foundation
import Testing

import CmuxFoundation
import CmuxSettings
import CmuxWorkspaces

#if canImport(cmux_DEV)
@testable import cmux_DEV
#elseif canImport(cmux)
@testable import cmux
#endif

@MainActor
@Suite("Workspace group rename persistence", .serialized)
struct WorkspaceGroupRenamePersistenceTests {
    private func makeTabManager() -> TabManager {
        let suiteName = "cmux.workspace-group-rename-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let manager = TabManager(
            autoWelcomeIfNeeded: false,
            settings: UserDefaultsSettingsClient(defaults: defaults),
            closeTabWarningDefaults: defaults
        )
        manager.addWorkspace(autoWelcomeIfNeeded: false)
        return manager
    }

    @Test("Renaming a generated group anchor survives session restore")
    func renamingGroupUpdatesPersistedAnchorIdentity() throws {
        let manager = makeTabManager()
        let groupID = try #require(
            manager.createWorkspaceGroup(name: "Group 1", childWorkspaceIds: [manager.tabs[0].id])
        )
        let group = try #require(manager.workspaceGroups.first { $0.id == groupID })
        let anchor = try #require(manager.tabs.first { $0.id == group.anchorWorkspaceId })

        manager.renameWorkspaceGroup(groupId: groupID, name: "Renamed Cloud Workspace")

        #expect(manager.workspaceGroups.first { $0.id == groupID }?.name == "Renamed Cloud Workspace")
        #expect(anchor.title == "Renamed Cloud Workspace")

        let restored = makeTabManager()
        restored.restoreSessionSnapshot(manager.sessionSnapshot(includeScrollback: false))
        let restoredGroup = try #require(restored.workspaceGroups.first { $0.id == groupID })
        let restoredAnchor = try #require(restored.tabs.first { $0.id == restoredGroup.anchorWorkspaceId })
        #expect(restoredGroup.name == "Renamed Cloud Workspace")
        #expect(restoredAnchor.title == "Renamed Cloud Workspace")
    }

    @Test("Renaming a group leaves a user-owned member title unchanged")
    func renamingGroupDoesNotRenameMembers() throws {
        let manager = makeTabManager()
        let memberID = manager.tabs[0].id
        let groupID = try #require(
            manager.createWorkspaceGroup(name: "Group 1", childWorkspaceIds: [memberID])
        )
        let member = try #require(manager.tabs.first { $0.id == memberID })
        let memberTitle = member.title

        manager.renameWorkspaceGroup(groupId: groupID, name: "Renamed")

        #expect(member.title == memberTitle)
    }
}
