//
//  NoteTypeCircleImageView.swift
//  DateAid
//
//  Created by Aaron Williamson on 3/3/21.
//  Copyright © 2021 Aaron Williamson. All rights reserved.
//

import UIKit

class NoteCircleImageView: CircleImageView {

    // MARK: Properties
    
    let noteType: NoteType
    
    var isSelected = false {
        didSet {
            updateImage(isSelected: isSelected)
        }
    }
    
    private var scaledSize: CGSize
    
    // MARK: Initialization
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(noteType: NoteType, scaledSize: CGSize = .zero) {
        self.noteType = noteType
        self.scaledSize = scaledSize
        super.init()
        configureView()
    }
    
    // MARK: View Setup
    
    override func configureView() {
        super.configureView()
        isUserInteractionEnabled = true
        contentMode = .center
        layer.borderWidth = 5
        
        if scaledSize != .zero {
            downsizeImage(to: scaledSize)
        }
    }
    
    // MARK: Interface
    
    func setSelectedState(isSelected: Bool) {
        self.isSelected = isSelected
    }
    
    // MARK: Private Methods
    
    private func updateImage(isSelected: Bool) {
        if isSelected {
            backgroundColor = .white
            layer.borderColor = UIColor.white.cgColor
            image = noteType.selectedImage
        } else {
            backgroundColor = .compatibleSystemBackground
            layer.borderColor = UIColor.compatibleSystemGray.cgColor
            image = noteType.unselectedImage
        }
        
        if scaledSize != .zero {
            downsizeImage(to: scaledSize)
        }
    }
}