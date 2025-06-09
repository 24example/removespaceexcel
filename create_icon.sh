#!/bin/bash

# Создаем базовое изображение 1024x1024 с зеленым фоном (#217346)
convert -size 1024x1024 xc:#217346 base.png

# Добавляем букву E белым цветом
convert base.png -gravity center -pointsize 600 -font Arial-Bold -fill white -annotate +0-100 'E' text.png

# Добавляем слово "очистка" мелким шрифтом под буквой E
convert text.png -gravity center -pointsize 120 -font Arial -fill white -annotate +0+200 'очистка' text_with_subtitle.png

# Добавляем символ очистки (метла) в верхнем правом углу
convert text_with_subtitle.png -gravity northeast -pointsize 300 -font Arial-Unicode-MS -fill white -annotate +50+50 '🧹' icon_1024.png

# Создаем различные размеры для macOS
convert icon_1024.png -resize 16x16 icon_16.png
convert icon_1024.png -resize 32x32 icon_32.png
convert icon_1024.png -resize 48x48 icon_48.png
convert icon_1024.png -resize 128x128 icon_128.png
convert icon_1024.png -resize 256x256 icon_256.png
convert icon_1024.png -resize 512x512 icon_512.png

# Создаем .icns файл для macOS
mkdir -p icon.iconset
mv icon_16.png icon.iconset/icon_16x16.png
mv icon_32.png icon.iconset/icon_32x32.png
mv icon_48.png icon.iconset/icon_48x48.png
mv icon_128.png icon.iconset/icon_128x128.png
mv icon_256.png icon.iconset/icon_256x256.png
mv icon_512.png icon.iconset/icon_512x512.png
cp icon_1024.png icon.iconset/icon_1024x1024.png

iconutil -c icns icon.iconset -o assets/icon.icns

# Создаем .ico файл для Windows
convert icon_1024.png -define icon:auto-resize=16,32,48,256 assets/icon.ico

# Очистка временных файлов
rm -rf icon.iconset base.png text.png text_with_subtitle.png icon_1024.png 