from PIL import Image, ImageDraw
import math

SIZE = 1024
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

cx = SIZE // 2   # 512

# 머리 작게 + 전체 캐릭터 원 가운데 정렬
# 귀 상단: head_cy - 205 / 발 하단: head_cy + 342  → 중심: head_cy + 68
# 원 중심 512 → head_cy = 512 - 68 = 444
head_r  = 162
head_cy = 444

# ── 배경 원 ──────────────────────────────────────────
draw.ellipse([10, 10, SIZE-10, SIZE-10], fill=(228, 255, 236, 255))

# ── 점프 반짝 효과선 (발 아래) ────────────────────────
sc_y = head_cy + 350   # 발 바로 아래
for angle in [35, 55, 75, 95, 115, 135]:
    rad = math.radians(angle)
    x1 = int(cx + 52 * math.cos(rad))
    y1 = int(sc_y + 20 * math.sin(rad))
    x2 = int(cx + 88 * math.cos(rad))
    y2 = int(sc_y + 34 * math.sin(rad))
    draw.line([x1, y1, x2, y2], fill=(3, 199, 90, 190), width=5)

# 그림자
shadow = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
sd = ImageDraw.Draw(shadow)
sd.ellipse([cx-88, sc_y-14, cx+88, sc_y+14], fill=(0,0,0,30))
img = Image.alpha_composite(img, shadow)
draw = ImageDraw.Draw(img)

# ── 귀 ───────────────────────────────────────────────
ear_r = 76
draw.ellipse([cx-248, head_cy-202, cx-248+ear_r*2, head_cy-202+ear_r*2], fill=(30,30,30))
draw.ellipse([cx+248-ear_r*2, head_cy-202, cx+248, head_cy-202+ear_r*2],  fill=(30,30,30))
draw.ellipse([cx-238, head_cy-192, cx-238+54, head_cy-192+54], fill=(62,62,62))
draw.ellipse([cx+238-54, head_cy-192, cx+238, head_cy-192+54],  fill=(62,62,62))

# ── 머리 ─────────────────────────────────────────────
draw.ellipse([cx-head_r, head_cy-head_r, cx+head_r, head_cy+head_r], fill=(255,255,255))

# ── 눈 패치 ──────────────────────────────────────────
draw.ellipse([cx-155, head_cy-105, cx-48, head_cy+8],  fill=(30,30,30))
draw.ellipse([cx+48,  head_cy-105, cx+155, head_cy+8], fill=(30,30,30))

# ── 눈웃음 (흰 ∩ arc) ────────────────────────────────
draw.arc([cx-148, head_cy-96, cx-54, head_cy-8],  start=195, end=345, fill=(255,255,255), width=18)
draw.arc([cx+54,  head_cy-96, cx+148, head_cy-8], start=195, end=345, fill=(255,255,255), width=18)
draw.ellipse([cx-132, head_cy-80, cx-117, head_cy-65], fill=(255,255,255))
draw.ellipse([cx+117, head_cy-80, cx+132, head_cy-65], fill=(255,255,255))

# ── 코 ───────────────────────────────────────────────
draw.ellipse([cx-24, head_cy+18, cx+24, head_cy+44], fill=(30,30,30))

# ── 웃는 입 ──────────────────────────────────────────
draw.arc([cx-58, head_cy+40, cx+58, head_cy+90], start=10, end=170, fill=(30,30,30), width=12)
draw.ellipse([cx-68, head_cy+48, cx-48, head_cy+66], fill=(255,200,190))
draw.ellipse([cx+48, head_cy+48, cx+68, head_cy+66], fill=(255,200,190))

# ── 볼 홍조 ──────────────────────────────────────────
blush = Image.new("RGBA", (SIZE, SIZE), (0,0,0,0))
bd = ImageDraw.Draw(blush)
bd.ellipse([cx-190, head_cy+20, cx-82, head_cy+60],  fill=(255,110,110,108))
bd.ellipse([cx+82,  head_cy+20, cx+190, head_cy+60], fill=(255,110,110,108))
img = Image.alpha_composite(img, blush)
draw = ImageDraw.Draw(img)

