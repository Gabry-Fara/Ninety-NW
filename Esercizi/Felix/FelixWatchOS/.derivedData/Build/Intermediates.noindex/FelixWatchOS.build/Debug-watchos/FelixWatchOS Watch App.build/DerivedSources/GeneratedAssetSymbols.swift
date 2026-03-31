import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "Asset 1" asset catalog image resource.
    static let asset1 = DeveloperToolsSupport.ImageResource(name: "Asset 1", bundle: resourceBundle)

    /// The "Asset 10" asset catalog image resource.
    static let asset10 = DeveloperToolsSupport.ImageResource(name: "Asset 10", bundle: resourceBundle)

    /// The "Asset 11" asset catalog image resource.
    static let asset11 = DeveloperToolsSupport.ImageResource(name: "Asset 11", bundle: resourceBundle)

    /// The "Asset 12" asset catalog image resource.
    static let asset12 = DeveloperToolsSupport.ImageResource(name: "Asset 12", bundle: resourceBundle)

    /// The "Asset 13" asset catalog image resource.
    static let asset13 = DeveloperToolsSupport.ImageResource(name: "Asset 13", bundle: resourceBundle)

    /// The "Asset 14" asset catalog image resource.
    static let asset14 = DeveloperToolsSupport.ImageResource(name: "Asset 14", bundle: resourceBundle)

    /// The "Asset 15" asset catalog image resource.
    static let asset15 = DeveloperToolsSupport.ImageResource(name: "Asset 15", bundle: resourceBundle)

    /// The "Asset 2" asset catalog image resource.
    static let asset2 = DeveloperToolsSupport.ImageResource(name: "Asset 2", bundle: resourceBundle)

    /// The "Asset 3" asset catalog image resource.
    static let asset3 = DeveloperToolsSupport.ImageResource(name: "Asset 3", bundle: resourceBundle)

    /// The "Asset 4" asset catalog image resource.
    static let asset4 = DeveloperToolsSupport.ImageResource(name: "Asset 4", bundle: resourceBundle)

    /// The "Asset 5" asset catalog image resource.
    static let asset5 = DeveloperToolsSupport.ImageResource(name: "Asset 5", bundle: resourceBundle)

    /// The "Asset 6" asset catalog image resource.
    static let asset6 = DeveloperToolsSupport.ImageResource(name: "Asset 6", bundle: resourceBundle)

    /// The "Asset 7" asset catalog image resource.
    static let asset7 = DeveloperToolsSupport.ImageResource(name: "Asset 7", bundle: resourceBundle)

    /// The "Asset 8" asset catalog image resource.
    static let asset8 = DeveloperToolsSupport.ImageResource(name: "Asset 8", bundle: resourceBundle)

    /// The "Asset 9" asset catalog image resource.
    static let asset9 = DeveloperToolsSupport.ImageResource(name: "Asset 9", bundle: resourceBundle)

    /// The "Autumn Bush" asset catalog image resource.
    static let autumnBush = DeveloperToolsSupport.ImageResource(name: "Autumn Bush", bundle: resourceBundle)

    /// The "Autumn Tree" asset catalog image resource.
    static let autumnTree = DeveloperToolsSupport.ImageResource(name: "Autumn Tree", bundle: resourceBundle)

    /// The "Bush" asset catalog image resource.
    static let bush = DeveloperToolsSupport.ImageResource(name: "Bush", bundle: resourceBundle)

    /// The "Coin" asset catalog image resource.
    static let coin = DeveloperToolsSupport.ImageResource(name: "Coin", bundle: resourceBundle)

    /// The "Fall (1)" asset catalog image resource.
    static let fall1 = DeveloperToolsSupport.ImageResource(name: "Fall (1)", bundle: resourceBundle)

    /// The "Fall (2)" asset catalog image resource.
    static let fall2 = DeveloperToolsSupport.ImageResource(name: "Fall (2)", bundle: resourceBundle)

    /// The "Fall (3)" asset catalog image resource.
    static let fall3 = DeveloperToolsSupport.ImageResource(name: "Fall (3)", bundle: resourceBundle)

    /// The "Fall (4)" asset catalog image resource.
    static let fall4 = DeveloperToolsSupport.ImageResource(name: "Fall (4)", bundle: resourceBundle)

    /// The "Fall (5)" asset catalog image resource.
    static let fall5 = DeveloperToolsSupport.ImageResource(name: "Fall (5)", bundle: resourceBundle)

    /// The "Fall (6)" asset catalog image resource.
    static let fall6 = DeveloperToolsSupport.ImageResource(name: "Fall (6)", bundle: resourceBundle)

    /// The "Fall (7)" asset catalog image resource.
    static let fall7 = DeveloperToolsSupport.ImageResource(name: "Fall (7)", bundle: resourceBundle)

    /// The "Fall (8)" asset catalog image resource.
    static let fall8 = DeveloperToolsSupport.ImageResource(name: "Fall (8)", bundle: resourceBundle)

    /// The "Flower-1" asset catalog image resource.
    static let flower1 = DeveloperToolsSupport.ImageResource(name: "Flower-1", bundle: resourceBundle)

    /// The "Flower-2" asset catalog image resource.
    static let flower2 = DeveloperToolsSupport.ImageResource(name: "Flower-2", bundle: resourceBundle)

    /// The "Flower-3" asset catalog image resource.
    static let flower3 = DeveloperToolsSupport.ImageResource(name: "Flower-3", bundle: resourceBundle)

    /// The "Grass" asset catalog image resource.
    static let grass = DeveloperToolsSupport.ImageResource(name: "Grass", bundle: resourceBundle)

    /// The "GrassCliffLeft" asset catalog image resource.
    static let grassCliffLeft = DeveloperToolsSupport.ImageResource(name: "GrassCliffLeft", bundle: resourceBundle)

    /// The "GrassCliffMid" asset catalog image resource.
    static let grassCliffMid = DeveloperToolsSupport.ImageResource(name: "GrassCliffMid", bundle: resourceBundle)

    /// The "GrassCliffRight" asset catalog image resource.
    static let grassCliffRight = DeveloperToolsSupport.ImageResource(name: "GrassCliffRight", bundle: resourceBundle)

    /// The "Hurt (1)" asset catalog image resource.
    static let hurt1 = DeveloperToolsSupport.ImageResource(name: "Hurt (1)", bundle: resourceBundle)

    /// The "Hurt (2)" asset catalog image resource.
    static let hurt2 = DeveloperToolsSupport.ImageResource(name: "Hurt (2)", bundle: resourceBundle)

    /// The "Hurt (3)" asset catalog image resource.
    static let hurt3 = DeveloperToolsSupport.ImageResource(name: "Hurt (3)", bundle: resourceBundle)

    /// The "Jump (1)" asset catalog image resource.
    static let jump1 = DeveloperToolsSupport.ImageResource(name: "Jump (1)", bundle: resourceBundle)

    /// The "Jump (2)" asset catalog image resource.
    static let jump2 = DeveloperToolsSupport.ImageResource(name: "Jump (2)", bundle: resourceBundle)

    /// The "Jump (3)" asset catalog image resource.
    static let jump3 = DeveloperToolsSupport.ImageResource(name: "Jump (3)", bundle: resourceBundle)

    /// The "Jump (4)" asset catalog image resource.
    static let jump4 = DeveloperToolsSupport.ImageResource(name: "Jump (4)", bundle: resourceBundle)

    /// The "Jump (5)" asset catalog image resource.
    static let jump5 = DeveloperToolsSupport.ImageResource(name: "Jump (5)", bundle: resourceBundle)

    /// The "Jump (6)" asset catalog image resource.
    static let jump6 = DeveloperToolsSupport.ImageResource(name: "Jump (6)", bundle: resourceBundle)

    /// The "Jump (7)" asset catalog image resource.
    static let jump7 = DeveloperToolsSupport.ImageResource(name: "Jump (7)", bundle: resourceBundle)

    /// The "Jump (8)" asset catalog image resource.
    static let jump8 = DeveloperToolsSupport.ImageResource(name: "Jump (8)", bundle: resourceBundle)

    /// The "Platform1" asset catalog image resource.
    static let platform1 = DeveloperToolsSupport.ImageResource(name: "Platform1", bundle: resourceBundle)

    /// The "Platform2" asset catalog image resource.
    static let platform2 = DeveloperToolsSupport.ImageResource(name: "Platform2", bundle: resourceBundle)

    /// The "Run (1)" asset catalog image resource.
    static let run1 = DeveloperToolsSupport.ImageResource(name: "Run (1)", bundle: resourceBundle)

    /// The "Run (2)" asset catalog image resource.
    static let run2 = DeveloperToolsSupport.ImageResource(name: "Run (2)", bundle: resourceBundle)

    /// The "Run (3)" asset catalog image resource.
    static let run3 = DeveloperToolsSupport.ImageResource(name: "Run (3)", bundle: resourceBundle)

    /// The "Run (4)" asset catalog image resource.
    static let run4 = DeveloperToolsSupport.ImageResource(name: "Run (4)", bundle: resourceBundle)

    /// The "Run (5)" asset catalog image resource.
    static let run5 = DeveloperToolsSupport.ImageResource(name: "Run (5)", bundle: resourceBundle)

    /// The "Run (6)" asset catalog image resource.
    static let run6 = DeveloperToolsSupport.ImageResource(name: "Run (6)", bundle: resourceBundle)

    /// The "Run (7)" asset catalog image resource.
    static let run7 = DeveloperToolsSupport.ImageResource(name: "Run (7)", bundle: resourceBundle)

    /// The "Run (8)" asset catalog image resource.
    static let run8 = DeveloperToolsSupport.ImageResource(name: "Run (8)", bundle: resourceBundle)

    /// The "Tree" asset catalog image resource.
    static let tree = DeveloperToolsSupport.ImageResource(name: "Tree", bundle: resourceBundle)

    /// The "Winter Tree" asset catalog image resource.
    static let winterTree = DeveloperToolsSupport.ImageResource(name: "Winter Tree", bundle: resourceBundle)

    /// The "background" asset catalog image resource.
    static let background = DeveloperToolsSupport.ImageResource(name: "background", bundle: resourceBundle)

    /// The "image 1" asset catalog image resource.
    static let image1 = DeveloperToolsSupport.ImageResource(name: "image 1", bundle: resourceBundle)

    /// The "image 10" asset catalog image resource.
    static let image10 = DeveloperToolsSupport.ImageResource(name: "image 10", bundle: resourceBundle)

    /// The "image 11" asset catalog image resource.
    static let image11 = DeveloperToolsSupport.ImageResource(name: "image 11", bundle: resourceBundle)

    /// The "image 12" asset catalog image resource.
    static let image12 = DeveloperToolsSupport.ImageResource(name: "image 12", bundle: resourceBundle)

    /// The "image 13" asset catalog image resource.
    static let image13 = DeveloperToolsSupport.ImageResource(name: "image 13", bundle: resourceBundle)

    /// The "image 14" asset catalog image resource.
    static let image14 = DeveloperToolsSupport.ImageResource(name: "image 14", bundle: resourceBundle)

    /// The "image 15" asset catalog image resource.
    static let image15 = DeveloperToolsSupport.ImageResource(name: "image 15", bundle: resourceBundle)

    /// The "image 16" asset catalog image resource.
    static let image16 = DeveloperToolsSupport.ImageResource(name: "image 16", bundle: resourceBundle)

    /// The "image 2" asset catalog image resource.
    static let image2 = DeveloperToolsSupport.ImageResource(name: "image 2", bundle: resourceBundle)

    /// The "image 3" asset catalog image resource.
    static let image3 = DeveloperToolsSupport.ImageResource(name: "image 3", bundle: resourceBundle)

    /// The "image 4" asset catalog image resource.
    static let image4 = DeveloperToolsSupport.ImageResource(name: "image 4", bundle: resourceBundle)

    /// The "image 5" asset catalog image resource.
    static let image5 = DeveloperToolsSupport.ImageResource(name: "image 5", bundle: resourceBundle)

    /// The "image 6" asset catalog image resource.
    static let image6 = DeveloperToolsSupport.ImageResource(name: "image 6", bundle: resourceBundle)

    /// The "image 7" asset catalog image resource.
    static let image7 = DeveloperToolsSupport.ImageResource(name: "image 7", bundle: resourceBundle)

    /// The "image 8" asset catalog image resource.
    static let image8 = DeveloperToolsSupport.ImageResource(name: "image 8", bundle: resourceBundle)

    /// The "image 9" asset catalog image resource.
    static let image9 = DeveloperToolsSupport.ImageResource(name: "image 9", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "Asset 1" asset catalog image.
    static var asset1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset1)
