//
//  Copyright © Marc Rollin.
//

import DesignSystem
import SwiftUI

public struct DiscloseButton: View {

    // MARK: Lifecycle

    public init(
        isExpanded: Binding<Bool>,
        size: CGFloat = 8,
        padding: DesignSystem.Token.Spacing = .extraSmall
    ) {
        _isExpanded = isExpanded
        self.size = size
        self.padding = padding
    }

    // MARK: Public

    public var body: some View {
        Button {
            withAnimation(designSystem.animation(.expand)) {
                isExpanded.toggle()
            }
        } label: {
            Image(systemName: "chevron.right")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size, alignment: .center)
                .rotationEffect(isExpanded ? .degrees(90) : .zero)
                .padding(designSystem.spacing(padding))
                .background(.black.opacity(designSystem.opacity(.veil)))
        }
        .buttonStyle(.plain)
    }

    // MARK: Internal

    @Binding var isExpanded: Bool
    let size: CGFloat
    let padding: DesignSystem.Token.Spacing

    // MARK: Private

    @Environment(DesignSystem.self) private var designSystem
}
