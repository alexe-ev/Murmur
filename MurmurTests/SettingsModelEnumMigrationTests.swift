import XCTest
@testable import Murmur

final class SettingsModelEnumMigrationTests: XCTestCase {
    func testTargetLanguageMigrationFallsBackToEnglish() {
        XCTAssertEqual(SettingsModel.TargetLanguage.fromPersisted(" RU "), .ru)
        XCTAssertEqual(SettingsModel.TargetLanguage.fromPersisted("zz"), .en)
        XCTAssertEqual(SettingsModel.TargetLanguage.fromPersisted(nil), .en)
    }
}
