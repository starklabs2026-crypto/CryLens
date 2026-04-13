import XCTest
@testable import CryLens

final class CryLensTests: XCTestCase {

    // MARK: - CryLabel tests

    func testCryLabelDisplayNamesAreNonEmpty() {
        for label in CryLabel.allCases {
            XCTAssertFalse(label.displayName.isEmpty, "\(label.rawValue) has empty displayName")
        }
    }

    func testCryLabelDescriptionsAreNonEmpty() {
        for label in CryLabel.allCases {
            XCTAssertFalse(label.description.isEmpty, "\(label.rawValue) has empty description")
        }
    }

    func testCryLabelAllFiveCasesExist() {
        XCTAssertEqual(CryLabel.allCases.count, 5)
        XCTAssertNotNil(CryLabel(rawValue: "hungry"))
        XCTAssertNotNil(CryLabel(rawValue: "tired"))
        XCTAssertNotNil(CryLabel(rawValue: "pain"))
        XCTAssertNotNil(CryLabel(rawValue: "burping"))
        XCTAssertNotNil(CryLabel(rawValue: "discomfort"))
    }

    // MARK: - APIError tests

    func testAPIErrorLocalizedDescriptionsAreNonEmpty() {
        let cases: [APIError] = [
            .invalidURL,
            .noData,
            .unauthorized,
            .serverError("test message"),
            .decodingError
        ]
        for error in cases {
            XCTAssertFalse(
                (error.errorDescription ?? "").isEmpty,
                "APIError.\(error) has empty errorDescription"
            )
        }
    }
}
