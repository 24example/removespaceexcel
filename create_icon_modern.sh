#!/bin/bash

# Современная минималистичная версия иконки Excel Cleaner

# Создаем базовое изображение с плоским дизайном
convert -size 1024x1024 xc:'#2E8B57' base.png

# Создаем белый круг в центре для контраста (увеличенный размер)
convert base.png \
    -fill white \
    -draw "circle 512,512 512,80" \
    with_circle.png

# Создаем букву C из кружочков (внешняя)
convert with_circle.png \
    -fill '#2E8B57' \
    -draw "circle 300,350 300,380" \
    -draw "circle 280,420 280,450" \
    -draw "circle 270,500 270,530" \
    -draw "circle 280,580 280,610" \
    -draw "circle 300,650 300,680" \
    -draw "circle 340,710 340,740" \
    -draw "circle 400,740 400,770" \
    -draw "circle 470,750 470,780" \
    -draw "circle 540,750 540,780" \
    -draw "circle 610,740 610,770" \
    -draw "circle 670,710 670,740" \
    -draw "circle 710,650 710,680" \
    -draw "circle 340,290 340,320" \
    -draw "circle 400,260 400,290" \
    -draw "circle 470,250 470,280" \
    -draw "circle 540,250 540,280" \
    -draw "circle 610,260 610,290" \
    -draw "circle 670,290 670,320" \
    with_c.png

# Создаем букву E из кружочков (внутри C)
# Вертикальная линия
convert with_c.png \
    -fill '#2E8B57' \
    -draw "circle 420,380 420,400" \
    -draw "circle 420,440 420,460" \
    -draw "circle 420,500 420,520" \
    -draw "circle 420,560 420,580" \
    -draw "circle 420,620 420,640" \
    with_e_vertical.png

# Горизонтальные линии буквы E
convert with_e_vertical.png \
    -fill '#2E8B57' \
    -draw "circle 480,380 480,400" \
    -draw "circle 540,380 540,400" \
    -draw "circle 480,500 480,520" \
    -draw "circle 540,500 540,520" \
    -draw "circle 480,620 480,640" \
    -draw "circle 540,620 540,640" \
    icon_modern.png

# Применяем скругление углов для современного вида (меньший радиус)
convert icon_modern.png \
    \( +clone -alpha extract \
    -draw 'fill black polygon 0,0 0,60 60,0 fill white circle 60,60 60,0' \
    \( +clone -flip \) -compose Multiply -composite \
    \( +clone -flop \) -compose Multiply -composite \
    \) -alpha off -compose CopyOpacity -composite \
    icon_1024_final.png

# Создаем различные размеры
for size in 16 32 48 128 256 512; do
    convert icon_1024_final.png -filter Lanczos -resize ${size}x${size} -quality 100 icon_${size}.png
done

# Создаем версии @2x для Retina
convert icon_1024_final.png -filter Lanczos -resize 32x32 -quality 100 icon_16@2x.png
convert icon_1024_final.png -filter Lanczos -resize 64x64 -quality 100 icon_32@2x.png
convert icon_1024_final.png -filter Lanczos -resize 256x256 -quality 100 icon_128@2x.png
convert icon_1024_final.png -filter Lanczos -resize 512x512 -quality 100 icon_256@2x.png
convert icon_1024_final.png -filter Lanczos -resize 1024x1024 -quality 100 icon_512@2x.png

# Создаем .icns для macOS
mkdir -p icon.iconset
cp icon_16.png icon.iconset/icon_16x16.png
cp icon_16@2x.png icon.iconset/icon_16x16@2x.png
cp icon_32.png icon.iconset/icon_32x32.png
cp icon_32@2x.png icon.iconset/icon_32x32@2x.png
cp icon_128.png icon.iconset/icon_128x128.png
cp icon_128@2x.png icon.iconset/icon_128x128@2x.png
cp icon_256.png icon.iconset/icon_256x256.png
cp icon_256@2x.png icon.iconset/icon_256x256@2x.png
cp icon_512.png icon.iconset/icon_512x512.png
cp icon_512@2x.png icon.iconset/icon_512x512@2x.png

# Сохраняем как основные файлы иконок
iconutil -c icns icon.iconset -o assets/icon.icns

# Создаем .ico для Windows
convert icon_1024_final.png \
    -define icon:auto-resize=16,24,32,48,64,128,256 \
    -compress none \
    assets/icon.ico

# Создаем PNG версию
cp icon_1024_final.png assets/icon.png

# Очистка
rm -rf icon.iconset base.png with_circle.png with_c.png with_e_vertical.png icon_modern.png icon_1024_final.png icon_*.png 