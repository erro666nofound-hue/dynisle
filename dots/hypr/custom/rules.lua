-- ######## Lumen ########
-- Chuyển từ ~/.config/hypr/lumen.conf sang đây 2026-08-29: illogical-impulse
-- không có hyprland.conf nữa, cấu hình chạy bằng Lua, nên file .conf cũ mồ côi.

-- Hyprland nhân decoration:active_opacity lên MỌI cửa sổ. Lumen đã tự đặt độ
-- trong cho nền của nó (Theme.surfaceAlpha) — không có luật này thì hai lớp mờ
-- chồng nhau và chữ chìm vào wallpaper. Blur không phụ thuộc luật này.
hl.window_rule({match = {class = "^(com\\.toast\\.Lumen)$"},    opacity = 1.0})

-- Không tắt màn hình khi đang nghe nhạc toàn màn hình.
hl.window_rule({match = {class = "^(com\\.toast\\.Lumen)$"},    idle_inhibit = "fullscreen"})

-- Mini Lumen: cùng tiến trình nên cùng class với cửa sổ lớn — phân biệt bằng
-- TIÊU ĐỀ. Không cho nổi thì Hyprland tile nó ra full màn, vì lúc đó cửa sổ lớn
-- đang ẩn và Mini là cửa sổ duy nhất của workspace.
hl.window_rule({match = {title = "^(Mini Lumen)$"},             float = true})
hl.window_rule({match = {title = "^(Mini Lumen)$"},             size = {"660", "320"}})

-- ######## dynisle ########
-- The wallpaper picker asks the XDG portal for a directory - the same dialog
-- the browser gets for a file upload. The browser's floats on its own because
-- it is a MODAL of the browser window; ours has no parent window, so it comes
-- up as a plain toplevel and Hyprland tiles it, shoved against the screen edge
-- with half the dialog cut off. A file dialog tiled into the layout is not a
-- file dialog.
hl.window_rule({match = {class = "^(xdg-desktop-portal-gtk)$"}, float = true})
hl.window_rule({match = {class = "^(xdg-desktop-portal-gtk)$"}, size = {"900", "620"}})
hl.window_rule({match = {class = "^(xdg-desktop-portal-gtk)$"}, center = true})
