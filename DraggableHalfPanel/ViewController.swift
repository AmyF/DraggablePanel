//
//  ViewController.swift
//  DraggableHalfPanel
//
//  Created by Huang Feida on 21/10/2022.
//

import UIKit

class ViewController: DraggablePanelViewController {
    private let rootVC = RootVC()
    override var rootViewController: DraggableRootViewController {
        rootVC
    }
    
    private let dragVC = BottomViewController()
    override var dragViewController: DraggableViewController {
        dragVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}

class RootVC: UIViewController, DraggableRootViewController, UITableViewDataSource {
    var scrollView: UIScrollView? {
        tableView
    }
    
    let tableView: UITableView = UITableView(frame: .zero, style: .plain)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        [
            tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ].forEach {
            $0.isActive = true
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath)"
        return cell
    }
}

class BottomViewController: UIViewController, DraggableViewController {
    var dragHeight: DraggablePanelViewController.DragHeight = .default
    
    var draggableView: UIView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .blue
        draggableView.backgroundColor = .red
        view.addSubview(draggableView)
        draggableView.translatesAutoresizingMaskIntoConstraints = false
        [
            draggableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            draggableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            draggableView.topAnchor.constraint(equalTo: self.view.topAnchor),
            draggableView.heightAnchor.constraint(equalToConstant: 90)
        ].forEach {
            $0.isActive = true
        }
        
        let line = UIView()
        line.backgroundColor = .gray
        draggableView.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        [
            line.topAnchor.constraint(equalTo: draggableView.topAnchor, constant: 20),
            line.widthAnchor.constraint(equalToConstant: 120),
            line.heightAnchor.constraint(equalToConstant: 16),
            line.centerXAnchor.constraint(equalTo: draggableView.centerXAnchor)
        ].forEach {
            $0.isActive = true
        }
    }
}
