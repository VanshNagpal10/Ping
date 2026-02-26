//
//  AccessibilityFonts.swift
//  Ping
//
//  Scaled font utilities for Dynamic Type support.
//  Wraps UIFontMetrics so that every Text view scales with
//  the user's preferred content-size category, capped at
//  a sensible maximum to prevent game-HUD layout breakage.
//

import SwiftUI

/// Provides scaled fonts that respect Dynamic Type settings.
enum ScaledFont {
    
    /// Returns a `Font` that scales with the user's Dynamic Type setting.
    ///
    /// - Parameters:
    ///   - size: The base point size at the `.large` (default) content-size category.
    ///   - weight: The font weight.
    ///   - design: The font design (e.g. `.rounded`, `.monospaced`).
    ///   - maxSize: The maximum point size the font can grow to. Defaults to `1.5× size`.
    ///              Pass `nil` to allow unlimited scaling.
    /// - Returns: A `Font` that adapts to the user's accessibility settings.
    static func scaledFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        maxSize: CGFloat? = nil
    ) -> Font {
        let cap = maxSize ?? (size * 1.5)
        let metrics = UIFontMetrics(forTextStyle: .body)
        
        // Create a UIFont with the requested traits, then scale it
        let descriptor = UIFont.systemFont(ofSize: size).fontDescriptor
        let baseFont = UIFont(descriptor: descriptor, size: size)
        let scaledSize = min(metrics.scaledValue(for: baseFont.pointSize), cap)
        
        return Font.system(size: scaledSize, weight: weight, design: design)
    }
}
