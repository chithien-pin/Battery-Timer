# BattTimer

Countdown timer luôn nổi trên cùng (always-on-top widget) cho macOS 13+, viết bằng **SwiftUI + AppKit**, kiến trúc **MVVM**.

## Tính năng

### Cốt lõi

- Nhiều timer cùng lúc — mỗi timer một cửa sổ floating riêng
- Start / Pause / Reset / +1 phút / +5 phút
- Nhập thời lượng (giờ:phút:giây) hoặc hẹn đến một giờ cụ thể trong ngày
- Cửa sổ borderless, kéo được, resize tự do — font số co giãn theo `GeometryReader`
- Lưu vị trí & kích thước cửa sổ (kèm multi-display `screenID`) qua `UserDefaults`
- Click-through (chuột xuyên qua) khi chỉ xem
- Âm thanh hệ thống + nhấp nháy / shake khi hết giờ
- Notification Center (tuỳ chọn bypass Focus / DND bằng time-sensitive)



### Bổ sung

- **Menu bar** icon — quick create preset, start/pause, xem countdown
- Preset: Pomodoro 25’, Short Break 5’, Long Break 15’, Boil Egg 7’, Focus Hour, Quick 1’
- Theme: System / Ocean / Ember / Forest / Midnight / Mono
- Display modes: Normal · Compact · **HUD** (nền trong suốt)
- Global hotkeys: `⌘⇧T` start/pause · `⌘⇧=` +1 phút · `⌘⇧N` timer mới
- Lịch sử timer đã chạy
- Float trên fullscreen app (tuỳ chọn `.screenSaver` level)



## Kiến trúc

```
BattTimer/
├── App/                  # @main + AppDelegate
├── Models/               # TimerModel, Theme, Preset, History
├── ViewModels/           # TimerViewModel, AppViewModel
├── Views/                # SwiftUI UI + sheets
├── Window/               # FloatingPanel (NSPanel), WindowManager
├── Services/             # Sound, Notification, HotKey, Persistence, MenuBar
└── Utilities/            # TimeFormatter, ShakeEffect
```


| Thành phần       | Vai trò                                           |
| ---------------- | ------------------------------------------------- |
| `TimerModel`     | Dữ liệu thuần Codable                             |
| `TimerViewModel` | Tick theo wall-clock `endDate`, Start/Pause/Reset |
| `AppViewModel`   | CRUD timers, prefs, history, nối services         |
| `WindowManager`  | Tạo / cập nhật / đóng `FloatingPanel`             |
| `FloatingPanel`  | `NSPanel` level `.floating` / `.screenSaver`      |




## Yêu cầu

- macOS 13.0+
- Xcode 15+ (Swift 5.9+)



## Build & Run bằng Xcode

1. Mở project:
  ```bash
   open /Users/BattTimer/BattTimer.xcodeproj
  ```
2. Chọn scheme **BattTimer** và destination **My Mac**.
3. Nếu được hỏi, chọn Development Team trong **Signing & Capabilities** (bật Automatically manage signing).
4. Nhấn **⌘R** để chạy.

Lần đầu chạy:

- macOS hỏi quyền **Notifications** → Allow.
- Để dùng **global hotkey** khi app không focus: System Settings → Privacy & Security → **Accessibility** → bật BattTimer.



## Build `.app` từ Terminal

```bash
cd /Users/batterypin/Desktop/BattTimer

xcodebuild \
  -project BattTimer.xcodeproj \
  -scheme BattTimer \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES

# App nằm tại:
open build/Build/Products/Release/BattTimer.app
```

Copy `BattTimer.app` vào `/Applications` nếu muốn dùng lâu dài.

## Cách dùng nhanh


| Hành động         | Cách làm                                                |
| ----------------- | ------------------------------------------------------- |
| Tạo timer         | Menu bar → **New Timer…** hoặc preset                   |
| Pause/Start       | Nút ▶/⏸ trên cửa sổ, hoặc `⌘⇧T`                         |
| Đổi HUD / Compact | Double-click cửa sổ, hoặc right-click → Display         |
| Click-through     | Right-click → Click-through (tắt bằng menu bar nếu cần) |
| Đóng timer        | Nút ✕ hoặc Remove trong context menu                    |




## Ghi chú kỹ thuật

- Timer tick dựa trên `endDate` (wall-clock), không cộng dồn delta — chính xác sau khi máy sleep.
- `LSUIElement = true` — app không hiện icon Dock mặc định; mở lại bằng click icon menu bar hoặc mở lại app.
- Sandbox bật; system sounds đọc từ `/System/Library/Sounds`.

