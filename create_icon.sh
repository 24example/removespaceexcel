#!/bin/bash

# Создаем базовое изображение 1024x1024 с зеленым фоном (#217346)
# Используем высокое качество и антиалиасинг
convert -size 1024x1024 xc:#217346 -quality 100 base.png

# Добавляем букву E белым цветом с увеличенным размером и лучшим позиционированием
# Используем -kerning для лучшего рендеринга
convert base.png -gravity center \
    -pointsize 720 \
    -font Arial-Bold \
    -fill white \
    -kerning -10 \
    -antialias \
    -annotate +0-80 'E' text.png

# Добавляем слово "очистка" мелким шрифтом под буквой E
convert text.png -gravity center \
    -pointsize 140 \
    -font Arial \
    -fill white \
    -antialias \
    -annotate +0+280 'очистка' text_with_subtitle.png

# Добавляем символ очистки (метла) в верхнем правом углу
# Уменьшаем отступ и увеличиваем размер символа
convert text_with_subtitle.png -gravity northeast \
    -pointsize 350 \
    -font Arial-Unicode-MS \
    -fill white \
    -antialias \
    -annotate +30+30 '🧹' icon_1024.png

# Применяем финальную обработку для улучшения качества
convert icon_1024.png \
    -filter Lanczos \
    -define filter:blur=0.8 \
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
rm -rf icon.iconset base.png text.png text_with_subtitle.png icon_1024.png icon_1024_final.png icon_*.png 