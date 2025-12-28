import Foundation

// MARK: - Private Methods

extension UniversalPayCodeSearchEngine {

    /// Searches for a specific pay code everywhere in the text
    func searchPayCodeEverywhere(code: String, in text: String) async -> [PayCodeSearchResult]? {
        var results: [PayCodeSearchResult] = []

        let isCriticalCode = ["DA", "RH12", "RH11", "RH13"].contains(code.uppercased())
        if isCriticalCode && !ProcessInfo.isRunningInTestEnvironment {
            print("[DEBUG] searchPayCodeEverywhere: code=\(code)")
            print("[DEBUG]   Text sample: \(String(text.prefix(300))...)")
        }

        let patterns = patternGenerator.generatePayCodePatterns(for: code)

        if isCriticalCode && !ProcessInfo.isRunningInTestEnvironment {
            print("[DEBUG]   Generated \(patterns.count) patterns for \(code)")
        }

        for (patternIndex, pattern) in patterns.enumerated() {
            let matches = extractPatternMatches(pattern: pattern, from: text)

            if isCriticalCode && !ProcessInfo.isRunningInTestEnvironment {
                print("[DEBUG]   Pattern[\(patternIndex)]: found \(matches.count) matches")
            }

            for match in matches {
                let classification = classificationEngine.classifyComponentIntelligently(
                    component: code,
                    value: match.value,
                    context: match.context
                )

                if isCriticalCode && !ProcessInfo.isRunningInTestEnvironment {
                    let debugMsg = "[DEBUG] value=₹\(match.value) section=\(classification.section) confidence=\(classification.confidence)"
                    print(debugMsg)
                }

                let result = PayCodeSearchResult(
                    value: match.value,
                    section: classification.section,
                    confidence: classification.confidence,
                    context: match.context,
                    isDualSection: classification.isDualSection
                )

                results.append(result)
            }
        }

        if isCriticalCode && !ProcessInfo.isRunningInTestEnvironment {
            print("[DEBUG]   Total results for \(code): \(results.count)")
        }

        return results.isEmpty ? nil : results
    }

    /// Relaxed line-based extraction for noisy OCR: looks for labels and the nearest numeric value
    func extractRelaxedLineMatches(from text: String) -> [String: PayCodeSearchResult] {
        let targets: [(code: String, labels: [String])] = [
            ("BPAY", ["BAND PAY", "BPAY", "BASIC PAY"]),
            ("MSP", ["MS PAY", "MSP", "MILITARY SERVICE PAY"]),
            ("DA", ["DA", "DEARNESS ALLOWANCE"]),
            ("DSOP", ["DSOP", "DSOP/AFPP", "PF", "PROVIDENT FUND", "AFPP"]),
            ("ITAX", ["ITAX", "INCOME TAX", "INCOME TAX / EC"]),
            ("AGIF", ["AGIF", "ARMY GROUP INSURANCE"])
        ]

        let lines = text.components(separatedBy: .newlines)
        var results: [String: PayCodeSearchResult] = [:]

        for (idx, line) in lines.enumerated() {
            let normalized = line.uppercased()
            for target in targets {
                if target.labels.contains(where: { normalized.contains($0) }) {
                    if let value = extractNearestNumber(from: lines, startingAt: idx, lookahead: 4) {
                        let classification = classificationEngine.classifyComponentIntelligently(
                            component: target.code,
                            value: value,
                            context: "relaxed-line-scan"
                        )
                        results[target.code] = PayCodeSearchResult(
                            value: value,
                            section: classification.section,
                            confidence: max(0.55, classification.confidence),
                            context: "relaxed-line-scan",
                            isDualSection: classification.isDualSection
                        )
                    }
                }
            }
        }

        return results
    }

    /// Finds the nearest numeric value on the same line or up to lookahead lines ahead (tolerates spaces/commas)
    func extractNearestNumber(from lines: [String], startingAt index: Int, lookahead: Int) -> Double? {
        var candidates: [String] = []
        for offset in 0...lookahead {
            let i = index + offset
            if i < lines.count { candidates.append(lines[i]) }
        }
        for candidate in candidates {
            if let amount = extractNumber(from: candidate) {
                return amount
            }
        }
        return nil
    }

