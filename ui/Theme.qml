import QtQuick 2.15

// Central visual tokens for the desktop application.  The values are adapted
// from DESIGN-cohere.md without depending on proprietary Cohere fonts.
QtObject {
    property color canvas: "#ffffff"
    property color ink: "#17171c"
    property color deepGreen: "#003c33"
    property color deepNavy: "#071829"
    property color mediaSurface: "#0b2234"
    property color softStone: "#eeece7"
    property color paleGreen: "#edfce9"
    property color paleBlue: "#f1f5ff"
    property color hairline: "#d9d9dd"
    property color border: "#e5e7eb"
    property color muted: "#93939f"
    property color slate: "#75758a"
    property color actionBlue: "#1863dc"
    property color focusBlue: "#4c6ee6"
    property color coral: "#ff7759"
    property color errorRed: "#b30000"
    property color errorSoft: "#fff0ed"

    property string sansFont: "Segoe UI"
    property string monoFont: "Cascadia Mono"

    property int space2: 2
    property int space4: 4
    property int space8: 8
    property int space12: 12
    property int space16: 16
    property int space24: 24
    property int space32: 32

    // Shared layout tokens.  Page-level spacing lives here so every tab uses
    // the same grid instead of repeating slightly different magic numbers.
    property int pageInsetDesktop: 32
    property int pageInsetMobile: 16
    property int pageTopInset: 24
    property int sectionGap: 16
    property int cardPaddingDesktop: 24
    property int cardPaddingMobile: 16
    property int controlHeight: 36

    property int radiusSmall: 8
    property int radiusPanel: 12
    property int radiusMedia: 22
    property int radiusPill: 20
}
