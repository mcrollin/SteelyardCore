//
//  Copyright © Marc Rollin.
//

import SwiftUI

// MARK: - BranchDisclosureGroup

public struct ExpandableGroup<Label: View, Content: View>: View {

    // MARK: Lifecycle

    public init(
        isExpanded: Binding<Bool>,
        content: @escaping () -> Content,
        label: @escaping () -> Label
    ) {
        _isExpanded = isExpanded
        self.content = content
        self.label = label
    }

    // MARK: Public

    public var body: some View {
        VStack(spacing: .zero) {
            label()
            LazyVStack(spacing: .zero) {
                if isExpanded {
                    content()
                }
            }
        }
    }

    // MARK: Internal

    @Binding var isExpanded: Bool
    let content: () -> Content
    let label: () -> Label
}
