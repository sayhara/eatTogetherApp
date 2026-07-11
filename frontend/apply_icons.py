from PIL import Image
import os

src = "assets/icon/app_icon.png"
img = Image.open(src).convert("RGBA")

# Android mipmap sizes
android_sizes = {
    "mipmap-mdpi":    48,
    "mipmap-hdpi":    72,
    "mipmap-xhdpi":   96,
    "mipmap-xxhdpi":  144,
    "mipmap-xxxhdpi": 192,
}

for folder, size in android_sizes.items():
    path = f"android/app/src/main/res/{folder}"
    os.makedirs(path, exist_ok=True)
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(f"{path}/ic_launcher.png")
    resized.save(f"{path}/ic_launcher_round.png")
    print(f"Android {folder}: {size}x{size}")

# iOS AppIcon sizes
ios_sizes = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]

ios_path = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
os.makedirs(ios_path, exist_ok=True)
for fname, size in ios_sizes:
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(f"{ios_path}/{fname}")
    print(f"iOS {fname}: {size}x{size}")

print("\n모든 아이콘 생성 완료!")
