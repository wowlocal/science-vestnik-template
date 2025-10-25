#!/bin/bash
# ========================================
# СКРИПТ КОНВЕРТАЦИИ LaTeX → DOCX
# ========================================
# Конвертирует LaTeX файлы в DOCX с сохранением форматирования
# согласно требованиям журнала "Вестник МГУ. Серия 13. Востоковедение"
#
# Использование:
#   ./latex2docx.sh article.tex
#   ./latex2docx.sh article.tex output.docx

set -e  # Остановка при ошибке

# ========================================
# ПРОВЕРКА ЗАВИСИМОСТЕЙ
# ========================================

if ! command -v pandoc &> /dev/null; then
    echo "❌ Ошибка: pandoc не установлен"
    echo "Установите pandoc: brew install pandoc (macOS) или apt-get install pandoc (Linux)"
    exit 1
fi

# Проверка версии pandoc
PANDOC_VERSION=$(pandoc --version | head -n1 | awk '{print $2}')
echo "ℹ️  Используется pandoc версии $PANDOC_VERSION"

# ========================================
# ПАРАМЕТРЫ
# ========================================

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.tex}.docx}"
REFERENCE_DOCX="reference-vestnik.docx"

# Проверка входного файла
if [ -z "$INPUT_FILE" ]; then
    echo "❌ Ошибка: не указан входной файл"
    echo "Использование: $0 <input.tex> [output.docx]"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Ошибка: файл '$INPUT_FILE' не найден"
    exit 1
fi

echo "📄 Входной файл: $INPUT_FILE"
echo "📝 Выходной файл: $OUTPUT_FILE"

# ========================================
# ПРЕДВАРИТЕЛЬНАЯ ОБРАБОТКА
# ========================================

echo "🔧 Подготовка файла для конвертации..."

# Создаем временный файл с очищенным LaTeX
TEMP_FILE=$(mktemp /tmp/latex2docx.XXXXXX.tex)

# Копируем содержимое, убирая специфичные для LaTeX команды
# которые pandoc не понимает
# Также конвертируем специальные символы
sed -e 's/—/---/g' \
    -e 's/–/--/g' \
    -e 's/\\usepackage{vestnik}//' \
    -e 's/\\udc{[^}]*}//' \
    -e 's/\\articletitleru{\([^}]*\)}/\\section*{\U\1}/' \
    -e 's/\\articletitleen{\([^}]*\)}/\\section*{\U\1}/' \
    -e 's/\\authorru{\([^}]*\)}/\\textbf{\1}\\newline/' \
    -e 's/\\authoren{\([^}]*\)}/\\textbf{\1}\\newline/' \
    -e 's/\\institution{\([^}]*\)}/\\textit{\1}\\newline/' \
    -e 's/\\institutionen{\([^}]*\)}/\\textit{\1}\\newline/' \
    -e 's/\\abstractru{\([^}]*\)}/\\textbf{\\textit{Аннотация:}} \\textit{\1}\\par/' \
    -e 's/\\abstracten{\([^}]*\)}/\\textbf{\\textit{Abstract:}} \\textit{\1}\\par/' \
    -e 's/\\keywordsru{\([^}]*\)}/\\textbf{\\textit{Ключевые слова:}} \\textit{\1}\\par/' \
    -e 's/\\keywordsen{\([^}]*\)}/\\textbf{\\textit{Key words:}} \\textit{\1}\\par/' \
    -e 's/\\funding{\([^}]*\)}/\\textbf{Финансирование:} \1\\par/' \
    -e 's/\\fundingen{\([^}]*\)}/\\textbf{Funding:} \1\\par/' \
    -e 's/\\forcitation{\([^}]*\)}/\\textbf{Для цитирования:} \1\\par/' \
    -e 's/\\forcitationen{\([^}]*\)}/\\textbf{For citation:} \1\\par/' \
    -e 's/\\aboutauthor{\([^}]*\)}/\\paragraph{About the author:} \1/' \
    -e 's/\\bibliographyru/\\section*{Список литературы}/' \
    -e 's/\\referencesen/\\section*{References}/' \
    -e 's/\\bibliosectioncyrillic/\\subsection*{На русском языке (кириллица)}/' \
    -e 's/\\bibliosectionlatin/\\subsection*{На западных языках (латиница)}/' \
    -e 's/\\bibliosectionoriental/\\subsection*{На восточных языках (иероглифика)}/' \
    -e 's/\\begin{bibliolist}/\\begin{itemize}/' \
    -e 's/\\end{bibliolist}/\\end{itemize}/' \
    -e 's/\\begin{bibliolistnum}/\\begin{enumerate}/' \
    -e 's/\\end{bibliolistnum}/\\end{enumerate}/' \
    "$INPUT_FILE" > "$TEMP_FILE"

echo "✅ Предварительная обработка завершена"

# ========================================
# КОНВЕРТАЦИЯ С PANDOC
# ========================================

echo "🔄 Конвертация в DOCX..."

# Параметры pandoc для соответствия требованиям журнала
PANDOC_OPTS=(
    --from=latex
    --to=docx
    --standalone
    --number-sections
    --toc=false
)

# Если есть reference.docx, используем его для стилей
if [ -f "$REFERENCE_DOCX" ]; then
    echo "ℹ️  Используется файл стилей: $REFERENCE_DOCX"
    PANDOC_OPTS+=(--reference-doc="$REFERENCE_DOCX")
else
    echo "⚠️  Предупреждение: файл стилей '$REFERENCE_DOCX' не найден"
    echo "   Будут использованы стандартные стили pandoc"
    echo "   Запустите './create-reference-docx.sh' для создания файла стилей"
fi

# Выполняем конвертацию
pandoc "${PANDOC_OPTS[@]}" "$TEMP_FILE" -o "$OUTPUT_FILE"

# Удаляем временный файл
rm "$TEMP_FILE"

echo "✅ Конвертация завершена успешно!"

# ========================================
# ПОСТОБРАБОТКА И РЕКОМЕНДАЦИИ
# ========================================

echo ""
echo "📋 Рекомендации по финальной проверке в Word:"
echo ""
echo "1. Откройте файл: $OUTPUT_FILE"
echo "2. Проверьте форматирование:"
echo "   • Шрифт основного текста: Times New Roman 12pt, интервал 1.5"
echo "   • Шрифт сносок: Times New Roman 10pt, интервал 1.0"
echo "   • Абзацный отступ: 1.25 см"
echo "   • Поля: 2.54 см (1 дюйм) со всех сторон"
echo "3. Проверьте нумерацию страниц"
echo "4. Проверьте корректность сносок и списка литературы"
echo ""
echo "⚠️  ВАЖНО: Некоторые элементы форматирования могут потребовать"
echo "   ручной корректировки в Microsoft Word."
echo ""
echo "✨ Готово! Файл сохранен: $OUTPUT_FILE"
