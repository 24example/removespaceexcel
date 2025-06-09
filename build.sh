#!/bin/bash

# Версия приложения
VERSION="1.0.0"

# Создаем директорию для бинарных файлов если её нет
mkdir -p build

# Общие флаги линковщика
COMMON_LDFLAGS="-s -w -X main.Version=$VERSION"

# Сборка для Windows (64-bit) с GUI режимом
echo "Building for Windows (64-bit)..."
GOOS=windows GOARCH=amd64 go build -tags "!console" -ldflags="$COMMON_LDFLAGS -H=windowsgui" -o build/ExcelCleaner.exe

# Сборка для macOS (64-bit)
echo "Building for macOS (64-bit)..."
mkdir -p build/ExcelCleaner.app/Contents/MacOS
GOOS=darwin GOARCH=amd64 go build -tags "!console" -ldflags="$COMMON_LDFLAGS" -o build/ExcelCleaner.app/Contents/MacOS/ExcelCleaner

# Сборка для Linux (64-bit)
echo "Building for Linux (64-bit)..."
GOOS=linux GOARCH=amd64 go build -tags "!console" -ldflags="$COMMON_LDFLAGS" -o build/ExcelCleaner

# Для macOS создаем Info.plist
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
    <true/>
</dict>
</plist>
EOF
fi

echo "Build complete! Check the build directory for executables." 