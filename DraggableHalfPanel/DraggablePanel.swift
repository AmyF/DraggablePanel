//
//  DraggablePanel.swift
//  DraggableHalfPanel
//
//  Created by Huang Feida on 21/10/2022.
//

import UIKit

protocol DraggableViewController: UIViewController {
    var dragHeight: DraggablePanelViewController.DragHeight { get }
    var draggableView: UIView { get }
}

protocol DraggableRootViewController: UIViewController {
    var scrollView: UIScrollView? { get }
}

class DraggablePanelViewController: UIViewController {
    // MARK: - properties
    var usingMaxDragHeightWhenInit: Bool {
        true
    }
    
    var attachEdge: Bool {
        true
    }
    
    var needLinkRootScrollView: Bool {
        true
    }
    
    var offsetOfDetectTopOffset: CGFloat {
        0
    }
    
    var offsetOfDetectBottomOffset: CGFloat {
        0
    }
    
    var durationOfDraggableViewAnimation: CGFloat {
        0.25
    }
    
    var rootViewController: DraggableRootViewController {
        fatalError()
    }
    
    var dragViewController: DraggableViewController {
        fatalError()
    }
    
    private var beforeDragContentHeight: CGFloat = 0
    
    private var offsetChangedObz: NSKeyValueObservation?
    private var isAnimatingDetectEdgeOffset: Bool = false
    
    deinit {
        offsetChangedObz?.invalidate()
        offsetChangedObz = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        addPanGestureRecognizer()
        setupInitDragHeight()
        linkRootScrollViewIfNeed()
    }
}

extension DraggablePanelViewController {
    private func linkRootScrollViewIfNeed() {
        guard needLinkRootScrollView, attachEdge, let scrollView = rootViewController.scrollView else {
            return
        }
        offsetChangedObz = scrollView.observe(\.contentOffset, options: [.new, .old]) { [weak self] scrollView, changed in
            guard let self = self else {
                return
            }
            if self.isScrollToTop(in: scrollView) {
                self.updateDragViewHeight(self.getMaxDragViewControllerHeight(), animated: true)
                return
            }
            if self.isScrollToBottom(in: scrollView) {
                self.updateDragViewHeight(self.getMinDragViewControllerHeight(), animated: true)
                return
            }
            
            if let offset = self.calculateDragDownScrollOffset(changed: changed) {
                self.dragDownViewController(offset: offset)
                return
            }
        }
    }
    
    private func isScrollToBottom(in scrollView: UIScrollView) -> Bool {
        scrollView.contentOffset.y + scrollView.bounds.height >= scrollView.contentSize.height - self.offsetOfDetectBottomOffset
    }
    
    private func isScrollToTop(in scrollView: UIScrollView) -> Bool {
        scrollView.contentOffset.y <= self.offsetOfDetectTopOffset
    }
    
    private func calculateDragDownScrollOffset(changed: NSKeyValueObservedChange<CGPoint>) -> CGFloat? {
        guard let newValue = changed.newValue?.y, let oldValue = changed.oldValue?.y else {
            return nil
        }
        let offset = newValue - oldValue
        if offset > 0 {
            return offset
        } else {
            return nil
        }
    }
    
    private func dragDownViewController(offset: CGFloat) {
        updateDragViewHeight(
            limiteHeight(
                dragViewController.view.bounds.height - offset,
                tolerance: false
            ),
            animated: false
        )
    }
}

