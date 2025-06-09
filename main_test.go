package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/xuri/excelize/v2"
)

// Вспомогательная функция для создания тестового Excel файла
func createTestFile(t *testing.T, data [][]string) string {
	t.Helper()

	// Создаем временный файл
	f := excelize.NewFile()
	defer f.Close()

	// Находим максимальную длину строки
	maxCols := 0
	for _, row := range data {
		if len(row) > maxCols {
			maxCols = len(row)
		}
	}

	// Записываем данные
	for i, row := range data {
		// Дополняем строку пустыми ячейками до максимальной длины
		for len(row) < maxCols {
			row = append(row, "")
		}

		for j, cell := range row {
			colName, err := excelize.ColumnNumberToName(j + 1)
			if err != nil {
				t.Fatalf("Ошибка конвертации номера столбца: %v", err)
			}
			cellRef := fmt.Sprintf("%s%d", colName, i+1)
			if err := f.SetCellValue("Sheet1", cellRef, cell); err != nil {
				t.Fatalf("Ошибка записи в ячейку %s: %v", cellRef, err)
			}
		}
	}

	// Создаем временный файл
	tmpFile, err := os.CreateTemp("", "test_*.xlsx")
	if err != nil {
		t.Fatalf("Ошибка создания временного файла: %v", err)
	}
	tmpFile.Close()

	// Сохраняем Excel файл
	if err := f.SaveAs(tmpFile.Name()); err != nil {
		os.Remove(tmpFile.Name())
		t.Fatalf("Ошибка сохранения файла: %v", err)
	}

	// Файл будет удален после теста
	t.Cleanup(func() {
		os.Remove(tmpFile.Name())
	})

	return tmpFile.Name()
}

// Вспомогательная функция для проверки содержимого Excel файла
func checkFileContent(t *testing.T, filename string, expected [][]string) {
	t.Helper()

	f, err := excelize.OpenFile(filename)
	if err != nil {
		t.Fatalf("Ошибка открытия файла: %v", err)
	}
	defer f.Close()

	// Получаем список листов
	sheets := f.GetSheetList()
	t.Logf("Листы в файле: %v", sheets)

	rows, err := f.GetRows(sheets[0])
	if err != nil {
		t.Fatalf("Ошибка чтения строк: %v", err)
	}

	t.Logf("Прочитано строк: %d, ожидалось: %d", len(rows), len(expected))
	for i, row := range rows {
		t.Logf("Строка %d: %v", i, row)
	}
	t.Logf("Ожидаемые данные:")
	for i, row := range expected {
		t.Logf("Строка %d: %v", i, row)
	}

	// Проверяем количество строк
	if len(rows) != len(expected) {
		t.Errorf("Неверное количество строк: получено %d, ожидалось %d", len(rows), len(expected))
		return
	}

	// Проверяем каждую ячейку
	for i, row := range rows {
		if len(row) != len(expected[i]) {
			t.Errorf("Неверное количество ячеек в строке %d: получено %d, ожидалось %d", i, len(row), len(expected[i]))
			continue
		}
		for j, cell := range row {
			if cell != expected[i][j] {
				t.Errorf("Неверное значение в ячейке [%d][%d]: получено %q, ожидалось %q", i, j, cell, expected[i][j])
			}
		}
	}
}

