import Foundation
import os
import ServiceManagement

enum LoginItemService {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        let status = SMAppService.mainApp.status
        AppLog.loginItem.info("SMAppService status=\(String(describing: status), privacy: .public) requested=\(enabled)")
        if enabled {
            try SMAppService.mainApp.register()
            AppLog.loginItem.info("Registered login item")
        } else {
            try SMAppService.mainApp.unregister()
            AppLog.loginItem.info("Unregistered login item")
        }
    }
}