#else
        .init()
#endif
    }

    /// The "Asset 10" asset catalog image.
    static var asset10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset10)
#else
        .init()
#endif
    }

    /// The "Asset 11" asset catalog image.
    static var asset11: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset11)
#else
        .init()
#endif
    }

    /// The "Asset 12" asset catalog image.
    static var asset12: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset12)
#else
        .init()
#endif
    }

    /// The "Asset 13" asset catalog image.
    static var asset13: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset13)
#else
        .init()
#endif
    }

    /// The "Asset 14" asset catalog image.
    static var asset14: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset14)
#else
        .init()
#endif
    }

    /// The "Asset 15" asset catalog image.
    static var asset15: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset15)
#else
        .init()
#endif
    }

    /// The "Asset 2" asset catalog image.
    static var asset2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset2)
#else
        .init()
#endif
    }

    /// The "Asset 3" asset catalog image.
    static var asset3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset3)
#else
        .init()
#endif
    }

    /// The "Asset 4" asset catalog image.
    static var asset4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset4)
#else
        .init()
#endif
    }

    /// The "Asset 5" asset catalog image.
    static var asset5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset5)
#else
        .init()
#endif
    }

    /// The "Asset 6" asset catalog image.
    static var asset6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset6)
#else
        .init()
#endif
    }

    /// The "Asset 7" asset catalog image.
    static var asset7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset7)
