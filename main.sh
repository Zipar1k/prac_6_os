#!/bin/bash

show_help() {
    echo "Использование: $0 [опции]"
    echo "-- опции --:"
    echo "  -u, --users        Показать пользователей и домашние директории"
    echo "  -p, --processes    Показать запущенные процессы"
    echo "  -l, --log файл     Сохранить вывод в файл"
    echo "  -e, --errors файл  Сохранить ошибки в файл"
    echo "  -h, --help         Показать справку"
}

show_users() {
    getent passwd 2>/dev/null | cut -d: -f1,6 | sort
}

show_processes() {
    ps -e -o pid,comm --no-headers 2>/dev/null | sort -n
}

check_file_access() {
    local file="$1"
    if ! touch "$file" 2>/dev/null; then
        echo "Ошибка: Нет доступа к файлу '$file'" >&2
        return 1
    fi
    return 0
}

main() {
    local users_flag=0
    local processes_flag=0
    local log_file=""
    local errors_file=""

    while getopts "uphl:e:-:" opt; do
        case $opt in
            u) users_flag=1 ;;
            p) processes_flag=1 ;;
            h) show_help; exit 0 ;;
            l) log_file="$OPTARG" ;;
            e) errors_file="$OPTARG" ;;
            -) 
                case "${OPTARG}" in
                    users) users_flag=1 ;;
                    processes) processes_flag=1 ;;
                    help) show_help; exit 0 ;;
                    log) log_file="${!OPTIND}"; OPTIND=$((OPTIND+1)) ;;
                    errors) errors_file="${!OPTIND}"; OPTIND=$((OPTIND+1)) ;;
                    *) echo "Неизвестная опция: --${OPTARG}" >&2; exit 1 ;;
                esac
                ;;
            *) echo "Неизвестная опция: -$OPTARG" >&2; exit 1 ;;
        esac
    done

    if [ -n "$log_file" ]; then
        if ! check_file_access "$log_file"; then
            exit 1
        fi
        exec >"$log_file"
    fi

    if [ -n "$errors_file" ]; then
        if ! check_file_access "$errors_file"; then
            exit 1
        fi
        exec 2>"$errors_file"
    fi

    if [ $users_flag -eq 1 ]; then
        echo "-- пользователи --"
        show_users
    fi

    if [ $processes_flag -eq 1 ]; then
        echo "-- процессы --"
        show_processes
    fi

    if [ $users_flag -eq 0 ] && [ $processes_flag -eq 0 ]; then
        show_help
    fi
}

main "$@"
