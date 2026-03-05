import XCTest
@testable import Murmur

final class SettingsModelEnumMigrationTests: XCTestCase {
    func testWhisperBackendMigrationNormalizesLegacyValues() {
        XCTAssertEqual(SettingsModel.WhisperBackend.fromPersisted(" API "), .api)
        XCTAssertEqual(SettingsModel.WhisperBackend.fromPersisted("local"), .local)
        XCTAssertEqual(SettingsModel.WhisperBackend.fromPersisted("unknown"), .local)
        XCTAssertEqual(SettingsModel.WhisperBackend.fromPersisted(nil), .local)
    }

    func testWhisperModelMigrationNormalizesLegacyPrefixAndCase() {
        XCTAssertEqual(SettingsModel.WhisperModel.fromPersisted("whisper-small"), .small)
        XCTAssertEqual(SettingsModel.WhisperModel.fromPersisted("  BASE  "), .base)
        XCTAssertEqual(SettingsModel.WhisperModel.fromPersisted("invalid"), .base)
        XCTAssertEqual(SettingsModel.WhisperModel.fromPersisted(nil), .base)
    }

    func testTargetLanguageMigrationFallsBackToEnglish() {
        XCTAssertEqual(SettingsModel.TargetLanguage.fromPersisted(" RU "), .ru)
        XCTAssertEqual(SettingsModel.TargetLanguage.fromPersisted("zz"), .en)
        XCTAssertEqual(SettingsModel.TargetLanguage.fromPersisted(nil), .en)
    }
}
