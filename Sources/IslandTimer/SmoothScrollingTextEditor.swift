import AppKit
import QuartzCore
import SwiftUI

struct SmoothScrollingTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var scrollY: CGFloat

    init(text: Binding<String>, scrollY: Binding<CGFloat> = .constant(0)) {
        _text = text
        _scrollY = scrollY
    }

    final class Coordinator {
        var didApplyInitialScrollPosition = false
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSView(context: Context) -> SmoothScrollingTextEditorView {
        let view = SmoothScrollingTextEditorView()
        view.onTextChange = { newText in
            if self.text != newText {
                self.text = newText
            }
        }
        view.onScrollYChange = { y in
            if abs(self.scrollY - y) > 0.5 {
                self.scrollY = y
            }
        }
        view.setText(text)
        return view
    }
    
    func updateNSView(_ nsView: SmoothScrollingTextEditorView, context: Context) {
        nsView.setText(text)
        if !context.coordinator.didApplyInitialScrollPosition {
            context.coordinator.didApplyInitialScrollPosition = true
            let y = scrollY
            DispatchQueue.main.async {
                nsView.setScrollY(y)
            }
        }
    }
}

final class ActivatingTextView: NSTextView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    override func mouseDown(with event: NSEvent) {
        NSApp.activate(ignoringOtherApps: true)
        if let window {
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(self)
        }
        super.mouseDown(with: event)
    }
}

final class ActivatingClipView: NSClipView {
    weak var targetTextView: NSTextView?
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    override func mouseDown(with event: NSEvent) {
        NSApp.activate(ignoringOtherApps: true)
        if let window {
            window.makeKeyAndOrderFront(nil)
            if let targetTextView {
                window.makeFirstResponder(targetTextView)
            }
        }
        super.mouseDown(with: event)
    }
}

final class SmoothScrollingTextEditorView: NSView, NSTextViewDelegate {
    var onTextChange: ((String) -> Void)?
    var onScrollYChange: ((CGFloat) -> Void)?
    
    private let scrollView: SmoothScrollView
    private let textView: ActivatingTextView
    private var boundsObserver: NSObjectProtocol?
    
    override init(frame frameRect: NSRect) {
        self.scrollView = SmoothScrollView()
        self.textView = ActivatingTextView()
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        self.scrollView = SmoothScrollView()
        self.textView = ActivatingTextView()
        super.init(coder: coder)
        setup()
    }

    deinit {
        if let boundsObserver {
            NotificationCenter.default.removeObserver(boundsObserver)
        }
    }
    
    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        
        textView.delegate = self
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.focusRingType = .none
        textView.font = .systemFont(ofSize: 14, weight: .regular)
        textView.textColor = .labelColor
        textView.insertionPointColor = .labelColor
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        
        let clipView = ActivatingClipView()
        clipView.targetTextView = textView
        clipView.postsBoundsChangedNotifications = true
        scrollView.contentView = clipView
        
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = textView
        
        addSubview(scrollView)

        boundsObserver = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: clipView,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.onScrollYChange?(self.scrollView.contentView.bounds.origin.y)
        }
    }
    
    override func layout() {
        super.layout()
        scrollView.frame = bounds
        if textView.frame.size.width != bounds.width || textView.frame.size.height < bounds.height {
            textView.frame = NSRect(origin: .zero, size: bounds.size)
        }
    }
    
    func textDidChange(_ notification: Notification) {
        onTextChange?(textView.string)
    }
    
    func setText(_ newText: String) {
        guard textView.string != newText else { return }
        let selectedRange = textView.selectedRange()
        textView.string = newText
        textView.setSelectedRange(selectedRange)
    }

    func setScrollY(_ y: CGFloat) {
        guard let docView = scrollView.documentView else {
            scrollView.contentView.setBoundsOrigin(NSPoint(x: 0, y: y))
            scrollView.reflectScrolledClipView(scrollView.contentView)
            return
        }

        let visibleHeight = scrollView.contentView.bounds.height
        let documentHeight = docView.bounds.height
        let maxY = max(0, documentHeight - visibleHeight)
        let clampedY = max(0, min(maxY, y))

        scrollView.contentView.setBoundsOrigin(NSPoint(x: 0, y: clampedY))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
}

final class SmoothScrollView: NSScrollView {
    private var pendingTargetY: CGFloat?
    private var isAnimating = false
    
    override func scrollWheel(with event: NSEvent) {
        guard let docView = documentView else {
            super.scrollWheel(with: event)
            return
        }
        
        let visibleHeight = contentView.bounds.height
        let documentHeight = docView.bounds.height
        guard documentHeight > visibleHeight + 1 else {
            super.scrollWheel(with: event)
            return
        }
        
        let multiplier: CGFloat = event.hasPreciseScrollingDeltas ? 1.0 : 12.0
        let distance = (-event.scrollingDeltaY) * multiplier
        
        let currentY = contentView.bounds.origin.y
        let maxY = max(0, documentHeight - visibleHeight)
        let targetY = clamp(currentY + distance, min: 0, max: maxY)
        
        animateScroll(to: targetY)
    }
    
    private func animateScroll(to targetY: CGFloat) {
        if isAnimating {
            pendingTargetY = targetY
            return
        }
        
        let currentY = contentView.bounds.origin.y
        let distance = abs(targetY - currentY)
        
        let speed: CGFloat = 900
        let duration = clamp(distance / speed, min: 0.08, max: 0.35)
        
        isAnimating = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .linear)
            contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: targetY))
        } completionHandler: { [weak self] in
            guard let self else { return }
            self.isAnimating = false
            if let pendingTargetY = self.pendingTargetY {
                self.pendingTargetY = nil
                self.animateScroll(to: pendingTargetY)
            }
        }
    }
    
    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.max(min, Swift.min(max, value))
    }
}
