//
//  CGVectorExtension.swift
//  SKPong
//
//  Created by Albertino Padin on 4/5/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGVector {
    var length: CGFloat { return hypot(self.dx, self.dy) }
}