#else
        .init()
#endif
    }

    /// The "Asset 8" asset catalog image.
    static var asset8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset8)
#else
        .init()
#endif
    }

    /// The "Asset 9" asset catalog image.
    static var asset9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .asset9)
#else
        .init()
#endif
    }

    /// The "Autumn Bush" asset catalog image.
    static var autumnBush: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .autumnBush)
#else
        .init()
#endif
    }

    /// The "Autumn Tree" asset catalog image.
    static var autumnTree: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .autumnTree)
#else
        .init()
#endif
    }

    /// The "Bush" asset catalog image.
    static var bush: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bush)
#else
        .init()
#endif
    }

    /// The "Coin" asset catalog image.
    static var coin: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .coin)
#else
        .init()
#endif
    }

    /// The "Fall (1)" asset catalog image.
    static var fall1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fall1)
#else
        .init()
#endif
    }

    /// The "Fall (2)" asset catalog image.
    static var fall2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fall2)
#else
        .init()
#endif
    }

    /// The "Fall (3)" asset catalog image.
    static var fall3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fall3)
#else
        .init()
#endif
    }

    /// The "Fall (4)" asset catalog image.
    static var fall4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fall4)
#else
        .init()
#endif
    }

    /// The "Fall (5)" asset catalog image.
    static var fall5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fall5)
