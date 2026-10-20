import AppKit
import ApplicationServices
import KeyTestCore

enum UIStrings {
    static let resetRow = "키보드 초기화"
    static let resetButton = "초기화"
    static let soundRow = "키 소리"
    static let volumeRow = "음량"
    static let transposeRow = "전조"
    static let waveformRow = "파형"
    static let modeRow = "모드"

    /// 권한이 없을 때 창 위쪽에 띄우는 안내. 권한이 충분하면 nil.
    static func permissionBanner(_ permission: TapPermission) -> String? {
        switch permission {
        case .granted:
            return nil
        case .missingAccessibility:
            return "조합키(Cmd+Tab 등)를 가로채려면 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 KeyTest를 허용하세요."
        case .missingInputMonitoring:
            return "키 입력을 감지하려면 시스템 설정 → 개인정보 보호 및 보안 → 입력 모니터링에서 KeyTest를 허용하세요."
        case .missingBoth:
            return "조합키(Cmd+Tab 등)를 가로채려면 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용 / 입력 모니터링에서 KeyTest를 허용하세요."
        }
    }
}

enum Permission {
    static func current() -> TapPermission {
        TapPermission.classify(accessibilityTrusted: AXIsProcessTrusted(),
                               inputMonitoringAllowed: CGPreflightListenEventAccess())
    }

    /// 앱 실행 때 한 번, 시스템 승인 창을 띄운다 (사용자가 직접 승인한다).
    static func requestPrompts() {
        _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        _ = CGRequestListenEventAccess()
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
