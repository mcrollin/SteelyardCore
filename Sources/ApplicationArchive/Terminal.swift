//
//  Copyright © Marc Rollin.
//

import Foundation

// MARK: - Terminal

final class Terminal: @unchecked Sendable {

    // MARK: Lifecycle

    init() { }

    // MARK: Internal

    struct TerminationError: Error {
        let reason: Process.TerminationReason
        let status: Int32
    }

    var process: Process?
    var outputPipe: Pipe?
    var inputPipe: Pipe?

    var isRunning: Bool { process?.isRunning ?? false }

    func streamCommand(
        _ command: String = "/bin/bash",
        arguments: [String],
        currentDirectoryPath: String = "/",
        environment: [String: String] = [:]
    ) -> AsyncThrowingStream<Data, Error> {
        self.process?.terminate()
        let process = Process()
        self.process = process

        process.launchPath = command
        process.currentDirectoryPath = currentDirectoryPath
        process.arguments = arguments
        process.environment = getEnvironmentVariables()
            .merging(environment, uniquingKeysWith: { $1 })

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        self.outputPipe = outputPipe

        let inputPipe = Pipe()
        process.standardInput = inputPipe
        self.inputPipe = inputPipe

        var continuation: AsyncThrowingStream<Data, Error>.Continuation!
        let contentStream = AsyncThrowingStream<Data, Error> { cont in
            continuation = cont
        }

        Task { [continuation, self] in
            let notificationCenter = NotificationCenter.default
            let notifications = notificationCenter.notifications(
                named: FileHandle.readCompletionNotification,
                object: outputPipe.fileHandleForReading
            )
            for await notification in notifications {
                let userInfo = notification.userInfo
                if let output = userInfo?[NSFileHandleNotificationDataItem] as? Data {
                    continuation?.yield(output)
                }
                if !(self.process?.isRunning ?? false) {
                    let reason = self.process?.terminationReason ?? .exit
                    let status = self.process?.terminationStatus ?? 1
                    if let output = (self.process?.standardOutput as? Pipe)?.fileHandleForReading
                        .readDataToEndOfFile() {
                        continuation?.yield(output)
                    }

                    if status == 0 {
                        continuation?.finish()
                    } else {
                        continuation?.finish(throwing: TerminationError(
                            reason: reason,
                            status: status
                        ))
                    }
                    break
                }
                Task { @MainActor in
                    outputPipe.fileHandleForReading.readInBackgroundAndNotify(forModes: [.common])
                }
            }
        }

        Task { @MainActor in
            outputPipe.fileHandleForReading.readInBackgroundAndNotify(forModes: [.common])
        }

        do {
            try process.run()
        } catch {
            continuation.finish(throwing: error)
        }

        return contentStream
    }

    func runCommand(
        _ command: String = "/bin/bash",
        arguments: [String],
        currentDirectoryPath: String = "/",
        environment: [String: String] = [:]
    )
    async throws -> String {
        let process = Process()
        process.launchPath = command
        process.currentDirectoryPath = currentDirectoryPath
        process.arguments = arguments
        process.environment = getEnvironmentVariables()
            .merging(environment, uniquingKeysWith: { $1 })

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        self.outputPipe = outputPipe

        let inputPipe = Pipe()
        process.standardInput = inputPipe
        self.inputPipe = inputPipe

        return try await withUnsafeThrowingContinuation { continuation in
            do {
                process.terminationHandler = { process in
                    do {
                        if let data = try outputPipe.fileHandleForReading.readToEnd(),
                           let content = String(data: data, encoding: .utf8) {
                            if process.terminationStatus == 0 {
                                continuation.resume(returning: content)
                            } else {
                                struct LocalizedTerminationError: Error, LocalizedError {
                                    let terminationError: TerminationError
                                    let errorDescription: String?
                                }
                                continuation.resume(throwing: LocalizedTerminationError(
                                    terminationError: .init(
                                        reason: process.terminationReason,
                                        status: process.terminationStatus
                                    ),
                                    errorDescription: content
                                ))
                            }
                            return
                        }
                        continuation.resume(returning: "")
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func writeInput(_ input: String) {
        guard let data = input.data(using: .utf8) else {
            return
        }

        inputPipe?.fileHandleForWriting.write(data)
        inputPipe?.fileHandleForWriting.closeFile()
    }

    func terminate() async {
        process?.terminate()
        process = nil
    }

    func getEnvironmentVariables() -> [String: String] {
        let env = ProcessInfo.processInfo.environment
            .merging(["LANG": "en_US.UTF-8"], uniquingKeysWith: { $1 })
        return env
    }
}
