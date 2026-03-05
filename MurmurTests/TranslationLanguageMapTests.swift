import XCTest
@testable import Murmur

final class TranslationLanguageMapTests: XCTestCase {
    func testSupportedLanguagesMatchTargetLanguageEnum() {
        let expectedCodes = SettingsModel.TargetLanguage.allCases.map(\.rawValue)
        let actualCodes = TranslationConfig.supportedLanguages.map(\.code)

        XCTAssertEqual(actualCodes, expectedCodes)
        XCTAssertEqual(TranslationConfig.supportedLanguages.count, SettingsModel.TargetLanguage.allCases.count)
    }

    func testSupportedLanguagesContainEnglishDisplayName() {
        let english = TranslationConfig.supportedLanguages.first { $0.code == SettingsModel.TargetLanguage.en.rawValue }
        XCTAssertEqual(english?.name, SettingsModel.TargetLanguage.en.displayName)
    }
}