#else
        .init()
#endif
    }

    /// The "Fall (6)" asset catalog image.
    static var fall6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fall6)
#else
        .init()
#endif
    }

    /// The "Fall (7)" asset catalog image.
    static var fall7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fall7)
#else
        .init()
#endif
    }

    /// The "Fall (8)" asset catalog image.
    static var fall8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fall8)
#else
        .init()
#endif
    }

    /// The "Flower-1" asset catalog image.
    static var flower1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .flower1)
#else
        .init()
#endif
    }

    /// The "Flower-2" asset catalog image.
    static var flower2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .flower2)
#else
        .init()
#endif
    }

    /// The "Flower-3" asset catalog image.
    static var flower3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .flower3)
#else
        .init()
#endif
    }

    /// The "Grass" asset catalog image.
    static var grass: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .grass)
#else
        .init()
#endif
    }

    /// The "GrassCliffLeft" asset catalog image.
    static var grassCliffLeft: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .grassCliffLeft)
#else
        .init()
#endif
    }

    /// The "GrassCliffMid" asset catalog image.
    static var grassCliffMid: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .grassCliffMid)
#else
        .init()
#endif
    }

    /// The "GrassCliffRight" asset catalog image.
    static var grassCliffRight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .grassCliffRight)
#else
        .init()
#endif
    }

    /// The "Hurt (1)" asset catalog image.
    static var hurt1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hurt1)
#else
        .init()
#endif
    }

    /// The "Hurt (2)" asset catalog image.
    static var hurt2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hurt2)
