#!/usr/bin/swift

import Foundation

let progname = URL(fileURLWithPath: CommandLine.arguments[0]).lastPathComponent

func warn(_ message: String, when: Bool = true) {
    guard when else { return }
    fputs("\(message)\n", stderr)
}

func warnx(_ message: String, when: Bool = true) {
    warn("\(progname): \(message)", when: when)
}

func usage() {
    warn("usage: \(progname) [-v] [-0] [--] [files...]")
    warn("  -v: Verbose output")
    warn("  -0: Expect NUL ('\\0')-terminated filename strings on stdin")
    warn("  --: End of options processing; all subsequent arguments are files")
    exit(1)
}

func isInputAvailable() -> Bool {
    var pollFD = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
    return poll(&pollFD, 1, 0) > 0 && (pollFD.revents & Int16(POLLIN)) != 0
}

struct InputSplitter: IteratorProtocol {
    enum Separator: UInt8 { case NUL = 0, LF = 10 }
    let separator: Separator
    var buffer = Data(capacity: Int(PATH_MAX))

    mutating func result() -> String? {
        defer { buffer.removeAll(keepingCapacity: true) }
        return buffer.isEmpty ? nil : String(data: buffer, encoding: .utf8)
    }
    mutating func next() -> String? {
        var char: UInt8 = 0
        while read(STDIN_FILENO, &char, 1) == 1 {
            if char == separator.rawValue {
                return result()
            }
            buffer.append(char)
        }
        return result()
    }
}

func lastComponentLower(for url: URL) -> URL {
    return url.deletingLastPathComponent().appendingPathComponent(url.lastPathComponent.lowercased())
}

func canonicalizePath(for url: URL) throws -> String? {
    do {
        let resourceValues = try url.resourceValues(forKeys: [.canonicalPathKey])
        return resourceValues.canonicalPath
    } catch let error as NSError where error.code == NSFileReadNoSuchFileError {
        return nil
    } catch {
        throw error
    }
}

var nullSeparated = false
var fileArguments = false
var verbose = false

var args = CommandLine.arguments.dropFirst()
loop: while let arg = args.first, arg.starts(with: "-") {
    args = args.dropFirst()

    switch arg {
    case "-v":
        verbose = true
    case "-0":
        nullSeparated = true
    case "--":
        fileArguments = true
        break loop
    default:
        warnx("invalid option: \(arg)")
        usage()
    }
}

if !(fileArguments || args.isEmpty) {
    fileArguments = true
    warnx("ignoring input on stdin due to file arguments", when: isInputAvailable())
}
warnx("ignoring -0 option due to file arguments", when: fileArguments && nullSeparated)

let urls = (fileArguments
            ? AnySequence(args)
            : AnySequence { InputSplitter(separator: nullSeparated ? .NUL : .LF) })
              .compactMap { URL(fileURLWithPath: $0).absoluteURL }

for url in urls {
    let newUrl = lastComponentLower(for: url)

    do {
        if try canonicalizePath(for: url) != url.path {
            warnx("skipped \(url.path): exact path not found")
            continue
        }

        if url == newUrl {
            warnx("skipped \(url.path): no change", when: verbose)
            continue
        }

        try FileManager.default.moveItem(at: url, to: newUrl)

        if verbose {
            print("\(url.path) -> \(newUrl.path)")
        }
    } catch let error as NSError where error.code == NSFileWriteFileExistsError {
        warnx("skipped \(url.path): existing file at \(newUrl.path)")
    } catch {
        warnx("error for \(url.path): \(error.localizedDescription)")
    }
}
