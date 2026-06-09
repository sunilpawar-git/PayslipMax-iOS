import CoreGraphics
import Foundation

// swiftlint:disable no_hardcoded_strings
// PDF content-stream operator names and dictionary keys are fixed by the PDF spec
// (ISO 32000) — they are not user-facing strings.

// MARK: - Content-stream operator callbacks
//
// `CGPDFScanner` invokes C-convention callbacks; the mutable `CGPDFTokenScanState` is
// recovered from the opaque `info` pointer. Names mirror the PDF operators they implement.
// This is the production port of the Phase 0.5 spike's `PDFTextOps`.

private func scanState(_ info: UnsafeMutableRawPointer?) -> CGPDFTokenScanState {
    guard let info else {
        preconditionFailure("CGPDFScanner invoked without info pointer")
    }
    return Unmanaged<CGPDFTokenScanState>.fromOpaque(info).takeUnretainedValue()
}

private func popNumbers(_ scanner: CGPDFScannerRef, _ count: Int) -> [CGFloat] {
    var out = [CGFloat](repeating: 0, count: count)
    for index in stride(from: count - 1, through: 0, by: -1) {
        var value: CGPDFReal = 0
        guard CGPDFScannerPopNumber(scanner, &value) else {
            return []
        }
        out[index] = CGFloat(value)
    }
    return out
}

private func decode(_ str: CGPDFStringRef) -> String {
    guard let ptr = CGPDFStringGetBytePtr(str) else {
        return ""
    }
    let bytes = UnsafeBufferPointer(start: ptr, count: CGPDFStringGetLength(str))
    return String(bytes: bytes, encoding: .isoLatin1) ?? ""
}

private func popString(_ scanner: CGPDFScannerRef) -> String {
    var ref: CGPDFStringRef?
    guard CGPDFScannerPopString(scanner, &ref), let str = ref else {
        return ""
    }
    return decode(str)
}

private func affine(_ nums: [CGFloat]) -> CGAffineTransform {
    CGAffineTransform(a: nums[0], b: nums[1], c: nums[2], d: nums[3], tx: nums[4], ty: nums[5])
}

private func moveLine(_ scan: CGPDFTokenScanState, _ tx: CGFloat, _ ty: CGFloat) {
    scan.lineMatrix = CGAffineTransform(translationX: tx, y: ty).concatenating(scan.lineMatrix)
    scan.textMatrix = scan.lineMatrix
}

/// Namespace of `CGPDFOperatorCallback`s + the operator table (avoids top-level constants).
enum CGPDFTextOperators {
    static let concatMatrix: CGPDFOperatorCallback = { scanner, info in
        let nums = popNumbers(scanner, 6)
        guard nums.count == 6 else {
            return
        }
        let scan = scanState(info)
        scan.ctm = affine(nums).concatenating(scan.ctm)
    }
    static let saveState: CGPDFOperatorCallback = { _, info in
        let scan = scanState(info); scan.ctmStack.append(scan.ctm)
    }
    static let restoreState: CGPDFOperatorCallback = { _, info in
        let scan = scanState(info); if let top = scan.ctmStack.popLast() { scan.ctm = top }
    }
    static let beginText: CGPDFOperatorCallback = { _, info in
        let scan = scanState(info); scan.textMatrix = .identity; scan.lineMatrix = .identity
    }
    static let setTextMatrix: CGPDFOperatorCallback = { scanner, info in
        let nums = popNumbers(scanner, 6)
        guard nums.count == 6 else {
            return
        }
        let scan = scanState(info)
        scan.textMatrix = affine(nums)
        scan.lineMatrix = scan.textMatrix
    }
    static let nextLineOffset: CGPDFOperatorCallback = { scanner, info in
        let nums = popNumbers(scanner, 2)
        guard nums.count == 2 else {
            return
        }
        moveLine(scanState(info), nums[0], nums[1])
    }
    static let nextLineLeading: CGPDFOperatorCallback = { scanner, info in
        let nums = popNumbers(scanner, 2)
        guard nums.count == 2 else {
            return
        }
        let scan = scanState(info); scan.leading = -nums[1]; moveLine(scan, nums[0], nums[1])
    }
    static let setLeading: CGPDFOperatorCallback = { scanner, info in
        let nums = popNumbers(scanner, 1); if let value = nums.first { scanState(info).leading = value }
    }
    static let nextLine: CGPDFOperatorCallback = { _, info in
        let scan = scanState(info); moveLine(scan, 0, -scan.leading)
    }
    static let showText: CGPDFOperatorCallback = { scanner, info in
        scanState(info).show(popString(scanner))
    }
    static let nextLineShow: CGPDFOperatorCallback = { scanner, info in
        let scan = scanState(info); moveLine(scan, 0, -scan.leading); scan.show(popString(scanner))
    }
    static let showArray: CGPDFOperatorCallback = { scanner, info in
        var arrayRef: CGPDFArrayRef?
        guard CGPDFScannerPopArray(scanner, &arrayRef), let array = arrayRef else {
            return
        }
        var text = ""
        for index in 0..<CGPDFArrayGetCount(array) {
            var ref: CGPDFStringRef?
            if CGPDFArrayGetString(array, index, &ref), let str = ref {
                text += decode(str)
            }
        }
        scanState(info).show(text)
    }
    /// Resolve the named XObject; if it is a Form, apply its `/Matrix` and recursively scan
    /// its content stream (several officer layouts wrap the whole table in one form).
    static let drawXObject: CGPDFOperatorCallback = { scanner, info in
        let scan = scanState(info)
        guard scan.depth < 12, let parent = scan.streamStack.last else {
            return
        }
        var nameRef: UnsafePointer<Int8>?
        guard CGPDFScannerPopName(scanner, &nameRef), let name = nameRef else {
            return
        }
        guard let xobject = CGPDFContentStreamGetResource(parent, "XObject", name) else {
            return
        }
        var stream: CGPDFStreamRef?
        guard CGPDFObjectGetValue(xobject, .stream, &stream), let formStream = stream else {
            return
        }
        guard let dict = CGPDFStreamGetDictionary(formStream), isForm(dict) else {
            return
        }
        runForm(scan, formStream, dict, parent)
    }

