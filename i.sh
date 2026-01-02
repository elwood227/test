#!/bin/bash
# reset_cups_pantum.sh - Полная переустановка CUPS для Pantum P2200
# Запуск: sudo bash reset_cups_pantum.sh

set -e

echo "=========================================="
echo "  ПОЛНАЯ ПЕРЕУСТАНОВКА CUPS И ПРИНТЕРА"
echo "=========================================="

# 1. ОСТАНОВКА СЛУЖБ
echo "🛑 Останавливаю службы..."
sudo systemctl stop cups cups-browsed
sudo systemctl disable cups cups-browsed

# 2. ПОЛНОЕ УДАЛЕНИЕ ВСЕХ ПАКЕТОВ ПЕЧАТИ
echo "🗑️ Удаляю все пакеты печати..."
sudo apt purge --auto-remove -y \
    cups* \
    printer-driver* \
    foomatic* \
    hplip* \
    ghostscript* \
    libcups* \
    python3-cups \
    python-cups \
    cups-filters \
    cups-client \
    cups-common \
    cups-core-drivers \
    cups-daemon \
    cups-server-common

# 3. ОЧИСТКА КОНФИГУРАЦИИ
echo "🧹 Очищаю конфигурацию..."
sudo rm -rf /etc/cups
sudo rm -rf /var/spool/cups
sudo rm -rf /var/cache/cups
sudo rm -rf /var/log/cups
sudo rm -rf /usr/lib/cups
sudo rm -rf /usr/share/cups

# 4. ОБНОВЛЕНИЕ СИСТЕМЫ
echo "🔄 Обновляю систему..."
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt autoclean

# 5. УСТАНОВКА ТОЛЬКО НУЖНЫХ ПАКЕТОВ
echo "📦 Устанавливаю CUPS заново..."
sudo apt install -y \
    cups \
    cups-client \
    cups-filters \
    cups-ipp-utils \
    printer-driver-cups-pdf \
    ghostscript \
    poppler-utils \
    libcups2-dev \
    python3-cups

# 6. НАСТРОЙКА CUPS
echo "⚙️ Настраиваю CUPS..."
sudo cupsctl --remote-any --remote-admin --share-printers
sudo systemctl start cups
sudo systemctl enable cups
sudo usermod -aG lpadmin $USER

# 7. ПЕРЕПОДКЛЮЧЕНИЕ ПРИНТЕРА (вынуть/вставить USB)
echo "🔌 Переподключите USB кабель принтера..."
echo "1. Выньте USB кабель из принтера"
echo "2. Подождите 5 секунд"
echo "3. Вставьте USB кабель обратно"
read -p "Нажмите Enter после переподключения..."

# 8. ПОИСК И ДОБАВЛЕНИЕ ПРИНТЕРА
echo "🔍 Ищу принтер..."
sleep 5

# Находим URI принтера
URI=$(sudo lpinfo -v | grep -i "pantum\|usb" | head -1)
if [ -z "$URI" ]; then
    echo "⚠️ Принтер не найден автоматически"
    echo "Доступные устройства:"
    sudo lpinfo -v
    read -p "Введите URI принтера (скопируйте из списка выше): " MANUAL_URI
    URI="$MANUAL_URI"
fi

echo "✅ Найден принтер: $URI"

# 9. ДОБАВЛЕНИЕ ПРИНТЕРА
echo "➕ Добавляю принтер Pantum_P2200_series..."
sudo lpadmin -x Pantum_P2200_series 2>/dev/null || true
sudo lpadmin -x Pantum_PZ200_series 2>/dev/null || true

sudo lpadmin -p Pantum_P2200_series \
    -E \
    -v "$URI" \
    -m "drv:///sample.drv/generic.ppd" \
    -o printer-is-shared=false \
    -o usb-unidir=true \
    -o PageSize=A4 \
    -o ColorModel=Gray

# 10. НАСТРОЙКА ПРИНТЕРА ПО УМОЛЧАНИЮ
echo "🎯 Настраиваю принтер по умолчанию..."
sudo lpadmin -d Pantum_P2200_series
sudo cupsenable Pantum_P2200_series
sudo cupsaccept Pantum_P2200_series

# 11. ТЕСТИРОВАНИЕ
echo "🖨️ Тестирую печать..."
echo "Тестовая печать Pantum P2200 - $(date)" > /tmp/test_print.txt

if lp -d Pantum_P2200_series /tmp/test_print.txt; then
    echo "✅ Тестовая печать отправлена успешно!"
    JOB_ID=$(lpstat -o | grep Pantum_P2200_series | tail -1 | awk '{print $1}')
    echo "🆔 ID задания: $JOB_ID"
else
    echo "❌ Ошибка отправки на печать"
fi

# 12. ПРОВЕРКА
echo ""
echo "=========================================="
echo "           ПРОВЕРКА СИСТЕМЫ"
echo "=========================================="

echo "1. Статус службы CUPS:"
sudo systemctl status cups --no-pager -l | head -10

echo ""
echo "2. Список принтеров:"
lpstat -p -d

echo ""
echo "3. Очередь печати:"
lpstat -o

echo ""
echo "4. Логи CUPS (последние 5 строк):"
sudo tail -5 /var/log/cups/error_log 2>/dev/null || echo "Логи отсутствуют"

echo ""
echo "=========================================="
echo "          ЧТО ДЕЛАТЬ ДАЛЬШЕ"
echo "=========================================="
echo "1. Проверьте физически - печатает ли принтер"
echo "2. Если не печатает, проверьте:"
echo "   - USB подключение"
echo "   - Бумагу в лотке"
echo "   - Тонер/картридж"
echo "3. Для бота установите библиотеки:"
echo "   pip3 install pyTelegramBotAPI Pillow img2pdf"
echo "4. Запустите бота: python3 bot.py"
echo ""
echo "Если всё равно не работает, покажите вывод команды:"
echo "sudo tail -f /var/log/cups/error_log"