//
//  BasePlugIn.swift
//  Examples
//
//  Created by Gabriele de Simone on 11/18/26.
//

import FxCore

/// A common base class for all plug-ins used in this project.
///
/// - Note: Shows how to declare some common defaults, such as having all your plug-ins
///   appear under the same category and with the same initial tag and icon.
///
class BasePlugIn : FxCorePlugIn {
    
    public override class var categories: [FxCoreCategoryName] { [FxCoreCategoryName(rawValue: "Examples")] }
    public override class var tag: FxCoreUITag { .pine }
    public override class var symbols: [String] { ["hammer"] }
    
}