// MARK: - ui
extension DraggablePanelViewController {
    private func setupLayout() {
        addChild(rootViewController)
        addChild(dragViewController)
        
        view.addSubview(rootViewController.view)
        view.addSubview(dragViewController.view)
        
        rootViewController.view.translatesAutoresizingMaskIntoConstraints = false
        rootViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        rootViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        rootViewController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        rootViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    private func setupInitDragHeight() {
        if usingMaxDragHeightWhenInit {
            updateDragViewHeight(getMaxDragViewControllerHeight(), animated: false)
        } else {
            updateDragViewHeight(getMinDragViewControllerHeight(), animated: false)
        }
    }
}

// MARK: - UIPanGestureRecognizer
extension DraggablePanelViewController {
    private func addPanGestureRecognizer() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onCallPanGestureRecognizer))
        pan.maximumNumberOfTouches = 1
        pan.minimumNumberOfTouches = 1
        dragViewController.draggableView.addGestureRecognizer(pan)
    }
    
    @objc private func onSwipeGestureRecognizer(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case .up:
            print(sender.location(in: dragViewController.draggableView))
        case .down:
            print(sender.location(in: dragViewController.draggableView))
        default:
            break
        }
    }
    
    @objc private func onCallPanGestureRecognizer(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            beforeDragContentHeight = dragViewController.view.frame.height
            fallthrough
        case .changed:
            let height = beforeDragContentHeight - sender.translation(in: view).y
            let targetHeight = limiteHeight(height, tolerance: true)
            updateDragViewHeight(targetHeight, animated: false)
        case .ended, .cancelled:
            let height = beforeDragContentHeight - sender.translation(in: view).y
            let targetHeight: CGFloat
            if attachEdge {
                targetHeight = calculateCloserEdge(offset: height)
            } else {
                targetHeight = limiteHeight(height, tolerance: false)
            }
            updateDragViewHeight(targetHeight, animated: true)
        case .possible, .failed:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - height calculate
extension DraggablePanelViewController {
    private func limiteHeight(_ height: CGFloat, tolerance: Bool) -> CGFloat {
        var currentHeight = height
        currentHeight = calculateMaxHeight(currentHeight: currentHeight, heightType: dragViewController.dragHeight.max, tolerance: tolerance)
        currentHeight = calculateMinHeight(currentHeight: currentHeight, heightType: dragViewController.dragHeight.min, tolerance: tolerance)
        return currentHeight
    }
    
    private func calculateMaxHeight(currentHeight: CGFloat, heightType: DragHeight.DragHeightType, tolerance: Bool) -> CGFloat {
        let height = min(currentHeight, getMaxDragViewControllerHeight())
        if tolerance && height < currentHeight {
            return 0.1 * (currentHeight - height) + height
        } else {
            return height
        }
    }
    
    private func calculateMinHeight(currentHeight: CGFloat, heightType: DragHeight.DragHeightType, tolerance: Bool) -> CGFloat {
        let height = max(currentHeight, getMinDragViewControllerHeight())
        if tolerance && height > currentHeight {
            return 0.1 * (currentHeight - height) + height
        } else {
            return height
        }
    }
    
    private func getMaxDragViewControllerHeight() -> CGFloat {
        switch dragViewController.dragHeight.max {
        case .offset(let offset):
            return offset
        case .ratio(let ratio):
            return view.bounds.height * ratio
        }
    }
    
    private func getMinDragViewControllerHeight() -> CGFloat {
        switch dragViewController.dragHeight.min {
        case .offset(let offset):
            return offset
        case .ratio(let ratio):
            return view.bounds.height * ratio
        }
    }
    
    private func calculateCloserEdge(offset: CGFloat) -> CGFloat {
        let maxHeight = getMaxDragViewControllerHeight()
        let minHeight = getMinDragViewControllerHeight()
        if abs(offset - maxHeight) > abs(offset - minHeight) {
            return minHeight
        } else {
            return maxHeight
        }
    }
    
    private func updateDragViewHeight(_ height: CGFloat, animated: Bool) {
        let block = {
            self.dragViewController.view.frame = CGRect(
                x: 0,
                y: self.view.bounds.height - height,
                width: self.view.bounds.width, height: height
            )
        }
        if animated {
            if isAnimatingDetectEdgeOffset {
                return
            }
            self.isAnimatingDetectEdgeOffset = true
            UIView.animate(withDuration: durationOfDraggableViewAnimation, animations: block) { _ in
                self.isAnimatingDetectEdgeOffset = false
            }
        } else {
            block()
        }
    }
}

// MARK: - DragHeight
extension DraggablePanelViewController {
    struct DragHeight {
        let max: DragHeightType
        let min: DragHeightType
        
        enum DragHeightType {
            case ratio(CGFloat)
            case offset(CGFloat)
        }
        
        static let `default`: DragHeight = .init(max: .ratio(0.618), min: .ratio(0.214))
    }
}
