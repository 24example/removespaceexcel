#!/bin/bash

echo "Installing Excel Cleaner..."

# Проверяем, что скрипт запущен с правами root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo: sudo ./install-linux.sh"
    exit 1
fi

# Копируем исполняемый файл
echo "- Copying executable..."
cp excel-cleaner /usr/local/bin/
chmod +x /usr/local/bin/excel-cleaner

# Создаем директорию для иконок если её нет
mkdir -p /usr/local/share/icons/

# Копируем иконку
echo "- Copying icon..."
cp excel-cleaner.png /usr/local/share/icons/

# Копируем .desktop файл
echo "- Copying desktop file..."
cp excel-cleaner.desktop /usr/share/applications/

# Обновляем базу данных desktop файлов
echo "- Updating desktop database..."
update-desktop-database /usr/share/applications/ 2>/dev/null || true

echo ""
echo "✅ Excel Cleaner installed successfully!"
echo ""
echo "You can run it:"
echo "  - From applications menu (Excel Cleaner)"
echo "  - From terminal: excel-cleaner"
echo ""
echo "To uninstall run:"
echo "  sudo rm /usr/local/bin/excel-cleaner"
echo "  sudo rm /usr/local/share/icons/excel-cleaner.png"
echo "  sudo rm /usr/share/applications/excel-cleaner.desktop" 