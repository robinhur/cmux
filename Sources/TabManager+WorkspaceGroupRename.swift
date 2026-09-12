import CmuxWorkspaces
import Foundation

extension TabManager {
    /// Renames a workspace group and synchronizes a generated anchor through
    /// the same user-title path as a direct workspace rename.
    func renameWorkspaceGroup(groupId: UUID, name: String) {
        let previousName = workspaceGroups.first { $0.id == groupId }?.name
        workspaceGrouping.renameWorkspaceGroup(groupId: groupId, name: name)

        guard let group = workspaceGroups.first(where: { $0.id == groupId }),
              previousName != group.name,
              group.anchorWorkspaceProvenance == .generated,
              let anchorID = group.liveAnchorWorkspaceId else { return }
        _ = setCustomTitle(
            tabId: anchorID,
            title: group.name,
            source: .user,
            propagateToRemoteTmux: false
        )
    }
}
