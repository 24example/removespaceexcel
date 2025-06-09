//go:build !console
// +build !console

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/ncruces/zenity"
	"github.com/xuri/excelize/v2"
)

func init() {
	// Отключаем вывод в stdout/stderr для GUI режима
	if !appSettings.isTestMode {
		os.Stdout = nil
		os.Stderr = nil
	}
}

// Version будет устанавливаться при сборке через ldflags
var Version = "dev"

// Структура для хранения настроек
type settings struct {
	lastOpenPath string
	lastSavePath string
	isTestMode   bool // Флаг тестового режима
}

var appSettings = settings{}

func showMainDialog() error {
	text := `Excel Cleaner %s

Эта программа поможет вам удалить лишние пробелы из ячеек Excel файлов.

Возможности:
• Обработка файлов формата XLSX
• Автоматическое удаление лишних пробелов
• Сохранение результата в новый файл
• Индикатор прогресса обработки

Последний использованный файл:
%s

Нажмите "Выбрать файл" для начала работы или "Отмена" для выхода.`

	lastFile := "Нет"
	if appSettings.lastOpenPath != "" {
		lastFile = filepath.Base(appSettings.lastOpenPath)
	}

	return zenity.Question(fmt.Sprintf(text, Version, lastFile),
		zenity.Title("Excel Cleaner "+Version),
		zenity.OKLabel("Выбрать файл"),
		zenity.CancelLabel("Выход"),
		zenity.Width(400),
		zenity.Height(300),
		zenity.Icon(zenity.InfoIcon),
	)
}

func processFile(filename string) error {
	// Сохраняем путь к файлу
	appSettings.lastOpenPath = filename

	// Открываем файл Excel
	xlFile, err := excelize.OpenFile(filename)
	if err != nil {
		return fmt.Errorf("ошибка открытия файла: %w", err)
	}
	defer xlFile.Close()

	// Получаем все листы в файле
	sheets := xlFile.GetSheetList()

	var progress zenity.ProgressDialog
	if !appSettings.isTestMode {
		// Показываем прогресс только в обычном режиме
		progress, err = zenity.Progress(
			zenity.Title("Обработка файла"),
			zenity.MaxValue(len(sheets)),
			zenity.Width(400),
		)
		if err != nil {
			return fmt.Errorf("ошибка создания индикатора прогресса: %w", err)
		}
		defer progress.Close()

		// Показываем общую информацию
		progress.Text(fmt.Sprintf("Начинаем обработку файла: %s\nВсего листов: %d",
			filepath.Base(filename), len(sheets)))
	}

	// Счетчики для статистики
	totalCells := 0
	modifiedCells := 0

	// Обрабатываем каждый лист
	for sheetIndex, sheet := range sheets {
		if !appSettings.isTestMode {
			// Обновляем прогресс только в обычном режиме
			if err := progress.Value(sheetIndex); err != nil {
				if err == zenity.ErrCanceled {
					return fmt.Errorf("операция отменена пользователем")
				}
				return fmt.Errorf("ошибка обновления прогресса: %w", err)
			}
			progress.Text(fmt.Sprintf("Обработка листа %s... (%d из %d)\nОбработано ячеек: %d\nИзменено ячеек: %d",
				sheet, sheetIndex+1, len(sheets), totalCells, modifiedCells))
		}

		// Получаем все ячейки на листе
		rows, err := xlFile.GetRows(sheet)
		if err != nil {
			return fmt.Errorf("ошибка чтения листа %s: %w", sheet, err)
		}

		// Обрабатываем каждую строку
		for rowIndex, row := range rows {
			if !appSettings.isTestMode {
				// Проверяем отмену только в обычном режиме
				select {
				case <-progress.Done():
					return fmt.Errorf("операция отменена пользователем")
				default:
				}
			}

			// Обрабатываем каждую ячейку в строке
			for colIndex := 0; colIndex < len(row); colIndex++ {
				totalCells++

				// Получаем значение ячейки
				cell := ""
				if colIndex < len(row) {
					cell = row[colIndex]
				}

				// Удаляем лишние пробелы
				trimmedCell := strings.TrimSpace(cell)

				// Всегда записываем значение ячейки
				// Конвертируем индекс столбца в буквенное обозначение
				colName, err := excelize.ColumnNumberToName(colIndex + 1)
				if err != nil {
					return fmt.Errorf("ошибка конвертации номера столбца: %w", err)
				}

				// Обновляем значение ячейки
				cellRef := fmt.Sprintf("%s%d", colName, rowIndex+1)
				if err := xlFile.SetCellValue(sheet, cellRef, trimmedCell); err != nil {
					return fmt.Errorf("ошибка обновления ячейки %s: %w", cellRef, err)
				}

				// Увеличиваем счетчик измененных ячеек, если значение изменилось
				if trimmedCell != cell {
					modifiedCells++
				}
			}
		}
	}

	if !appSettings.isTestMode {
		// Отмечаем завершение обработки только в обычном режиме
		progress.Complete()

		// Показываем статистику перед сохранением
		info := fmt.Sprintf("Обработка завершена!\n\nСтатистика:\n"+
			"• Всего обработано ячеек: %d\n"+
			"• Изменено ячеек: %d\n"+
			"• Процент изменений: %.1f%%\n\n"+
			"Выберите путь для сохранения файла:",
			totalCells, modifiedCells, float64(modifiedCells)/float64(totalCells)*100)

		zenity.Info(info,
			zenity.Title("Статистика обработки"),
			zenity.Width(300),
		)
	}

	// В тестовом режиме сохраняем в той же директории
	var savePath string
	if appSettings.isTestMode {
		savePath = filepath.Join(filepath.Dir(filename), "cleaned_"+filepath.Base(filename))
	} else {
		// Формируем имя файла по умолчанию
		defaultName := "cleaned_" + filepath.Base(filename)
		defaultPath := filepath.Join(filepath.Dir(appSettings.lastSavePath), defaultName)
		if appSettings.lastSavePath == "" {
			defaultPath = defaultName
		}

		// Спрашиваем, куда сохранить результат
		var err error
		savePath, err = zenity.SelectFileSave(
			zenity.Title("Сохранить обработанный файл"),
			zenity.FileFilter{
				Name:     "Excel файлы",
				Patterns: []string{"*.xlsx"},
			},
			zenity.Filename(defaultPath),
		)
		if err != nil {
			if err == zenity.ErrCanceled {
				return nil
			}
			return fmt.Errorf("ошибка выбора файла для сохранения: %w", err)
		}

		// Сохраняем путь
		appSettings.lastSavePath = savePath
	}

	// Добавляем расширение .xlsx если его нет
	if !strings.HasSuffix(savePath, ".xlsx") {
		savePath += ".xlsx"
	}

	// Сохраняем изменения во временный файл
	if err := xlFile.SaveAs(savePath); err != nil {
		return fmt.Errorf("ошибка сохранения файла: %w", err)
	}

	return nil
}

