# zabbix-install-bat
Zabbix installation bat script
Установка агента Zabbix

Подготовка к установке:
1. Расширение «Open Hardware Monitor» для работы требует  NET Framework 3.
2. Для идентификации компьютера используется параметр конфигурации «hostname»который равен имени компьютера. Перед установкой компьютеру необходимо задать уникальное имя и перезагрузить либо убедиться в его уникальности.

Чтобы установить агент, необходимо:
редактировать скрипт   «install.bat », изменив переменную serverip=10.10.10.171 чтобы она соответствовала адресу вашего сервера Zabbix.
запустить скрипт “install.bat” с правами администратора компьютера.


Скрипт:
останавливает службу мониторинга если она запущена 
 удаляет старые файлы агента 
 копирует новые  файлы агента
 копирует файлы дополнительных расширений,
 создаёт разрешающее правило брэндмауэра Windows если его не существует
 стартует службу мониторинга. 

Возможные проблемы: 

1. Скрипт вошёл в цикл и не завершается.
 Решение: Запустить скрипт с правами администратора. 

2. Скрипт аварийно завершил работу, не скопировав файлы:
Решение: Убедиться что в пути к скрипту нет русских символов, перенести папку с инсталятором в корень диска.

3. При возникновении проблем с антивирусом необходимо добавить в исключения следующие пути и файлы:
«%PROGRAMFILES%\zabbix» обычно:  «C:\Program Files\zabbix»
«%WINDIR%\system32\smartctl.exe» обычно: «C:\Windows\System32\smartctl.exe»
«%WINDIR%\system32\OpenHardwareMonitorReport.exe» обычно: «C:\Windows\System32\OpenHardwareMonitorReport.exe»
«%WINDIR%\system32\OpenHardwareMonitorLib.dll» обычно: «C:\Windows\System32\OpenHardwareMonitorLib.dll»