#else
        .init()
#endif
    }

    /// The "Hurt (3)" asset catalog image.
    static var hurt3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hurt3)
#else
        .init()
#endif
    }

    /// The "Jump (1)" asset catalog image.
    static var jump1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jump1)
#else
        .init()
#endif
    }

    /// The "Jump (2)" asset catalog image.
    static var jump2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jump2)
#else
        .init()
#endif
    }

    /// The "Jump (3)" asset catalog image.
    static var jump3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jump3)
#else
        .init()
#endif
    }

    /// The "Jump (4)" asset catalog image.
    static var jump4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jump4)
#else
        .init()
#endif
    }

    /// The "Jump (5)" asset catalog image.
    static var jump5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jump5)
#else
        .init()
#endif
    }

    /// The "Jump (6)" asset catalog image.
    static var jump6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jump6)
#else
        .init()
#endif
    }

    /// The "Jump (7)" asset catalog image.
    static var jump7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jump7)
#else
        .init()
#endif
    }

    /// The "Jump (8)" asset catalog image.
    static var jump8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jump8)
#else
        .init()
#endif
    }

    /// The "Platform1" asset catalog image.
    static var platform1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .platform1)
#else
        .init()
#endif
    }

    /// The "Platform2" asset catalog image.
    static var platform2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .platform2)
#else
        .init()
#endif
    }

    /// The "Run (1)" asset catalog image.
    static var run1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .run1)
#else
        .init()
#endif
    }

    /// The "Run (2)" asset catalog image.
    static var run2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .run2)
#else
        .init()
#endif
    }

    /// The "Run (3)" asset catalog image.
    static var run3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .run3)
#else
        .init()
#endif
    }

    /// The "Run (4)" asset catalog image.
    static var run4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .run4)
#else
        .init()
#endif
    }

    /// The "Run (5)" asset catalog image.
    static var run5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .run5)
#else
        .init()
#endif
    }

    /// The "Run (6)" asset catalog image.
    static var run6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .run6)
#else
        .init()
#endif
    }

    /// The "Run (7)" asset catalog image.
    static var run7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .run7)
#else
        .init()
#endif
    }

    /// The "Run (8)" asset catalog image.
    static var run8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .run8)
#else
        .init()
#endif
    }

    /// The "Tree" asset catalog image.
    static var tree: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tree)
#else
        .init()
#endif
    }

    /// The "Winter Tree" asset catalog image.
    static var winterTree: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .winterTree)
#else
        .init()
#endif
    }

    /// The "background" asset catalog image.
    static var background: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .background)
#else
        .init()
#endif
    }

    /// The "image 1" asset catalog image.
    static var image1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image1)
#else
        .init()
#endif
    }

    /// The "image 10" asset catalog image.
    static var image10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image10)
#else
        .init()
#endif
    }

    /// The "image 11" asset catalog image.
    static var image11: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image11)
#else
        .init()
#endif
    }

    /// The "image 12" asset catalog image.
    static var image12: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image12)
#else
        .init()
#endif
    }

    /// The "image 13" asset catalog image.
    static var image13: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image13)
#else
        .init()
#endif
    }

    /// The "image 14" asset catalog image.
    static var image14: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image14)
#else
        .init()
#endif
    }

    /// The "image 15" asset catalog image.
    static var image15: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image15)
#else
        .init()
#endif
    }

    /// The "image 16" asset catalog image.
    static var image16: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image16)
#else
        .init()
#endif
    }

    /// The "image 2" asset catalog image.
    static var image2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image2)
#else
        .init()
#endif
    }

    /// The "image 3" asset catalog image.
    static var image3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image3)
#else
        .init()
#endif
    }

    /// The "image 4" asset catalog image.
    static var image4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image4)
#else
        .init()
#endif
    }

    /// The "image 5" asset catalog image.
    static var image5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image5)
#else
        .init()
#endif
    }

    /// The "image 6" asset catalog image.
    static var image6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image6)
#else
        .init()
#endif
    }

    /// The "image 7" asset catalog image.
    static var image7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image7)
#else
        .init()
#endif
    }

    /// The "image 8" asset catalog image.
    static var image8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image8)
#else
        .init()
#endif
    }

    /// The "image 9" asset catalog image.
    static var image9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .image9)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "Asset 1" asset catalog image.
    static var asset1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset1)
