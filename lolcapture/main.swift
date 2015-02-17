//
//  main.swift
//  lolcommits
//
//  Created by Matthew Rothenberg on 2/9/15.
//  Copyright (c) 2015 Matthew Rothenberg. All rights reserved.
//

import Foundation

println("📷 lolcommits is preserving this moment in history.")
if let imagedata = CamSnapper().capture() {
    let renderedImage = LOLImage(imageData: imagedata).render()
    renderedImage.writeToFile("/Users/mroth/Desktop/snap2.jpg", atomically: true)
}
