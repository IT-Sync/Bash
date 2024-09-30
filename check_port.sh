#!/bin/bash

# Проверка наличия sshpass
if ! command -v sshpass &> /dev/null; then
    echo "sshpass не установлен. Установите sshpass для выполнения этого скрипта."
    exit 1
fi

# Функция для проверки доступности порта на удалённом сервере
check_port() {
    local remote_host="$1"
    local target_server="$2"
    local port="$3"
    
    # Выполняем проверку порта на удалённом сервере с использованием sshpass
    result=$(sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$remote_host" "nc -zv $target_server $port" 2>&1)

    # Проверяем результаты
    if echo "$result" | grep -q "Connected"; then
        echo "$remote_host; $target_server; $port; connected"
    elif echo "$result" | grep -q "TIMEOUT"; then
        echo "$remote_host; $target_server; $port; timeout"
    elif echo "$result" | grep -q "refused"; then    
        echo "$remote_host; $target_server; $port; refused"
    else
        echo "$remote_host; $target_server; $port; error: $result"
    fi
}

# Основная часть скрипта
output_file="/home/PROD/alexk/test/port_check_results6"  # Путь к файлу для записи результатов

# Запрашиваем имя пользователя и пароль один раз
read -p "Введите имя пользователя: " username
read -sp "Введите пароль: " password
echo  # Для новой строки после ввода пароля

# Очищаем файл перед началом новой записи
> "$output_file"

# Чтение хостов из файла
hosts_file="hosts.txt"  # Укажите путь к файлу с хостами
target_servers_file="target_servers.txt"  # Укажите путь к файлу с серверами
ports_file="ports.txt"  # Укажите путь к файлу со списком портов

# Проверяем наличие файлов
if [[ ! -f "$hosts_file" || ! -f "$target_servers_file" || ! -f "$ports_file" ]]; then
    echo "Один или несколько файлов не найдены. Убедитесь, что файлы существуют."
    exit 1
fi

# Чтение файлов
mapfile -t hosts < "$hosts_file"
mapfile -t target_servers < "$target_servers_file"
mapfile -t ports < "$ports_file"

# Проверка портов
for remote_host in "${hosts[@]}"; do
    for target_server in "${target_servers[@]}"; do
        for port in "${ports[@]}"; do
            echo "Подключение к хосту $remote_host и проверка порта $port на $target_server..."
            result=$(check_port "$remote_host" "$target_server" "$port")
            echo "$result" >> "$output_file"
        done
    done
done

echo "Проверка завершена. Результаты сохранены в $output_file."

