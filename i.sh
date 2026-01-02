#!/bin/bash
# setup_pantum_final.sh - Полная установка принтера Pantum P2200
# Запуск: sudo bash setup_pantum_final.sh

set -e

echo "🛠️  Установка принтера Pantum P2200..."

# 1. Остановка и очистка
sudo systemctl stop cups 2>/dev/null || true
sudo lpadmin -x Pantum_P2200_series 2>/dev/null || true
sudo lpadmin -x Pantum_PZ200_series 2>/dev/null || true

# 2. Установка минимального набора
echo "📦 Устанавливаю CUPS..."
sudo apt update
sudo apt install -y cups cups-client cups-filters ghostscript poppler-utils
sudo systemctl start cups
sudo systemctl enable cups

# 3. Добавление принтера RAW способом (самый надежный)
echo "➕ Добавляю принтер..."
sudo lpadmin -p Pantum_P2200_series \
    -E \
    -v "usb://Pantum/P2200%20series" \
    -m "raw" \
    -o printer-is-shared=false

# 4. Настройка
sudo lpadmin -d Pantum_P2200_series
sudo cupsenable Pantum_P2200_series
sudo cupsaccept Pantum_P2200_series

# 5. Тест RAW печати
echo "🖨️  Тестирую RAW печать..."
cat > /tmp/test.raw << 'EOF'
E
%-12345X@PJL JOB
@PJL SET RESOLUTION=600
@PJL SET DUPLEX=OFF
@PJL ENTER LANGUAGE=PCL

E&l0O&l0E&l1O&l4D&l0L(s0p10h12v0s0b3T
Тест принтера Pantum P2200
RAW режим - работает!
E
%-12345X
EOF

lp -d Pantum_P2200_series -o raw /tmp/test.raw

echo ""
echo "✅ ВСЁ УСТАНОВЛЕНО!"
echo "Принтер: Pantum_P2200_series"
echo "Режим: RAW (самый надежный)"
echo ""
echo "📋 Проверка:"
lpstat -p -d
echo ""
echo "Если принтер не печатает, проверьте:"
echo "1. USB подключение"
echo "2. Бумагу в лотке"
echo "3. Включен ли принтер"
