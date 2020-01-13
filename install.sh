#!/usr/bin/env bash

# Цветной фон
back_red="\e[41m"
back_green="\e[42m"
back_brown="\e[43m"
back_blue="\e[44m"
back_purple="\e[45m"
back_cyan="\e[46m"

# Цветной текст
red="\e[31m"
green="\e[32m"
brown="\e[33m"
blue="\e[34m"
purple="\e[35m"
cyan="\e[36m"

# Завершение вывода цвета
end="\e[0m"

# Данные о системе
os=`lsb_release -a | grep "Description" | awk '{$1=""; print $0}'`
cpu=`lscpu | grep "CPU MHz" | awk '{print $3}'`
cores=`grep -o "processor" <<< "$(cat /proc/cpuinfo)" | wc -l`
kern=`uname -r | sed -e "s/-/ /" | awk '{print $1}'`
kn=`lsb_release -cs`
mem=`free -m | grep "Mem" | awk '{print $2}'`
hdd=`df -m | awk '(NR == 2)' | awk '{print $2}'`

function show() {
  # Печать информации о выполнении новой команды
  echo -e "${brown} ${1}...${end}"
}

function answer() {
  # Соглашение пользователя на продолжение
  temp=""
  read temp
  temp=$(echo ${temp^^})
  echo -e "${end}"
  if [[ "$temp" != "Y" && "$temp" != "YES" ]]; then return 255; fi
}

function close() {
  # Завершение работы скрипта + перезагрузка
  echo -en "${brown}Нажмите любую клавишу, чтобы продолжить...${end}"
  read -s -n 1
  clear
  if [[ "$1" == "reboot" ]]; then shutdown -r now; else exit 0; fi
}

function rebootOS() {
  echo -e "\n${red}ВНИМАНИЕ! Система будет перезагружена!${end}"
  echo -e "${red}Сохраните данные указанные выше!${end}\n"
  close "reboot"
}

clear

# Вывод информации о системе
echo -e "$red"
echo "  Дистрибутив:${os}"
echo "  Версия ядра: ${kern} (${kn})"
echo "          CPU: ${cores} x ${cpu} MHz"
echo "          RAM: ${mem} Mb"
echo "          HDD: ${hdd} Mb"
echo -en "$end"

# Изменение портов
port_ssh=$(shuf -i 50000-55000 -n 1)
port_sql=$(shuf -i 55001-60000 -n 1)

echo -en "\n${cyan}Введите имя нового пользователя: ${end}"; read username
echo -en "${cyan}Введите пароль нового пользователя: ${end}"; read -r password


show "Обновление системных пакетов"
apt update && \
apt upgrade -y && \
apt dist-upgrade -y


show "Настройка часового пояса"
ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime  && \
apt install -y tzdata  && \
dpkg-reconfigure --frontend noninteractive tzdata  && \
apt install -y ntp

show "Настройка языка и региональных стандартов"
apt install -y language-pack-ru
locale-gen ru_RU && \
locale-gen ru_RU.UTF-8 && \
update-locale LANG=ru_RU.UTF-8 && \
dpkg-reconfigure --frontend noninteractive locales


# === НАСТРОЙКА FIREWALL === #

show "Установка и настройка утилиты ufw"
apt install -y ufw && \
ufw default deny incoming && \
ufw default allow outgoing && \
ufw allow http && \
ufw allow 443/tcp && \
ufw allow ${port_ssh} && \
ufw allow ${port_sql}

show "Включение ufw"
yes | ufw enable

show "Проверка статуса ufw"
ufw status

# === НАСТРОЙКА ЗАЩИТЫ ОТ ПЕРЕБОРА ПАРОЛЕЙ === #

show "Установка утилиты fail2ban (защиты от перебора паролей)"
apt install -y fail2ban

# === НАСТРОЙКА SSH === #

show "Настройка параметров SSH"
apt install -y sed && \
sed -i "/^Port/s/^/# /" /etc/ssh/sshd_config && \
sed -i "/^PermitRootLogin/s/^/# /" /etc/ssh/sshd_config && \
sed -i "/^AllowUsers/s/^/# /" /etc/ssh/sshd_config && \
sed -i "/^PermitEmptyPasswords/s/^/# /" /etc/ssh/sshd_config && \
{
echo "Port ${port_ssh}"
echo "PermitRootLogin no"
echo "AllowUsers ${username}"
echo "PermitEmptyPasswords no"
} >> /etc/ssh/sshd_config



