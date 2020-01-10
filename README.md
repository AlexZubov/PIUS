#### PIUS (pre install ubuntu server)

### Скрипт подготовки python3 севера Ubuntu 18.xx

##### Запуск скрипта:
`wget -O - https://raw.githubusercontent.com/AlexZubov/PIUS/master/install.sh > /tmp/install.sh && bash /tmp/install.sh`
##### На данный момент реализовано:

- Обновление системных пакетов
- Настройка часового пояса `Europe/Moscow`
- Настройка языка и региональных стандартов
- Установка утилит:
    - `fail2ban`
    - `ufw`
    - `mc`
    - `wget`
    - `git`
    - `net-tools`
- Настройка параметров `SSH`
- Создание пользователя c правами `sudo`
- Настройка `Bash aliases`:
    - `c='clear'`
    - `smc='sudo mc'`
    - `ping='ping -c 5'`
    - `getip='wget -qO- ifconfig.co'`
    - `ports='netstat -tulanp'`
    - `ll='ls -la'`