    /// Cross-line sweep: matches labels followed by numbers across line breaks/spaces
    func extractCrossLineMatches(from text: String) -> [String: PayCodeSearchResult] {
        let targets: [(code: String, pattern: String)] = [
            ("BPAY", #"(?is)(BAND\s+PAY|BPAY|BASIC\s+PAY)[^0-9]{0,120}?[₹Rs\.\s]*([0-9][0-9\ ,]{0,20}[0-9](?:\.\d{1,2})?)"#),
            ("MSP", #"(?is)(MS\s+PAY|MSP|MILITARY\s+SERVICE\s+PAY)[^0-9]{0,120}?[₹Rs\.\s]*([0-9][0-9\ ,]{0,20}[0-9](?:\.\d{1,2})?)"#),
            ("DA", #"(?is)(DA|DEARNESS\s+ALLOWANCE)[^0-9]{0,120}?[₹Rs\.\s]*([0-9][0-9\ ,]{0,20}[0-9](?:\.\d{1,2})?)"#),
            ("DSOP", #"(?is)(DSOP|DSOP/AFPP|PF|PROVIDENT\s+FUND|AFPP)[^0-9]{0,120}?[₹Rs\.\s]*([0-9][0-9\ ,]{0,20}[0-9](?:\.\d{1,2})?)"#),
            ("ITAX", #"(?is)(ITAX|INCOME\s+TAX|INCOME\s+TAX\s*/\s*EC|INCOME\s*TAX\s*EC)[^0-9]{0,120}?[₹Rs\.\s]*([0-9][0-9\ ,]{0,20}[0-9](?:\.\d{1,2})?)"#),
            ("AGIF", #"(?is)(AGIF|ARMY\s+GROUP\s+INSURANCE)[^0-9]{0,120}?[₹Rs\.\s]*([0-9][0-9\ ,]{0,20}[0-9](?:\.\d{1,2})?)"#)
        ]

        var results: [String: PayCodeSearchResult] = [:]

        for target in targets {
            guard let regex = try? NSRegularExpression(pattern: target.pattern, options: []) else { continue }
            let nsText = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
            if let match = matches.first, match.numberOfRanges >= 3 {
                let amountRange = match.range(at: 2)
                if let range = Range(amountRange, in: text) {
                    let raw = String(text[range])
                    let clean = raw.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "")
                    if let value = Double(clean) {
                        let classification = classificationEngine.classifyComponentIntelligently(
                            component: target.code,
                            value: value,
                            context: "crossline-scan"
                        )
                        results[target.code] = PayCodeSearchResult(
                            value: value,
                            section: classification.section,
                            confidence: max(0.6, classification.confidence),
                            context: "crossline-scan",
                            isDualSection: classification.isDualSection
                        )
                    }
                }
            }
        }

        return results
    }

    func extractNumber(from text: String) -> Double? {
        let pattern = #"([0-9][0-9\ ,]{0,20}[0-9](?:\.\d{1,2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           let amountRange = Range(match.range(at: 1), in: text) {
            let raw = String(text[amountRange])
            let clean = raw.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "")
            return Double(clean)
        }
        return nil
    }

    /// Searches for universal arrears patterns with enhanced classification
    func searchUniversalArrearsPatterns(in text: String) async -> [String: PayCodeSearchResult] {
        var arrearsResults: [String: PayCodeSearchResult] = [:]

        let universalArrearsPatterns = patternGenerator.generateUniversalArrearsPatterns()

        for pattern in universalArrearsPatterns {
            let matches = extractUniversalArrearsMatches(pattern: pattern, from: text)
            for match in matches {
                let arrearsCode = "ARR-\(match.component)"

                let baseComponentClassification = classificationEngine.classifyComponent(match.component)
                let classification = classificationEngine.classifyComponentIntelligently(
                    component: arrearsCode,
                    value: match.value,
                    context: match.context
                )

                let finalKey: String
                if baseComponentClassification == .universalDualSection {
                    let suffix = classification.section == .earnings ? "_EARNINGS" : "_DEDUCTIONS"
                    finalKey = "\(arrearsCode)\(suffix)"
                } else {
                    finalKey = arrearsCode
                }

                arrearsResults[finalKey] = PayCodeSearchResult(
                    value: match.value,
                    section: classification.section,
                    confidence: classification.confidence,
                    context: match.context,
                    isDualSection: baseComponentClassification == .universalDualSection
                )
            }
        }

        return arrearsResults
    }

    /// Extracts pattern matches with context
    func extractPatternMatches(pattern: String, from text: String) -> [(value: Double, context: String)] {
        var matches: [(value: Double, context: String)] = []

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsText = text as NSString
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

            for result in results where result.numberOfRanges > 1 {
                let amountRange = result.range(at: 1)
                if amountRange.location != NSNotFound {
                    let amountString = nsText.substring(with: amountRange)
                    if let value = parseAmount(amountString) {
                        let contextRange = NSRange(
                            location: max(0, result.range.location - 200),
                            length: min(400, nsText.length - max(0, result.range.location - 200))
                        )
                        let context = nsText.substring(with: contextRange)
                        matches.append((value: value, context: context))
                    }
                }
            }
        } catch {}

        return matches
    }

    /// Extracts universal arrears matches with component identification
    func extractUniversalArrearsMatches(
        pattern: String,
        from text: String
    ) -> [(component: String, value: Double, context: String)] {
        var matches: [(component: String, value: Double, context: String)] = []

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsText = text as NSString
            let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

            for result in results where result.numberOfRanges >= 3 {
                let componentRange = result.range(at: 1)
                let amountRange = result.range(at: 2)

                if componentRange.location != NSNotFound && amountRange.location != NSNotFound {
                    let component = nsText.substring(with: componentRange).uppercased()
                    let amountString = nsText.substring(with: amountRange)

                    if let value = parseAmount(amountString), isKnownMilitaryPayCode(component) {
                        let contextRange = NSRange(
                            location: max(0, result.range.location - 200),
                            length: min(400, nsText.length - max(0, result.range.location - 200))
                        )
                        let context = nsText.substring(with: contextRange)
                        matches.append((component: component, value: value, context: context))
                    }
                }
            }
        } catch {}

        return matches
    }

    /// Parses amount string to double value
    func parseAmount(_ amountString: String) -> Double? {
        let cleanAmount = amountString
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespaces)

        return Double(cleanAmount)
    }
}