# === УСТАНОВКА ПРОГРАММ === #

show "Установка и настройка утилиты mc"
  apt install -y mc && \
  {
    echo "[Midnight-Commander]"
    echo "use_internal_view=true"
    echo "use_internal_edit=true"
    echo "editor_syntax_highlighting=true"
    echo "skin=modarin256"
    echo "[Layout]"
    echo "message_visible=0"
    echo "xterm_title=0"
    echo "command_prompt=0"
    echo "[Panels]"
    echo "show_mini_info=false"
  } > /etc/mc/mc.ini


show "Установка утилиты wget"
	apt install -y wget

show "Установка утилиты git"
	apt install -y git


show "Установка утилиты net-tools"
  	apt install -y net-tools

show "Установка pip3"
apt install -y python3-pip


show "Создание пользователя ${username}"
	groupadd ${username} && \
	useradd -g ${username} -G sudo -s /bin/bash -m ${username} -p $(openssl passwd -1 ${password})

show "Настройка сокращений bash команд"
  {
    echo "alias c='clear'"
    echo "alias smc='sudo mc'"
    echo "alias ping='ping -c 5'"
    echo "alias getip='wget -qO- ifconfig.co'"
    echo "alias ports='netstat -tulanp'"
    echo "alias ll='ls -la'"
  } > /home/${username}/.bash_aliases && \
  chown ${username}:${username} /home/${username}/.bash_aliases

show "Очистка пакетного менеджера"
  apt autoremove -y && \
  apt autoclean -y


# Добавление ключа для авторизации
echo -en "\n${green}Добавить публичный ключ для авторизации по ssh? [Y/n]: ${end}"
answer
if [[ $? -eq 0 ]]; then
  echo -en "\n${cyan}Введите Ваш публичный ключ: ${end}"; read user_pub_key
  mkdir /home/${username}/.ssh
  {
      echo "${user_pub_key}"
    } > /home/${username}/.ssh/authorized_keys && \
    chown ${username}:${username} /home/${username}/.ssh/authorized_keys
fi


echo -en "\n${green}Установить python3 и всего зависимости? [Y/n]: ${end}"
answer
if [[ $? -ne 0 ]]; then
show "Установка python + dev + venv"
sudo apt-get -y update
sudo apt-get -y install python3 python3-venv python3-dev
fi

echo -en "\n${green}Установить python3 и всего зависимости? [Y/n]: ${end}"
answer
if [[ $? -ne 0 ]]; then
show "Установка mysql server, mail agent - postfix, supervisor, nginx"
sudo apt-get -y install mysql-server supervisor nginx
fi

#echo -en "\n${cyan}Введите название приложения (en): ${end}"; read app_name
#mkdir /home/${username}/${app_name}
#cd /home/${username}/${app_name}
#mkdir /home/${username}/${app_name}/app
#{
#    echo "from flask import Flask"
#    echo "app = Flask(__name__)"
#    echo "from app import routes"
#  } > /home/${username}/${app_name}/__init__.py && \
#  chown ${username}:${username} /home/${username}/${app_name}/__init__.py
#{
#    echo "from app import app"
#    echo "@app.route('/')"
#    echo "@app.route('/index')"
#    echo "def index():"
#    echo "  return 'Hello, World!'"
#  } > /home/${username}/${app_name}/app/routes.py && \
#  chown ${username}:${username} /home/${username}/${app_name}/app/routes.py
#show "Активация виртуальной среды и установка Flask"
#python3 -m venv venv
#source venv/bin/activate
#pip3 install flask

# === Вывод данных === #

ip=$(wget -qO- ifconfig.co)
echo -e "${clr}${clr}${clr}${clr}${clr}${clr}${end}\n"
echo -e "${green}  Пользователь: ${cyan}${username}${end}"
echo -e "${green}        Пароль: ${cyan}${password}${end}"
echo -e "${green}      Порт SSH: ${cyan}${port_ssh}${end}"
echo -e "${green}      Порт SQL: ${cyan}${port_sql}${end}"
echo -e "${green}    Внешний IP: ${cyan}${ip}${end}"
echo -e "\n${cyan}  ssh ${username}@${ip} -p ${port_ssh}${end}"
echo -e "${cyan}  sh://${username}@${ip}:${port_ssh}/${end}"
echo -e "\n${clr}${clr}${clr}${clr}${clr}${clr}${end}"

rebootOS
