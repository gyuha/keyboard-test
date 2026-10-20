import Foundation

/// 맥 키보드의 미디어 키 (NX_KEYTYPE_* 값).
public enum MediaKey: Int, Equatable {
    case volumeUp = 0
    case volumeDown = 1
    case mute = 7
}

public struct KeyCell: Equatable {
    public let id: String
    public let label: String
    /// 키캡에 위에서 아래로 그릴 글자 (기호 키는 두 줄)
    public let caption: [String]
    public let row: Int
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public let keyCodes: [Int]
    public let media: MediaKey?
}

/// 참고 이미지의 108키 레이아웃. 단위는 키 한 칸 = 1.0.
/// 대응: Alt=Option, Win=Command, Print/Scroll/Pause=F13/F14/F15, Ins=Help, Del=Forward Delete,
/// N.Lck=키패드 Clear, Menu=Fn (맥에는 Menu 키가 없다), Sleep은 맥 일반 키보드에 없어 켜지지 않는다.
public enum Layout {
    public static let width = 22.5
    public static let height = 6.5

    public static let rows: [[KeyCell]] = build()
    public static let all: [KeyCell] = rows.flatMap { $0 }

    public static func cell(id: String) -> KeyCell? {
        all.first { $0.id == id }
    }

    public static func cell(forKeyCode code: Int) -> KeyCell? {
        keyCodeIndex[code]
    }

    public static func cell(forMedia key: MediaKey) -> KeyCell? {
        all.first { $0.media == key }
    }

    private static let keyCodeIndex: [Int: KeyCell] = {
        var index: [Int: KeyCell] = [:]
        for cell in all {
            for code in cell.keyCodes { index[code] = cell }
        }
        return index
    }()

    private static func build() -> [[KeyCell]] {
        var result: [[KeyCell]] = []
        for row in 0...5 {
            var cells: [KeyCell] = []
            let y = row == 0 ? 0.0 : 0.5 + Double(row)
            func k(_ label: String, _ x: Double, w: Double = 1, h: Double = 1,
                   caption: [String]? = nil, id: String? = nil,
                   codes: [Int] = [], media: MediaKey? = nil) {
                cells.append(KeyCell(id: id ?? label, label: label, caption: caption ?? [label],
                                     row: row, x: x, y: y, width: w, height: h,
                                     keyCodes: codes, media: media))
            }
            switch row {
            case 0:
                k("Esc", 0, codes: [53])
                let fCodes = [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111]
                let fX: [Double] = [2, 3, 4, 5, 6.5, 7.5, 8.5, 9.5, 11, 12, 13, 14]
                for i in 0..<12 { k("F\(i + 1)", fX[i], codes: [fCodes[i]]) }
                k("Print", 15.25, codes: [105])
                k("Scroll", 16.25, codes: [107])
                k("Pause", 17.25, codes: [113])
                k("Sleep", 18.5)
                k("Mute", 19.5, media: .mute)
                k("Vol-", 20.5, media: .volumeDown)
                k("Vol+", 21.5, media: .volumeUp)
            case 1:
                k("~", 0, caption: ["~", "`"], codes: [50])
                let top = ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"]
                let digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
                let dCodes = [18, 19, 20, 21, 23, 22, 26, 28, 25, 29]
                for i in 0..<10 { k(digits[i], Double(i + 1), caption: [top[i], digits[i]], codes: [dCodes[i]]) }
                k("-", 11, caption: ["_", "-"], codes: [27])
                k("=", 12, caption: ["+", "="], codes: [24])
                k("Backspace", 13, w: 2, codes: [51])
                k("Ins", 15.25, codes: [114])
                k("Home", 16.25, codes: [115])
                k("PgUp", 17.25, codes: [116])
                k("N.Lck", 18.5, codes: [71])
                k("÷", 19.5, id: "Num÷", codes: [75])
                k("×", 20.5, id: "Num×", codes: [67])
                k("−", 21.5, id: "Num−", codes: [78])
            case 2:
                k("Tab", 0, w: 1.5, codes: [48])
                let letters = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
                let lCodes = [12, 13, 14, 15, 17, 16, 32, 34, 31, 35]
                for i in 0..<10 { k(letters[i], 1.5 + Double(i), codes: [lCodes[i]]) }
                k("{", 11.5, caption: ["{", "["], codes: [33])
                k("}", 12.5, caption: ["}", "]"], codes: [30])
                k("|", 13.5, w: 1.5, caption: ["|", "\\"], codes: [42])
                k("Del", 15.25, codes: [117])
                k("End", 16.25, codes: [119])
                k("PgDn", 17.25, codes: [121])
                k("7", 18.5, id: "Num7", codes: [89])
                k("8", 19.5, id: "Num8", codes: [91])
                k("9", 20.5, id: "Num9", codes: [92])
                k("+", 21.5, h: 2, id: "Num+", codes: [69])
            case 3:
                k("Caps Lock", 0, w: 1.75, codes: [57])
                let letters = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
                let lCodes = [0, 1, 2, 3, 5, 4, 38, 40, 37]
                for i in 0..<9 { k(letters[i], 1.75 + Double(i), codes: [lCodes[i]]) }
                k(";", 10.75, caption: [":", ";"], codes: [41])
                k("'", 11.75, caption: ["\"", "'"], codes: [39])
                k("Enter", 12.75, w: 2.25, codes: [36])
                k("4", 18.5, id: "Num4", codes: [86])
                k("5", 19.5, id: "Num5", codes: [87])
                k("6", 20.5, id: "Num6", codes: [88])
            case 4:
                k("Left Shift", 0, w: 2.25, codes: [56])
                let letters = ["Z", "X", "C", "V", "B", "N", "M"]
                let lCodes = [6, 7, 8, 9, 11, 45, 46]
                for i in 0..<7 { k(letters[i], 2.25 + Double(i), codes: [lCodes[i]]) }
                k(",", 9.25, caption: ["<", ","], codes: [43])
                k(".", 10.25, caption: [">", "."], codes: [47])
                k("/", 11.25, caption: ["?", "/"], codes: [44])
                k("Right Shift", 12.25, w: 2.75, codes: [60])
                k("↑", 16.25, codes: [126])
                k("1", 18.5, id: "Num1", codes: [83])
                k("2", 19.5, id: "Num2", codes: [84])
                k("3", 20.5, id: "Num3", codes: [85])
                k("N.Ent", 21.5, h: 2, codes: [76])
            default:
                k("LCtl", 0, w: 1.25, codes: [59])
                k("LWin", 1.25, w: 1.25, codes: [55])
                k("LAlt", 2.5, w: 1.25, codes: [58])
                k("Space", 3.75, w: 6.25, codes: [49])
                k("RAlt", 10, w: 1.25, codes: [61])
                k("RWin", 11.25, w: 1.25, codes: [54])
                k("Menu", 12.5, w: 1.25, codes: [63])
                k("RCtl", 13.75, w: 1.25, codes: [62])
                k("←", 15.25, codes: [123])
                k("↓", 16.25, codes: [125])
                k("→", 17.25, codes: [124])
                k("0", 18.5, w: 2, id: "Num0", codes: [82])
                k(".", 20.5, id: "Num.", codes: [65])
            }
            result.append(cells)
        }
        return result
    }
}
