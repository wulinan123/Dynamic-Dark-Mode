import XCTest
@testable import DesktopWallpaperSelection

final class DesktopWallpaperSelectionTests: XCTestCase {
    func testSanitizeKeepsFileURLs() {
        let input = URL(fileURLWithPath: "/tmp/../tmp/a.png")
        let output = DesktopWallpaperSelection.sanitize(input)
        XCTAssertEqual(output, input.standardizedFileURL)
    }
    
    func testSanitizeRejectsNonFileURLs() {
        XCTAssertNil(DesktopWallpaperSelection.sanitize(URL(string: "https://example.com/a.png")))
    }
    
    func testSetByKindAndClear() {
        var selection = DesktopWallpaperSelection()
        let light = URL(fileURLWithPath: "/tmp/light.jpg")
        let dark = URL(fileURLWithPath: "/tmp/dark.jpg")
        
        selection.set(light, for: .light)
        selection.set(dark, for: .dark)
        XCTAssertEqual(selection.lightURL, light.standardizedFileURL)
        XCTAssertEqual(selection.darkURL, dark.standardizedFileURL)
        XCTAssertTrue(selection.hasAnySelection)
        
        selection.clear()
        XCTAssertNil(selection.lightURL)
        XCTAssertNil(selection.darkURL)
        XCTAssertFalse(selection.hasAnySelection)
    }
}