    private static func isForm(_ dict: CGPDFDictionaryRef) -> Bool {
        var subtype: UnsafePointer<Int8>?
        guard CGPDFDictionaryGetName(dict, "Subtype", &subtype), let sub = subtype else {
            return true   // no Subtype: treat as form (scan it)
        }
        return String(cString: sub) == "Form"
    }

    private static func formMatrix(_ dict: CGPDFDictionaryRef) -> CGAffineTransform? {
        var matrixRef: CGPDFArrayRef?
        let hasMatrix = CGPDFDictionaryGetArray(dict, "Matrix", &matrixRef)
        guard hasMatrix, let array = matrixRef, CGPDFArrayGetCount(array) == 6 else {
            return nil
        }
        var nums = [CGFloat](repeating: 0, count: 6)
        for index in 0..<6 {
            var value: CGPDFReal = 0
            CGPDFArrayGetNumber(array, index, &value)
            nums[index] = CGFloat(value)
        }
        return affine(nums)
    }

    private static func runForm(
        _ scan: CGPDFTokenScanState,
        _ formStream: CGPDFStreamRef,
        _ dict: CGPDFDictionaryRef,
        _ parent: CGPDFContentStreamRef
    ) {
        let saved = scan.ctm
        if let matrix = formMatrix(dict) {
            scan.ctm = matrix.concatenating(scan.ctm)
        }
        var formResources: CGPDFDictionaryRef?
        CGPDFDictionaryGetDictionary(dict, "Resources", &formResources)
        guard let resources = formResources ?? scan.fallbackResources else {
            scan.ctm = saved
            return
        }
        let child = CGPDFContentStreamCreateWithStream(formStream, resources, parent)
        scan.depth += 1
        scan.streamStack.append(child)
        let nested = CGPDFScannerCreate(child, scan.table, Unmanaged.passUnretained(scan).toOpaque())
        CGPDFScannerScan(nested)
        CGPDFScannerRelease(nested)
        CGPDFContentStreamRelease(child)
        scan.streamStack.removeLast()
        scan.depth -= 1
        scan.ctm = saved
    }

    static func table() -> CGPDFOperatorTableRef {
        guard let table = CGPDFOperatorTableCreate() else {
            preconditionFailure("CGPDFOperatorTableCreate returned nil")
        }
        let ops: [(String, CGPDFOperatorCallback)] = [
            ("cm", concatMatrix), ("q", saveState), ("Q", restoreState), ("BT", beginText),
            ("Tm", setTextMatrix), ("Td", nextLineOffset), ("TD", nextLineLeading),
            ("TL", setLeading), ("T*", nextLine), ("Tj", showText), ("'", nextLineShow),
            ("TJ", showArray), ("Do", drawXObject)
        ]
        for (name, callback) in ops { CGPDFOperatorTableSetCallback(table, name, callback) }
        return table
    }
}

// swiftlint:enable no_hardcoded_strings