func main() {
	for {
		// Показываем главное окно
		err := showMainDialog()
		if err == zenity.ErrCanceled {
			return
		} else if err != nil {
			zenity.Error(
				"Ошибка: "+err.Error(),
				zenity.Title("Ошибка"),
				zenity.ErrorIcon,
			)
			continue
		}

		// Показываем диалог выбора файла с последним использованным путем
		startDir := filepath.Dir(appSettings.lastOpenPath)
		if startDir == "." {
			startDir = ""
		}

		filename, err := zenity.SelectFile(
			zenity.Title("Выберите Excel файл"),
			zenity.FileFilter{
				Name:     "Excel файлы",
				Patterns: []string{"*.xlsx"},
			},
			zenity.Filename(startDir),
		)
		if err != nil {
			if err == zenity.ErrCanceled {
				continue
			}
			zenity.Error(
				"Ошибка выбора файла: "+err.Error(),
				zenity.Title("Ошибка"),
			)
			continue
		}

		// Проверяем расширение файла
		if !strings.HasSuffix(strings.ToLower(filename), ".xlsx") {
			zenity.Error(
				"Поддерживаются только файлы .xlsx",
				zenity.Title("Ошибка"),
			)
			continue
		}

		// Обрабатываем файл
		if err := processFile(filename); err != nil {
			zenity.Error(
				"Ошибка обработки файла: "+err.Error(),
				zenity.Title("Ошибка"),
			)
			continue
		}

		// Показываем сообщение об успехе
		err = zenity.Question(
			"Файл успешно обработан и сохранен!\n\nХотите обработать еще один файл?",
			zenity.Title("Успех"),
			zenity.OKLabel("Да"),
			zenity.CancelLabel("Нет"),
			zenity.Icon(zenity.InfoIcon),
		)
		if err == zenity.ErrCanceled {
			break
		} else if err != nil {
			continue
		}
	}
}
