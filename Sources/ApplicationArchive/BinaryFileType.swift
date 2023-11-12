//
//  Copyright © Marc Rollin.
//

import Foundation

// MARK: - BinaryFileType

public enum BinaryFileType: Sendable {
    case machO
    case elf
    case windowsPE

    // MARK: Public

    public var description: String {
        switch self {
        case .machO:
            "Mach-O"
        case .elf:
            "ELF"
        case .windowsPE:
            "Windows PE"
        }
    }

    // MARK: Fileprivate

    fileprivate static let machOMagicNumbers: [[UInt8]] = [
        [0xFE, 0xED, 0xFA, 0xCE], // Mach-O 32-bit big-endian
        [0xFE, 0xED, 0xFA, 0xCF], // Mach-O 64-bit big-endian
        [0xCE, 0xFA, 0xED, 0xFE], // Mach-O 32-bit little-endian
        [0xCF, 0xFA, 0xED, 0xFE], // Mach-O 64-bit little-endian
        [0xBE, 0xBA, 0xFE, 0xCA], // Mach-O universal binary (big-endian)
        [0xCA, 0xFE, 0xBA, 0xBE], // Mach-O universal binary (little-endian)
        [0xCA, 0xFE, 0xBA, 0xBF], // Mach-O 64-bit universal binary (little-endian)
        [0xBF, 0xBA, 0xFE, 0xCA], // Mach-O 64-bit universal binary (big-endian)
    ]
}

extension URL {

    // MARK: Internal

    var binaryFileType: BinaryFileType? {
        guard let fileHandle = try? FileHandle(forReadingFrom: self) else {
            return nil
        }

        let data = fileHandle.readData(ofLength: 4) // Read only the first 64 bytes
        fileHandle.closeFile()

        return if isMachO(data: data) {
            .machO
        } else if isELF(data: data) {
            .elf
        } else if isWindowsPE(data: data) {
            .windowsPE
        } else {
            nil
        }
    }

    // MARK: Private

    private func isMachO(data: Data) -> Bool {
        BinaryFileType.machOMagicNumbers.contains(where: data.starts)
    }

    private func isELF(data: Data) -> Bool {
        data.starts(with: [0x7F, 0x45, 0x4C, 0x46])
    }

    private func isWindowsPE(data: Data) -> Bool {
        data.starts(with: [0x4D, 0x5A])
    }
}
