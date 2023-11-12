//
//  Copyright © Marc Rollin.
//

import ApplicationArchive
import DesignSystem
import SwiftUI

// MARK: - ApplicationDisplayable

public protocol ApplicationDisplayable {
    var name: String { get }
    var icon: Data? { get }
    var version: String { get }
    var platforms: [ArchiveApp.Platform] { get }
}

// MARK: - ApplicationView

public struct ApplicationView: View {

    // MARK: Lifecycle

    public init(application: ApplicationDisplayable, didTap: (() -> Void)? = nil) {
        self.application = application
        self.didTap = didTap
    }

    // MARK: Public

    public var body: some View {
        Button {
            didTap?()
        } label: {
            HStack {
                icon(application.icon)
                    .background(.secondary.opacity(designSystem.opacity(.faint)))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary, lineWidth: 1))

                VStack(alignment: .leading) {
                    Text(application.name)
                    Text(application.version)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ForEach(application.platforms, id: \.self) { platform in
                    platform.icon
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Internal

    let application: ApplicationDisplayable
    let didTap: (() -> Void)?

    // MARK: Private

    @Environment(DesignSystem.self) private var designSystem

    private func image(_ data: Data) -> Image? {
#if os(macOS)
        if let image = NSImage(data: data) {
            return Image(nsImage: image)
        }
#else
        if let image = UIImage(data: data) {
            return Image(uiImage: image)
        }
#endif
        return nil
    }

    @ViewBuilder
    private func icon(_ data: Data?) -> some View {
        if let data,
           let image = image(data) {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 32, maxHeight: 32)
        } else {
            Image(systemName: "apple.logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 16, maxHeight: 16)
                .padding(8)
        }
    }
}
