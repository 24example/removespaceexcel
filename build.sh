#!/bin/bash

# Версия приложения
VERSION="1.0.0"

# Создаем директорию для бинарных файлов если её нет
mkdir -p build

# Общие флаги линковщика
COMMON_LDFLAGS="-s -w -X main.Version=$VERSION"

# Генерируем ресурсы для Windows перед сборкой
echo "Generating Windows resources..."
GOVERSIONINFO="$HOME/go/bin/goversioninfo"
if [ -f "$GOVERSIONINFO" ]; then
    $GOVERSIONINFO -icon=assets/icon.ico -manifest=assets/excel-cleaner.manifest -o=resource_windows_amd64.syso assets/versioninfo.json
elif command -v goversioninfo &> /dev/null; then
    goversioninfo -icon=assets/icon.ico -manifest=assets/excel-cleaner.manifest -o=resource_windows_amd64.syso assets/versioninfo.json
else
    echo "Warning: goversioninfo not found. Install it with: go install github.com/josephspurrier/goversioninfo/cmd/goversioninfo@latest"
fi

# Сборка для Windows (64-bit) с GUI режимом и иконкой
echo "Building for Windows (64-bit)..."
GOOS=windows GOARCH=amd64 go build -tags "!console" -ldflags="$COMMON_LDFLAGS -H=windowsgui" -o build/ExcelCleaner.exe

# Удаляем .syso файл после сборки Windows
rm -f resource_windows_amd64.syso

# Сборка для macOS (64-bit)
echo "Building for macOS (64-bit)..."
mkdir -p build/ExcelCleaner.app/Contents/MacOS
mkdir -p build/ExcelCleaner.app/Contents/Resources
GOOS=darwin GOARCH=amd64 go build -tags "!console" -ldflags="$COMMON_LDFLAGS" -o build/ExcelCleaner.app/Contents/MacOS/ExcelCleaner

# Копируем иконку для macOS
cp assets/icon.icns build/ExcelCleaner.app/Contents/Resources/

# Сборка для Linux (64-bit)
echo "Building for Linux (64-bit)..."
GOOS=linux GOARCH=amd64 go build -tags "!console" -ldflags="$COMMON_LDFLAGS" -o build/ExcelCleaner

# Копируем иконку для Linux (для .desktop файла)
cp assets/icon.png build/

# Для macOS создаем Info.plist с иконкой
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Creating macOS app bundle..."
    # Создаем Info.plist
    cat > build/ExcelCleaner.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ExcelCleaner</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundleIdentifier</key>
    <string>com.excelcleaner.app</string>
    <key>CFBundleName</key>
    <string>Excel Cleaner</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.10</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF
fi

# Создаем .desktop файл для Linux
echo "Creating Linux desktop file..."
cat > build/excel-cleaner.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Excel Cleaner
Comment=Remove spaces from Excel files
Exec=/usr/local/bin/ExcelCleaner
Icon=/usr/local/share/icons/excel-cleaner.png
Terminal=false
Categories=Office;Utility;
EOF

echo "Build complete! Check the build directory for executables."
echo ""
echo "Installation instructions:"
echo "- Windows: The icon is embedded in ExcelCleaner.exe"
echo "- macOS: Use the ExcelCleaner.app bundle"
echo "- Linux: Copy ExcelCleaner to /usr/local/bin/ and icon.png to /usr/local/share/icons/excel-cleaner.png" 