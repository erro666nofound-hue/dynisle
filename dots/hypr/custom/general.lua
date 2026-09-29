-- Tắt màn hình cảm ứng (Atmel, USB 03eb:8b03) vì bị lỗi, tự chạm lung tung.
-- Muốn bật lại: đổi enabled = false thành true (hoặc xoá khối này).
hl.device({
    name    = "atmel",
    enabled = false,
})

-- Phím F10 "ma" (2026-09-29). Bàn phím của CHÍNH laptop này (ASUS TP300LAB)
-- tự bấm F10 khi gõ chữ, nhất là chữ "e" - hỏng phần cứng, đo được 28 lần
-- trong 3 phút. F10 làm Chrome nhảy lên menu, Shift+F10 mở menu chuột phải
-- trong Discord, và Roblox tăng đồ hoạ.
-- Gắn F10 vào một lệnh rỗng thì Hyprland NUỐT nó, không app nào nhận được.
-- Chỉ bật trên đúng máy này, nên máy khác cài từ repo vẫn giữ F10.
local product = io.open("/sys/class/dmi/id/product_name", "r")
local model = product and product:read("*l") or ""
if product then product:close() end
if model == "TP300LAB" then
    for _, mods in ipairs({ "", "SHIFT + ", "CTRL + ", "ALT + ", "CTRL + SHIFT + " }) do
        hl.bind(mods .. "F10", hl.dsp.exec_cmd("true"), { description = "Nuốt phím F10 ma" })
    end
end