#else
        .init()
#endif
    }

    /// The "Asset 10" asset catalog image.
    static var asset10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset10)
#else
        .init()
#endif
    }

    /// The "Asset 11" asset catalog image.
    static var asset11: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset11)
#else
        .init()
#endif
    }

    /// The "Asset 12" asset catalog image.
    static var asset12: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset12)
#else
        .init()
#endif
    }

    /// The "Asset 13" asset catalog image.
    static var asset13: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset13)
#else
        .init()
#endif
    }

    /// The "Asset 14" asset catalog image.
    static var asset14: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset14)
#else
        .init()
#endif
    }

    /// The "Asset 15" asset catalog image.
    static var asset15: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset15)
#else
        .init()
#endif
    }

    /// The "Asset 2" asset catalog image.
    static var asset2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset2)
#else
        .init()
#endif
    }

    /// The "Asset 3" asset catalog image.
    static var asset3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset3)
#else
        .init()
#endif
    }

    /// The "Asset 4" asset catalog image.
    static var asset4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset4)
#else
        .init()
#endif
    }

    /// The "Asset 5" asset catalog image.
    static var asset5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset5)
#else
        .init()
#endif
    }

    /// The "Asset 6" asset catalog image.
    static var asset6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset6)
#else
        .init()
#endif
    }

    /// The "Asset 7" asset catalog image.
    static var asset7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset7)
#else
        .init()
#endif
    }

    /// The "Asset 8" asset catalog image.
    static var asset8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset8)
#else
        .init()
#endif
    }

    /// The "Asset 9" asset catalog image.
    static var asset9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .asset9)
#else
        .init()
#endif
    }

    /// The "Autumn Bush" asset catalog image.
    static var autumnBush: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .autumnBush)
#else
        .init()
#endif
    }

    /// The "Autumn Tree" asset catalog image.
    static var autumnTree: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .autumnTree)
#else
        .init()
#endif
    }

    /// The "Bush" asset catalog image.
    static var bush: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .bush)
#else
        .init()
#endif
    }

    /// The "Coin" asset catalog image.
    static var coin: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .coin)
#else
        .init()
#endif
    }

    /// The "Fall (1)" asset catalog image.
    static var fall1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .fall1)
#else
        .init()
#endif
    }

    /// The "Fall (2)" asset catalog image.
    static var fall2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .fall2)
#else
        .init()
#endif
    }

    /// The "Fall (3)" asset catalog image.
    static var fall3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .fall3)
#else
        .init()
#endif
    }

    /// The "Fall (4)" asset catalog image.
    static var fall4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .fall4)
#else
        .init()
#endif
    }

    /// The "Fall (5)" asset catalog image.
    static var fall5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .fall5)
#else
        .init()
#endif
    }

    /// The "Fall (6)" asset catalog image.
    static var fall6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .fall6)
#else
        .init()
#endif
    }

    /// The "Fall (7)" asset catalog image.
    static var fall7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .fall7)
#else
        .init()
#endif
    }

    /// The "Fall (8)" asset catalog image.
    static var fall8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .fall8)
#else
        .init()
#endif
    }

    /// The "Flower-1" asset catalog image.
    static var flower1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .flower1)
#else
        .init()
#endif
    }

    /// The "Flower-2" asset catalog image.
    static var flower2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .flower2)
#else
        .init()
#endif
    }

    /// The "Flower-3" asset catalog image.
    static var flower3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .flower3)
#else
        .init()
#endif
    }

    /// The "Grass" asset catalog image.
    static var grass: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .grass)
#else
        .init()
#endif
    }

    /// The "GrassCliffLeft" asset catalog image.
    static var grassCliffLeft: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .grassCliffLeft)
#else
        .init()
#endif
    }

    /// The "GrassCliffMid" asset catalog image.
    static var grassCliffMid: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .grassCliffMid)
#else
        .init()
#endif
    }

    /// The "GrassCliffRight" asset catalog image.
    static var grassCliffRight: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .grassCliffRight)
#else
        .init()
#endif
    }

    /// The "Hurt (1)" asset catalog image.
    static var hurt1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hurt1)
#else
        .init()
#endif
    }

    /// The "Hurt (2)" asset catalog image.
    static var hurt2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hurt2)
