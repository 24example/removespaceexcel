#!/bin/bash

# Создаем базовое изображение 1024x1024 с градиентным фоном
# Используем градиент от темно-зеленого к светло-зеленому для глубины
convert -size 1024x1024 \
    radial-gradient:'#2E8B57'-'#217346' \
    -quality 100 base.png

# Добавляем легкую текстуру/шум для профессионального вида
convert base.png \
    -attenuate 0.1 \
    +noise Gaussian \
    base_textured.png

# Создаем округлую форму с тенью для современного вида
convert -size 1024x1024 xc:transparent \
    -fill white \
    -draw "roundrectangle 100,100 924,924 80,80" \
    mask.png

# Применяем маску к фону
convert base_textured.png mask.png \
    -alpha off -compose CopyOpacity -composite \
    rounded_base.png

# Добавляем мягкую тень
convert rounded_base.png \
    \( +clone -background black -shadow 80x20+0+15 \) \
    +swap -background transparent -layers merge +repage \
    shadowed_base.png

# Создаем букву E с эффектом 3D
convert -size 1024x1024 xc:transparent \
    -gravity center \
    -pointsize 600 \
    -font Arial-Bold \
    -fill white \
    -stroke '#E8F5E9' \
    -strokewidth 3 \
    -kerning -20 \
    -antialias \
    -annotate +0-50 'E' \
    letter_e.png

# Добавляем внутреннюю тень к букве E для объема
convert letter_e.png \
    -channel A -morphology Distance Euclidean:1,10 \
    -level 0,5% \
    -negate \
    letter_e_shadow.png

# Объединяем букву с тенью
convert shadowed_base.png letter_e.png \
    -compose over -composite \
    with_letter.png

# Добавляем текст "EXCEL" сверху мелким шрифтом
convert with_letter.png \
    -gravity north \
    -pointsize 90 \
    -font Arial \
    -fill '#E8F5E9' \
    -antialias \
    -annotate +0+180 'EXCEL' \
    with_excel.png

# Добавляем текст "CLEANER" снизу
convert with_excel.png \
    -gravity south \
    -pointsize 90 \
    -font Arial \
    -fill '#E8F5E9' \
    -antialias \
    -annotate +0+180 'CLEANER' \
    with_cleaner.png

# Добавляем стилизованный символ очистки (звездочки) вокруг буквы E
convert with_cleaner.png \
    -gravity northwest \
    -pointsize 120 \
    -font Arial \
    -fill '#90EE90' \
    -antialias \
    -annotate +250+350 '✦' \
    with_star1.png

convert with_star1.png \
    -gravity northeast \
    -pointsize 100 \
    -font Arial \
    -fill '#98FB98' \
    -antialias \
    -annotate +280+400 '✧' \
    with_star2.png

convert with_star2.png \
    -gravity southeast \
    -pointsize 80 \
    -font Arial \
    -fill '#90EE90' \
    -antialias \
    -annotate +320+420 '✦' \
    icon_1024.png

# Применяем финальную обработку для улучшения качества
convert icon_1024.png \
    -filter Lanczos \
    -define filter:blur=0.9 \
    -sharpen 0x0.5 \
    -quality 100 \
    icon_1024_final.png

# Создаем различные размеры для macOS с высоким качеством
convert icon_1024_final.png -filter Lanczos -resize 16x16 -quality 100 icon_16.png
convert icon_1024_final.png -filter Lanczos -resize 32x32 -quality 100 icon_32.png
convert icon_1024_final.png -filter Lanczos -resize 48x48 -quality 100 icon_48.png
convert icon_1024_final.png -filter Lanczos -resize 128x128 -quality 100 icon_128.png
convert icon_1024_final.png -filter Lanczos -resize 256x256 -quality 100 icon_256.png
convert icon_1024_final.png -filter Lanczos -resize 512x512 -quality 100 icon_512.png

# Создаем версии @2x для Retina дисплеев
convert icon_1024_final.png -filter Lanczos -resize 32x32 -quality 100 icon_16@2x.png
convert icon_1024_final.png -filter Lanczos -resize 64x64 -quality 100 icon_32@2x.png
convert icon_1024_final.png -filter Lanczos -resize 256x256 -quality 100 icon_128@2x.png
convert icon_1024_final.png -filter Lanczos -resize 512x512 -quality 100 icon_256@2x.png
convert icon_1024_final.png -filter Lanczos -resize 1024x1024 -quality 100 icon_512@2x.png

# Создаем .icns файл для macOS
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
cp icon_1024_final.png icon.iconset/icon_512x512@2x.png

iconutil -c icns icon.iconset -o assets/icon.icns

# Создаем .ico файл для Windows с высоким качеством
convert icon_1024_final.png \
    -define icon:auto-resize=16,24,32,48,64,128,256 \
    -compress none \
    assets/icon.ico

# Создаем PNG версию для общего использования
cp icon_1024_final.png assets/icon.png

# Очистка временных файлов
rm -rf icon.iconset base.png base_textured.png mask.png rounded_base.png shadowed_base.png letter_e.png letter_e_shadow.png with_letter.png with_excel.png with_cleaner.png with_star1.png with_star2.png icon_1024.png icon_1024_final.png icon_*.png 