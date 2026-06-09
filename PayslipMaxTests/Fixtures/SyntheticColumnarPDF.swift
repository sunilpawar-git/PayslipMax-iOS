import CoreGraphics
import Foundation

/// Builds tiny, **PII-free** PDFs with hand-authored content streams so the production
/// `CGPDFTokenExtractor` can be exercised deterministically in CI — no real officer slips,
/// no `characterBounds`, no network. Coordinates mirror the plan's real columnar geometry
/// (credit/debit label + amount X-bands) but carry only synthetic, redacted-identity values.
///
/// The assembler emits a minimal but spec-valid PDF (correct `xref` byte offsets + trailer)
/// so `CGPDFDocument` opens it the same way it opens a real slip.
enum SyntheticColumnarPDF {
    /// One placed text token: a string drawn at a baseline-left origin in page points.
    struct Token {
        let text: String
        let x: CGFloat
        let y: CGFloat
        let fontSize: CGFloat

        init(_ text: String, x: CGFloat, y: CGFloat, fontSize: CGFloat = 10) {
            self.text = text
            self.x = x
            self.y = y
            self.fontSize = fontSize
        }
    }

    // MARK: - Page specs

    /// A page whose tokens are drawn directly in the page content stream.
    static func page(_ tokens: [Token]) -> Page {
        Page(tokens: tokens, wrapInForm: false)
    }

    /// A page whose tokens are wrapped in a single Form XObject (drawn via `Do`),
    /// exercising the extractor's Form-XObject recursion. `matrix` is the form `/Matrix`
    /// (defaults to identity); tokens are positioned in form space.
    static func formPage(_ tokens: [Token], matrix: [CGFloat] = [1, 0, 0, 1, 0, 0]) -> Page {
        Page(tokens: tokens, wrapInForm: true, formMatrix: matrix)
    }

    struct Page {
        let tokens: [Token]
        let wrapInForm: Bool
        var formMatrix: [CGFloat] = [1, 0, 0, 1, 0, 0]
    }

    // MARK: - Document assembly

    /// Assembles `pages` into a single-document `Data` blob and a `CGPDFDocument`.
    static func document(_ pages: [Page]) -> CGPDFDocument? {
        let data = data(pages)
        guard let provider = CGDataProvider(data: data as CFData) else {
            return nil
        }
        return CGPDFDocument(provider)
    }

    /// Raw PDF bytes for `pages`.
    static func data(_ pages: [Page]) -> Data {
        var objects: [String] = []
        // Reserve obj 1 (catalog) and obj 2 (pages tree); page/content/form objects follow.
        objects.append("")  // placeholder 1 (catalog)
        objects.append("")  // placeholder 2 (pages)
        let fontObjNumber = 3
        objects.append("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")

        var pageObjNumbers: [Int] = []
        for spec in pages {
            appendPageObjects(spec, fontObjNumber: fontObjNumber, into: &objects, pageNumbers: &pageObjNumbers)
        }

        let kids = pageObjNumbers.map { "\($0) 0 R" }.joined(separator: " ")
        objects[0] = "<< /Type /Catalog /Pages 2 0 R >>"
        objects[1] = "<< /Type /Pages /Kids [\(kids)] /Count \(pageObjNumbers.count) >>"

        return assemble(objects: objects, rootObjectNumber: 1)
    }

    // MARK: - Per-page object construction

    private static func appendPageObjects(
        _ spec: Page,
        fontObjNumber: Int,
        into objects: inout [String],
        pageNumbers: inout [Int]
    ) {
        let body = contentStreamBody(for: spec)
        if spec.wrapInForm {
            let formNumber = objects.count + 1
            objects.append(streamObject(formBody(spec), dictExtra: formDict(spec, fontObjNumber: fontObjNumber)))
            let pageContentNumber = objects.count + 1
            objects.append(streamObject(body))
            let pageNumber = objects.count + 1
            let resources = "<< /XObject << /Fm0 \(formNumber) 0 R >> "
                + "/Font << /F1 \(fontObjNumber) 0 R >> >>"
            objects.append(pageObject(contentNumber: pageContentNumber, resources: resources))
            pageNumbers.append(pageNumber)
        } else {
            let pageContentNumber = objects.count + 1
            objects.append(streamObject(body))
            let pageNumber = objects.count + 1
            let resources = "<< /Font << /F1 \(fontObjNumber) 0 R >> >>"
            objects.append(pageObject(contentNumber: pageContentNumber, resources: resources))
            pageNumbers.append(pageNumber)
        }
    }

    private static func pageObject(contentNumber: Int, resources: String) -> String {
        "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] "
            + "/Resources \(resources) /Contents \(contentNumber) 0 R >>"
    }

    /// Page content: either the tokens themselves, or a single `Do` invoking the form.
    private static func contentStreamBody(for spec: Page) -> String {
        spec.wrapInForm ? "/Fm0 Do" : tokenOps(spec.tokens)
    }

    private static func formBody(_ spec: Page) -> String {
        tokenOps(spec.tokens)
    }

    private static func formDict(_ spec: Page, fontObjNumber: Int) -> String {
        let matrix = spec.formMatrix.map { trim($0) }.joined(separator: " ")
        return " /Type /XObject /Subtype /Form /BBox [0 0 595 842] /Matrix [\(matrix)] "
            + "/Resources << /Font << /F1 \(fontObjNumber) 0 R >> >>"
    }

    /// One `BT … Tm … Tj ET` block per token.
    private static func tokenOps(_ tokens: [Token]) -> String {
        tokens.map { token in
            "BT /F1 \(trim(token.fontSize)) Tf 1 0 0 1 \(trim(token.x)) \(trim(token.y)) Tm "
                + "(\(escape(token.text))) Tj ET"
        }.joined(separator: "\n")
    }

    // MARK: - Low-level PDF encoding

    private static func streamObject(_ content: String, dictExtra: String = "") -> String {
        "<< /Length \(content.utf8.count)\(dictExtra) >>\nstream\n\(content)\nendstream"
    }

    private static func assemble(objects: [String], rootObjectNumber: Int) -> Data {
        var pdf = "%PDF-1.4\n"
        var offsets: [Int] = []
        for (index, body) in objects.enumerated() {
            offsets.append(pdf.utf8.count)
            pdf += "\(index + 1) 0 obj\n\(body)\nendobj\n"
        }
        let xrefOffset = pdf.utf8.count
        pdf += "xref\n0 \(objects.count + 1)\n"
        pdf += "0000000000 65535 f \n"
        for offset in offsets {
            pdf += String(format: "%010d 00000 n \n", offset)
        }
        pdf += "trailer\n<< /Size \(objects.count + 1) /Root \(rootObjectNumber) 0 R >>\n"
        pdf += "startxref\n\(xrefOffset)\n%%EOF\n"
        return Data(pdf.utf8)
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "(", with: "\\(")
            .replacingOccurrences(of: ")", with: "\\)")
    }

    /// Formats a coordinate without a trailing `.0` so the content stream stays compact.
    private static func trim(_ value: CGFloat) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }
}