# ── 몸통 ─────────────────────────────────────────────
shoulder_y = head_cy + head_r - 32   # ≈ 574
body_h = 105
body_w = 100
draw.ellipse([cx-body_w, shoulder_y, cx+body_w, shoulder_y+body_h], fill=(255,255,255))
draw.ellipse([cx-body_w+26, shoulder_y+13, cx+body_w-26, shoulder_y+body_h-5], fill=(245,245,245))

# ── 왼팔 (어깨 수평) ──────────────────────────────────
arm_y   = shoulder_y + 16
arm_top = arm_y - 26
arm_bot = arm_y + 26
draw.ellipse([cx-body_w-140, arm_top, cx-body_w+10, arm_bot+7], fill=(30,30,30))
draw.ellipse([cx-body_w-178, arm_top-9, cx-body_w-100, arm_bot+17], fill=(30,30,30))

# ── 오른팔 (어깨 수평) ───────────────────────────────
draw.ellipse([cx+body_w-10, arm_top, cx+body_w+140, arm_bot+7], fill=(30,30,30))
draw.ellipse([cx+body_w+100, arm_top-9, cx+body_w+178, arm_bot+17], fill=(30,30,30))

# ── 밥그릇 (왼손) ────────────────────────────────────
bx = cx - body_w - 142
by = arm_y + 14
draw.ellipse([bx-50, by-40, bx+50, by+10], fill=(255,255,255))
draw.ellipse([bx-42, by-48, bx+42, by+2],  fill=(252,250,246))
for ddx, ddy in [(-20,-4),(0,-12),(20,0),(-8,8),(18,-6)]:
    draw.ellipse([bx+ddx-4, by+ddy-3, bx+ddx+4, by+ddy+3], fill=(238,235,225))
draw.ellipse([bx-52, by+5,  bx+52, by+52], fill=(248,192,58))
draw.rectangle([bx-52, by+26, bx+52, by+52], fill=(248,192,58))
draw.ellipse([bx-52, by+34, bx+52, by+62], fill=(212,162,36))
draw.arc([bx-52, by+5, bx+52, by+52], start=0, end=180, fill=(172,126,18), width=4)

# ── 젓가락 (오른손) ──────────────────────────────────
jx = cx + body_w + 142
jy = arm_y - 52
draw.rectangle([jx-12, jy,    jx-5,  jy+100], fill=(158,88,26), outline=(112,62,16), width=2)
draw.rectangle([jx+3,  jy-14, jx+10, jy+86],  fill=(158,88,26), outline=(112,62,16), width=2)
draw.ellipse([jx-15, jy+92, jx-2,  jy+104], fill=(255,138,68))
draw.ellipse([jx,    jy+78, jx+12, jy+90],  fill=(255,138,68))

# ── 다리 (짧고 벌어진 점프) ──────────────────────────
body_bot = shoulder_y + body_h   # ≈ 679
leg_w = 46
leg_h = 75
draw.ellipse([cx-leg_w*2-8, body_bot-8, cx-8, body_bot+leg_h-8], fill=(30,30,30))
draw.ellipse([cx-leg_w*2-20, body_bot+leg_h-20, cx-2, body_bot+leg_h+22], fill=(30,30,30))
draw.ellipse([cx+8, body_bot-8, cx+leg_w*2+8, body_bot+leg_h-8], fill=(30,30,30))
draw.ellipse([cx+2, body_bot+leg_h-20, cx+leg_w*2+20, body_bot+leg_h+22], fill=(30,30,30))

# ── 테두리 ───────────────────────────────────────────
draw.ellipse([10, 10, SIZE-10, SIZE-10], outline=(3,199,90,255), width=26)

import os; os.makedirs("assets/icon", exist_ok=True)
img.save("assets/icon/app_icon.png")
print("Saved!")
