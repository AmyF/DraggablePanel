//
//  DraggablePanel.swift
//  DraggableHalfPanel
//
//  Created by Huang Feida on 21/10/2022.
//

import UIKit

struct DragHeight {
    let max: DragHeightType
    let min: DragHeightType
    
    enum DragHeightType {
        case ratio(CGFloat)
        case offset(CGFloat)
    }
    
    static let `default`: DragHeight = .init(max: .ratio(0.618), min: .ratio(0.214))
}

protocol DraggableViewController: UIViewController {
    var dragHeight: DragHeight { get }
    var draggableView: UIView { get }
}

class DraggablePanelViewController: UIViewController {
    var usingMaxDragHeightWhenInit: Bool {
        true
    }
    
    var attachEdge: Bool {
        true
    }
    
    var rootViewController: UIViewController {
        fatalError()
    }
    
    var dragViewController: DraggableViewController {
        fatalError()
    }
    
    private var beforeDragContentHeight: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        addPanGestureRecognizer()
        
        if usingMaxDragHeightWhenInit {
            updateDragViewHeight(getMaxDragViewControllerHeight())
        } else {
            updateDragViewHeight(getMinDragViewControllerHeight())
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
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
            updateDragViewHeight(targetHeight)
        case .ended, .cancelled:
            let height = beforeDragContentHeight - sender.translation(in: view).y
            let targetHeight: CGFloat
            if attachEdge {
               targetHeight = calculateCloserEdge(offset: height)
            } else {
                targetHeight = limiteHeight(height, tolerance: false)
            }
            UIView.animate(withDuration: 0.1) {
                self.updateDragViewHeight(targetHeight)
            }
        case .possible, .failed:
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - height calculate
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
    
    private func updateDragViewHeight(_ height: CGFloat) {
        dragViewController.view.frame = CGRect(x: 0, y: view.bounds.height - height, width: view.bounds.width, height: height)
    }
}