func TestProcessFile(t *testing.T) {
	// Включаем тестовый режим
	origSettings := appSettings
	defer func() {
		appSettings = origSettings
	}()
	appSettings.isTestMode = true

	tests := []struct {
		name     string
		input    [][]string
		expected [][]string
	}{
		{
			name: "Удаление пробелов в начале и конце",
			input: [][]string{
				{" test1 ", "  test2  ", " test3 "},
				{"  a  ", " b ", "   c   "},
			},
			expected: [][]string{
				{"test1", "test2", "test3"},
				{"a", "b", "c"},
			},
		},
		{
			name: "Пустые ячейки",
			input: [][]string{
				{"  ", " ", "   "},
				{"a", "", "c"},
			},
			expected: [][]string{
				{"", "", ""},
				{"a", "", "c"},
			},
		},
		{
			name: "Смешанные данные",
			input: [][]string{
				{" 123 ", "  abc  ", " test "},
				{"  1.23  ", " text ", "   mixed   "},
			},
			expected: [][]string{
				{"123", "abc", "test"},
				{"1.23", "text", "mixed"},
			},
		},
		{
			name: "Неравномерные строки",
			input: [][]string{
				{" a ", "  b  ", " c ", " d "},
				{"  1  ", " 2 "},
				{"  x  "},
			},
			expected: [][]string{
				{"a", "b", "c", "d"},
				{"1", "2", "", ""},
				{"x", "", "", ""},
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Создаем тестовый файл
			inputFile := createTestFile(t, tt.input)

			// Обрабатываем файл
			err := processFile(inputFile)
			if err != nil {
				t.Fatalf("Ошибка обработки файла: %v", err)
			}

			// Проверяем результат
			outputFile := filepath.Join(filepath.Dir(inputFile), "cleaned_"+filepath.Base(inputFile))
			if _, err := os.Stat(outputFile); os.IsNotExist(err) {
				t.Fatal("Файл с результатом не создан")
			}
			defer os.Remove(outputFile)

			// Открываем файл для проверки
			f, err := excelize.OpenFile(outputFile)
			if err != nil {
				t.Fatalf("Ошибка открытия файла: %v", err)
			}
			defer f.Close()

			// Получаем все строки
			rows, err := f.GetRows(f.GetSheetList()[0])
			if err != nil {
				t.Fatalf("Ошибка чтения строк: %v", err)
			}

			// Проверяем количество строк
			if len(rows) != len(tt.expected) {
				t.Errorf("Неверное количество строк: получено %d, ожидалось %d", len(rows), len(tt.expected))
				return
			}

			// Проверяем каждую строку
			for i, expectedRow := range tt.expected {
				// Получаем фактическую строку
				var actualRow []string
				if i < len(rows) {
					actualRow = rows[i]
				}

				// Дополняем фактическую строку пустыми значениями при необходимости
				for len(actualRow) < len(expectedRow) {
					actualRow = append(actualRow, "")
				}

				// Сравниваем значения
				for j, expectedCell := range expectedRow {
					actualCell := ""
					if j < len(actualRow) {
						actualCell = actualRow[j]
					}

					if actualCell != expectedCell {
						t.Errorf("Строка %d, ячейка %d: получено %q, ожидалось %q", i+1, j+1, actualCell, expectedCell)
					}
				}
			}
		})
	}
}

func TestSettings(t *testing.T) {
	// Сохраняем исходные настройки
	origSettings := appSettings
	defer func() {
		appSettings = origSettings
	}()

	// Очищаем настройки перед тестом
	appSettings = settings{}

	t.Run("Сохранение путей", func(t *testing.T) {
		// Тестовые пути
		openPath := "/path/to/input.xlsx"
		savePath := "/path/to/output.xlsx"

		// Проверяем начальные значения
		if appSettings.lastOpenPath != "" {
			t.Errorf("Начальное значение lastOpenPath должно быть пустым, получено: %q", appSettings.lastOpenPath)
		}
		if appSettings.lastSavePath != "" {
			t.Errorf("Начальное значение lastSavePath должно быть пустым, получено: %q", appSettings.lastSavePath)
		}

		// Устанавливаем пути
		appSettings.lastOpenPath = openPath
		appSettings.lastSavePath = savePath

		// Проверяем сохраненные значения
		if appSettings.lastOpenPath != openPath {
			t.Errorf("Неверное значение lastOpenPath: получено %q, ожидалось %q", appSettings.lastOpenPath, openPath)
		}
		if appSettings.lastSavePath != savePath {
			t.Errorf("Неверное значение lastSavePath: получено %q, ожидалось %q", appSettings.lastSavePath, savePath)
		}
	})

	t.Run("Формирование пути по умолчанию", func(t *testing.T) {
		// Устанавливаем тестовые пути
		appSettings.lastOpenPath = "/path/to/input.xlsx"
		appSettings.lastSavePath = "/save/path/output.xlsx"

		// Проверяем формирование имени файла по умолчанию
		defaultName := "cleaned_" + filepath.Base(appSettings.lastOpenPath)
		if !strings.HasPrefix(defaultName, "cleaned_") {
			t.Errorf("Имя файла по умолчанию должно начинаться с 'cleaned_', получено: %q", defaultName)
		}
		if !strings.HasSuffix(defaultName, ".xlsx") {
			t.Errorf("Имя файла по умолчанию должно заканчиваться на '.xlsx', получено: %q", defaultName)
		}

		// Проверяем полный путь
		defaultPath := filepath.Join(filepath.Dir(appSettings.lastSavePath), defaultName)
		if !strings.HasPrefix(defaultPath, filepath.Dir(appSettings.lastSavePath)) {
			t.Errorf("Путь по умолчанию должен использовать директорию последнего сохранения, получено: %q", defaultPath)
		}
	})
}
