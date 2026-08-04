import SwiftUI
import UIKit
import SolBlockModel
import SolDesignSystem

/// Per-paragraph geometry the gutter needs: y-origin + height of each logical
/// line, in text-view content coordinates.
struct LineFragment: Equatable {
    let lineIndex: Int
    let y: CGFloat
    let height: CGFloat
}

/// TextKit 2 editor surface. Reports text changes, selection, scroll offset
/// and per-line layout fragments (for gutter alignment — wrapped lines get
/// one tag at the paragraph's first fragment, mirroring the Block Model's
/// line-oriented truth).
struct MarkdownTextView: UIViewRepresentable {
    @Binding var text: String
    let onSelectionChange: (NSRange) -> Void
    let onScroll: (CGFloat) -> Void
    let onFragments: ([LineFragment]) -> Void

    func makeUIView(context: Context) -> UITextView {
        // usingTextLayoutManager: true → TextKit 2 (default on iOS 16+, pinned
        // explicitly because the fragment enumeration below depends on it).
        let tv = UITextView(usingTextLayoutManager: true)
        tv.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.backgroundColor = .clear
        tv.autocapitalizationType = .none
        tv.autocorrectionType = .no
        tv.smartQuotesType = .no // markdown markers must stay ASCII
        tv.smartDashesType = .no
        tv.delegate = context.coordinator
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        tv.text = text
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        if tv.text != text {
            let selection = tv.selectedRange
            tv.text = text
            tv.selectedRange = NSRange(location: min(selection.location, (text as NSString).length), length: 0)
        }
        context.coordinator.publishFragments(of: tv)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        private let parent: MarkdownTextView
        private var lastFragments: [LineFragment] = []

        init(_ parent: MarkdownTextView) { self.parent = parent }

        func textViewDidChange(_ tv: UITextView) {
            parent.text = tv.text
            publishFragments(of: tv)
        }

        func textViewDidChangeSelection(_ tv: UITextView) {
            parent.onSelectionChange(tv.selectedRange)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.onScroll(scrollView.contentOffset.y)
        }

        /// Walks TextKit 2 layout fragments; each text paragraph = one logical
        /// line of the Block Model.
        func publishFragments(of tv: UITextView) {
            guard let layoutManager = tv.textLayoutManager,
                  let contentManager = layoutManager.textContentManager else { return }
            var fragments: [LineFragment] = []
            var lineIndex = 0
            layoutManager.enumerateTextLayoutFragments(
                from: layoutManager.documentRange.location,
                options: [.ensuresLayout]
            ) { fragment in
                let frame = fragment.layoutFragmentFrame
                fragments.append(LineFragment(
                    lineIndex: lineIndex,
                    y: frame.origin.y + tv.textContainerInset.top,
                    height: frame.height))
                // A layout fragment covers one paragraph element; advance the
                // logical-line counter by the newlines it spans (offset math —
                // NSTextContentManager has no attributedString(in:) accessor).
                if let paragraph = fragment.textElement,
                   let range = paragraph.elementRange {
                    let start = contentManager.offset(
                        from: layoutManager.documentRange.location, to: range.location)
                    let end = contentManager.offset(
                        from: layoutManager.documentRange.location, to: range.endLocation)
                    if start >= 0, end > start, end <= (tv.text as NSString).length {
                        let s = (tv.text as NSString).substring(
                            with: NSRange(location: start, length: end - start))
                        lineIndex += max(1, s.filter { $0 == "\n" }.count)
                    } else {
                        lineIndex += 1
                    }
                } else {
                    lineIndex += 1
                }
                return true
            }
            if fragments != lastFragments {
                lastFragments = fragments
                parent.onFragments(fragments)
            }
        }
    }
}
