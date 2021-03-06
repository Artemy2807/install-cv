# Install script for OpenCV and TFLite

Этот репозиторий содержит скрипт для установки [OpenCV](http://github.com/opencv/opencv) и [TensorFlow Lite](http://github.com/tensorflow/tensorflow). Скрипт успешно работает на Debian и Ubuntu. Работа срипта в других дистрибутивах Linux не была проверена.

## Использование 
<b>Примечание:</b> по умолчанию сборка библиотек происходит в папке, в которой вы запустили скрипт.

Для запуска крипта выполните следующие команды:
```cmd
git clone https://github.com/Artemy2807/install-cv.git install-cv
cd install-cv
chmod +x install.sh
./install.sh
```
Также мы можете задавать параметры работы скрипта с помощью аргументов, о которых написано ниже.


## Аргументы командной строки:
Для того, чтобы задать аргумент необходимо написать его после команды для запуска скрипта. Может быть указано несколько аргументов. Также, если вы используете аргумент, который требует еще и указания ввода пользователя, необходимо написать этот аргумент и через пробел написать необходимый текст. Пример использования аргументов:

```c
./install --without-tf --cv-version 4.1.0 -b /home/user
```

Аргументы командной строки:
```
-h, --help                             Выводит информацию о срипте
--without-cv                           При использовании этого аргумента отключается сборка OpenCV
--without-tf                           При использовании этого аргумента отключается сборка TensorFlow Lite
--cv-version <version>                 Указать версию OpenCV для сборки (по умолчанию: 4.1.0)
--tf-version <version>                 Указать версию OpenCV для сборки (по умолчанию: v2.1.2)
-b, --build-dir <directory>            Указать папку, в которой будет производиться сборка библиотек
                                       (по умолчанию используется папка, в которой вы запустили скрипт)
-p, --prefix-install <directory>       Указать папку, в которую будет производиться установка библиотек
                                       (по умолчанию: /usr/local)
```

## Автор
Автор: Одышев Артемий
- Telegram: [@artemy](https://t.me/artemy_odeshev)
- VK: [@artemy](https://vk.com/artemyodiesiev)