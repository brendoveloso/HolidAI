import XCTest

final class HolidAIUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTabsProfileAndEmptyContractAction() throws {
        let app = makeApp()
        app.launch()

        let compactTabBar = app.tabBars.firstMatch
        if compactTabBar.exists {
            XCTAssertEqual(compactTabBar.buttons.count, 4)
            XCTAssertTrue(compactTabBar.buttons["Início"].exists)
            XCTAssertTrue(compactTabBar.buttons["Feriados"].exists)
            XCTAssertTrue(compactTabBar.buttons["Contratos"].exists)
        } else {
            XCTAssertTrue(app.buttons["Início"].exists)
            XCTAssertTrue(app.buttons["Feriados"].exists)
            XCTAssertTrue(app.buttons["Contratos"].exists)
        }
        XCTAssertTrue(app.buttons["Perfil"].exists)
        XCTAssertTrue(app.buttons["Adicionar contrato"].exists)

        if compactTabBar.exists {
            compactTabBar.buttons.element(boundBy: 3).tap()
            XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 2))
            compactTabBar.buttons["Início"].tap()
            XCTAssertTrue(compactTabBar.buttons["Início"].isSelected)
        }

        app.buttons["Perfil"].tap()
        XCTAssertTrue(app.navigationBars["Perfil"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testCreatesFirstContract() throws {
        let app = makeApp()
        app.launch()

        app.buttons["Adicionar contrato"].tap()
        let companyField = app.textFields["Nome da Empresa (Ex: Nubank)"]
        XCTAssertTrue(companyField.waitForExistence(timeout: 2))
        companyField.tap()
        companyField.typeText("Empresa Teste")

        let statePicker = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Estado'")).firstMatch
        XCTAssertTrue(statePicker.exists)
        statePicker.tap()
        XCTAssertTrue(app.buttons["São Paulo"].waitForExistence(timeout: 2))
        app.buttons["São Paulo"].tap()
        app.buttons["Salvar"].tap()

        XCTAssertTrue(app.staticTexts["Empresa Teste"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testMultipleContractsAndSearchDestinations() throws {
        let app = makeApp(seedContracts: true)
        app.launch()

        app.tabBars.buttons["Contratos"].tap()
        XCTAssertTrue(app.staticTexts["Banco Ágil"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Estúdio Aurora"].exists)

        app.tabBars.buttons.element(boundBy: 3).tap()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 2))
        searchField.typeText("bancario")
        XCTAssertTrue(app.staticTexts["Banco Ágil"].waitForExistence(timeout: 2))
        app.staticTexts["Banco Ágil"].tap()
        XCTAssertTrue(app.navigationBars["Banco Ágil"].waitForExistence(timeout: 2))

        app.tabBars.buttons.element(boundBy: 3).tap()
        let holidaySearchField = app.searchFields.firstMatch
        XCTAssertTrue(holidaySearchField.waitForExistence(timeout: 2))
        holidaySearchField.typeText("Natal")
        XCTAssertTrue(app.staticTexts["Natal"].waitForExistence(timeout: 2))
        app.staticTexts["Natal"].tap()
        XCTAssertTrue(app.navigationBars["Natal"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) { makeApp().launch() }
    }

    private func makeApp(seedContracts: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        if seedContracts { app.launchArguments.append("-ui-seed-contracts") }
        return app
    }
}