#else
        .init()
#endif
    }

    /// The "Hurt (3)" asset catalog image.
    static var hurt3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hurt3)
#else
        .init()
#endif
    }

    /// The "Jump (1)" asset catalog image.
    static var jump1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jump1)
#else
        .init()
#endif
    }

    /// The "Jump (2)" asset catalog image.
    static var jump2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jump2)
#else
        .init()
#endif
    }

    /// The "Jump (3)" asset catalog image.
    static var jump3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jump3)
#else
        .init()
#endif
    }

    /// The "Jump (4)" asset catalog image.
    static var jump4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jump4)
#else
        .init()
#endif
    }

    /// The "Jump (5)" asset catalog image.
    static var jump5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jump5)
#else
        .init()
#endif
    }

    /// The "Jump (6)" asset catalog image.
    static var jump6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jump6)
#else
        .init()
#endif
    }

    /// The "Jump (7)" asset catalog image.
    static var jump7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jump7)
#else
        .init()
#endif
    }

    /// The "Jump (8)" asset catalog image.
    static var jump8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jump8)
#else
        .init()
#endif
    }

    /// The "Platform1" asset catalog image.
    static var platform1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .platform1)
#else
        .init()
#endif
    }

    /// The "Platform2" asset catalog image.
    static var platform2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .platform2)
#else
        .init()
#endif
    }

    /// The "Run (1)" asset catalog image.
    static var run1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .run1)
#else
        .init()
#endif
    }

    /// The "Run (2)" asset catalog image.
    static var run2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .run2)
#else
        .init()
#endif
    }

    /// The "Run (3)" asset catalog image.
    static var run3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .run3)
#else
        .init()
#endif
    }

    /// The "Run (4)" asset catalog image.
    static var run4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .run4)
#else
        .init()
#endif
    }

    /// The "Run (5)" asset catalog image.
    static var run5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .run5)
#else
        .init()
#endif
    }

    /// The "Run (6)" asset catalog image.
    static var run6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .run6)
#else
        .init()
#endif
    }

    /// The "Run (7)" asset catalog image.
    static var run7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .run7)
#else
        .init()
#endif
    }

    /// The "Run (8)" asset catalog image.
    static var run8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .run8)
#else
        .init()
#endif
    }

    /// The "Tree" asset catalog image.
    static var tree: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tree)
#else
        .init()
#endif
    }

    /// The "Winter Tree" asset catalog image.
    static var winterTree: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .winterTree)
#else
        .init()
#endif
    }

    /// The "background" asset catalog image.
    static var background: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .background)
#else
        .init()
#endif
    }

    /// The "image 1" asset catalog image.
    static var image1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image1)
#else
        .init()
#endif
    }

    /// The "image 10" asset catalog image.
    static var image10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image10)
#else
        .init()
#endif
    }

    /// The "image 11" asset catalog image.
    static var image11: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image11)
#else
        .init()
#endif
    }

    /// The "image 12" asset catalog image.
    static var image12: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image12)
#else
        .init()
#endif
    }

    /// The "image 13" asset catalog image.
    static var image13: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image13)
#else
        .init()
#endif
    }

    /// The "image 14" asset catalog image.
    static var image14: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image14)
#else
        .init()
#endif
    }

    /// The "image 15" asset catalog image.
    static var image15: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image15)
#else
        .init()
#endif
    }

    /// The "image 16" asset catalog image.
    static var image16: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image16)
#else
        .init()
#endif
    }

    /// The "image 2" asset catalog image.
    static var image2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image2)
#else
        .init()
#endif
    }

    /// The "image 3" asset catalog image.
    static var image3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image3)
#else
        .init()
#endif
    }

    /// The "image 4" asset catalog image.
    static var image4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image4)
#else
        .init()
#endif
    }

    /// The "image 5" asset catalog image.
    static var image5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image5)
#else
        .init()
#endif
    }

    /// The "image 6" asset catalog image.
    static var image6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image6)
#else
        .init()
#endif
    }

    /// The "image 7" asset catalog image.
    static var image7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image7)
#else
        .init()
#endif
    }

    /// The "image 8" asset catalog image.
    static var image8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image8)
#else
        .init()
#endif
    }

    /// The "image 9" asset catalog image.
    static var image9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .image9)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

