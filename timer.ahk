#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; Глобальные переменные для таймеров
global timerEndTimes := []
global timerNames := ["Тир (1ч 30м)", "Схемы (4ч)", "Угон (1ч 30м)", "Почта (10м)", "Швейка (4ч)", "Дрессировка (15м)", "Сутенерка (2ч)", "Организация (2ч)", "Клубные задания (2ч)", "Ограбление магазинов (2ч)", "Еда для заключенных (1ч 30м)"]
global timerDurations := [5400, 14400, 5400, 600, 14400, 900, 7200, 7200, 7200, 7200, 5400]  ; в секундах
global gameProcesses := ["GTA5.exe", "ragemp_v.exe", "MultiplayerL.exe", "RAGEMP.exe", "FiveM.exe", "RAGEMultiplayer.exe"]
global timerGuiVisible := false
global manuallyHidden := false
global guiHWND := 0
global hotkeyList := ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11"]  ; Горячие клавиши по умолчанию

; Цвета и базовые настройки
global backgroundColor := "000000"    ; Черный фон
global textColor := "FFFFFF"          ; Белый текст
global inactiveColor := "00FF00"      ; Зеленый для неактивных таймеров
global activeColor := "FF0000"        ; Красный для активных таймеров
global windowTransparency := 200      ; Прозрачность (0-255)

; Версия и информация о скрипте
global scriptVersion := "1.0"
global scriptLastUpdate := "24.04.2025"
global scriptAuthor := "Fluffy Barbara (Гонцовский Никита)"
global scriptDiscord := "https://discord.gg/QxNGkTxgx2"

; Загружаем настройки, если есть
LoadSettings()

; Создаем GUI для таймеров
Gui, TimerGUI:New, +AlwaysOnTop +ToolWindow +LastFound, Таймер КД в GTA5 by Fluffy Barbara
guiHWND := WinExist()

; Устанавливаем цвет фона и текста
Gui, TimerGUI:Color, %backgroundColor%
Gui, TimerGUI:Font, s10 c%textColor%, Arial

; Добавляем таймеры
y := 10
Gui, TimerGUI:Add, Text, x10 y%y% w300 h20, Список таймеров:
y += 30

Loop, % timerNames.Length() {
    Gui, TimerGUI:Add, Text, x10 y%y% w180 vName%A_Index%, % timerNames[A_Index]
    Gui, TimerGUI:Add, Text, x200 y%y% w100 vTime%A_Index% c%inactiveColor%, Не активен
    Gui, TimerGUI:Add, Button, x310 y%y% w60 h20 vBtn%A_Index% gStartTimer%A_Index%, Старт
    y += 30
    timerEndTimes[A_Index] := 0
}

; Добавляем пустую линию для отделения кнопок
y += 15

; Добавляем кнопки управления с отступом
Gui, TimerGUI:Add, Button, x10 y%y% w100 h20 gOpenHotkeySettings, Настройки
Gui, TimerGUI:Add, Button, x310 y%y% w60 h22 gGuiClose, Закрыть

; Устанавливаем прозрачность для окна
WinSet, Transparent, %windowTransparency%

; Запускаем таймеры обновления
SetTimer, UpdateTimers, 1000
SetTimer, CheckGameRunning, 3000

; Регистрируем стандартные горячие клавиши
RegisterHotkeys()

; Создаем директорию для конфигураций, если её нет
If !FileExist("configs")
    FileCreateDir, configs

return

; Функция для загрузки настроек
LoadSettings() {
    global backgroundColor, textColor, inactiveColor, activeColor, windowTransparency, hotkeyList
    
    ; Загружаем цвета
    if (FileExist("TimerSettings.ini")) {
        IniRead, bg, TimerSettings.ini, Colors, Background, 000000
        IniRead, text, TimerSettings.ini, Colors, Text, FFFFFF
        IniRead, inactive, TimerSettings.ini, Colors, Inactive, 00FF00
        IniRead, active, TimerSettings.ini, Colors, Active, FF0000
        IniRead, trans, TimerSettings.ini, Colors, Transparency, 200
        
        backgroundColor := bg
        textColor := text
        inactiveColor := inactive
        activeColor := active
        windowTransparency := trans
    }
    
    ; Загружаем горячие клавиши
    if (FileExist("TimerHotkeys.ini")) {
        Loop, 11 {
            IniRead, hotkey, TimerHotkeys.ini, Hotkeys, Timer%A_Index%, % hotkeyList[A_Index]
            hotkeyList[A_Index] := hotkey
        }
    }
}

; Функция для загрузки конкретного профиля настроек
LoadProfile(profileName) {
    global backgroundColor, textColor, inactiveColor, activeColor, windowTransparency, hotkeyList
    
    profilePath := "configs\" . profileName . ".ini"
    
    if (FileExist(profilePath)) {
        ; Загружаем настройки цветов
        IniRead, bg, %profilePath%, Colors, Background, 000000
        IniRead, text, %profilePath%, Colors, Text, FFFFFF
        IniRead, inactive, %profilePath%, Colors, Inactive, 00FF00
        IniRead, active, %profilePath%, Colors, Active, FF0000
        IniRead, trans, %profilePath%, Colors, Transparency, 200
        
        backgroundColor := bg
        textColor := text
        inactiveColor := inactive
        activeColor := active
        windowTransparency := trans
        
        ; Загружаем горячие клавиши
        Loop, 11 {
            IniRead, hotkey, %profilePath%, Hotkeys, Timer%A_Index%, % hotkeyList[A_Index]
            hotkeyList[A_Index] := hotkey
        }
        
        ; Применяем настройки
        ApplySettings()
        
        ; Применяем настройки к окну настроек, если оно открыто
        ApplySettingsToHotkeyGUI()
        
        ; Сохраняем настройки как текущие
        SaveCurrentSettings()
        
        ; Регистрируем горячие клавиши заново
        RegisterHotkeys()
        
        return true
    }
    
    return false
}

; Функция для применения текущих настроек к основному интерфейсу
ApplySettings() {
    global backgroundColor, textColor, inactiveColor, activeColor, windowTransparency, guiHWND, timerNames, timerEndTimes
    
    ; Применяем настройки к главному окну
    Gui, TimerGUI:Color, %backgroundColor%
    Gui, TimerGUI:Font, s10 c%textColor%, Arial
    WinSet, Transparent, %windowTransparency%, ahk_id %guiHWND%
    
    ; Обновляем цвета текста таймеров
    Loop, % timerNames.Length() {
        if (timerEndTimes[A_Index] > 0) {
            GuiControl, TimerGUI:+c%activeColor%, Time%A_Index%
        } else {
            GuiControl, TimerGUI:+c%inactiveColor%, Time%A_Index%
        }
    }
}

; Функция для применения текущих настроек к окну настроек
ApplySettingsToHotkeyGUI() {
    global backgroundColor, textColor
    
    ; Проверяем, открыто ли окно настроек
    if WinExist("Настройки таймеров") {
        ; Применяем цвета к окну настроек
        Gui, HotkeyGUI:Color, %backgroundColor%
        Gui, HotkeyGUI:Font, s10 c%textColor%, Arial
        
        ; Обновляем все текстовые элементы
        Loop, 30 {
            GuiControl, HotkeyGUI:Font, Static%A_Index%
        }
    }
}

; Функция для сохранения текущих настроек
SaveCurrentSettings() {
    global backgroundColor, textColor, inactiveColor, activeColor, windowTransparency, hotkeyList
    
    ; Сохраняем настройки цветов
    IniWrite, %backgroundColor%, TimerSettings.ini, Colors, Background
    IniWrite, %textColor%, TimerSettings.ini, Colors, Text
    IniWrite, %inactiveColor%, TimerSettings.ini, Colors, Inactive
    IniWrite, %activeColor%, TimerSettings.ini, Colors, Active
    IniWrite, %windowTransparency%, TimerSettings.ini, Colors, Transparency
    
    ; Сохраняем горячие клавиши
    Loop, % hotkeyList.Length() {
        IniWrite, % hotkeyList[A_Index], TimerHotkeys.ini, Hotkeys, Timer%A_Index%
    }
}

; Функция для сохранения текущих настроек в профиль
SaveProfile(profileName) {
    global backgroundColor, textColor, inactiveColor, activeColor, windowTransparency, hotkeyList
    
    profilePath := "configs\" . profileName . ".ini"
    
    ; Сохраняем настройки цветов
    IniWrite, %backgroundColor%, %profilePath%, Colors, Background
    IniWrite, %textColor%, %profilePath%, Colors, Text
    IniWrite, %inactiveColor%, %profilePath%, Colors, Inactive
    IniWrite, %activeColor%, %profilePath%, Colors, Active
    IniWrite, %windowTransparency%, %profilePath%, Colors, Transparency
    
    ; Сохраняем горячие клавиши
    Loop, % hotkeyList.Length() {
        IniWrite, % hotkeyList[A_Index], %profilePath%, Hotkeys, Timer%A_Index%
    }
    
    return true
}

; Функция для получения списка доступных профилей
GetProfilesList() {
    profilesList := "|"  ; Начинаем со знака |, что позволит создать пустой первый элемент в DropDownList
    
    Loop, Files, configs\*.ini
    {
        SplitPath, A_LoopFileName, , , , fileName  ; Получаем имя файла без расширения
        profilesList .= fileName . "|"
    }
    
    return profilesList
}

; Функция для регистрации горячих клавиш
RegisterHotkeys() {
    global hotkeyList
    
    ; Удаляем предыдущие горячие клавиши, если они были
    Loop, 11 {
        Hotkey, % hotkeyList[A_Index], Off, UseErrorLevel
    }
    Hotkey, F12, Off, UseErrorLevel
    
    ; Устанавливаем новые горячие клавиши
    Loop, 11 {
        Hotkey, % hotkeyList[A_Index], StartTimer%A_Index%, UseErrorLevel
    }
    
    ; F12 всегда для показа/скрытия окна
    Hotkey, F12, ToggleWindowVisibility, UseErrorLevel
}

; Функция открытия окна настроек
OpenHotkeySettings:
    ; Получаем размеры экрана
    SysGet, MonitorCount, MonitorCount
    SysGet, MonitorPrimary, MonitorPrimary
    SysGet, MonitorWorkArea, MonitorWorkArea, %MonitorPrimary%
    
    ; Создаем GUI для настроек - увеличиваем высоту окна, чтобы разместить кнопки ниже
    Gui, HotkeyGUI:Destroy
    Gui, HotkeyGUI:New, +ToolWindow +Owner +AlwaysOnTop, Настройки таймеров
    Gui, HotkeyGUI:Color, %backgroundColor%
    Gui, HotkeyGUI:Font, s10 c%textColor%, Arial
    
    ; Создаем вкладки для настроек
    Gui, HotkeyGUI:Add, Tab2, x5 y5 w440 h430 +Buttons vSettingsTabs, Горячие клавиши|Цвета|Профили|Об авторе
    
    ; === ВКЛАДКА 1: ГОРЯЧИЕ КЛАВИШИ ===
    Gui, HotkeyGUI:Tab, 1
    
    Gui, HotkeyGUI:Add, Text, x15 y35 w350 h20, Настройка горячих клавиш для таймеров:
    y := 60
    
    ; Создаем элементы для каждого таймера
    Loop, % timerNames.Length() {
        Gui, HotkeyGUI:Add, Text, x15 y%y% w180, % timerNames[A_Index] ":"
        Gui, HotkeyGUI:Add, Hotkey, x200 y%y% w100 vHotkey%A_Index%, % hotkeyList[A_Index]
        y += 30
    }
    
    ; === ВКЛАДКА 2: ЦВЕТА ===
    Gui, HotkeyGUI:Tab, 2
    
    Gui, HotkeyGUI:Add, Text, x15 y35 w350 h20, Настройка цветовой схемы:
    
    ; Выбор цветовой схемы через выпадающий список
    Gui, HotkeyGUI:Add, Text, x15 y65 w150 h20, Цветовая схема:
    Gui, HotkeyGUI:Add, DropDownList, x170 y65 w160 vColorScheme gChangeColorScheme, Темная (по умолчанию)|Синяя|Красная|Зеленая|Фиолетовая
    
    ; Добавляем настройку прозрачности
    Gui, HotkeyGUI:Add, Text, x15 y105 w150 h20, Прозрачность:
    Gui, HotkeyGUI:Add, Slider, x170 y105 w160 h20 vTransparencySlider gUpdateTransparency Range100-255 TickInterval25, %windowTransparency%
    Gui, HotkeyGUI:Add, Text, x340 y105 w40 h20 vTransparencyValue, %windowTransparency%
    
    ; === ВКЛАДКА 3: ПРОФИЛИ ===
    Gui, HotkeyGUI:Tab, 3
    
    Gui, HotkeyGUI:Add, Text, x15 y35 w350 h20, Управление профилями настроек:
    
    ; Список доступных профилей
    Gui, HotkeyGUI:Add, Text, x15 y65 w150 h20, Выбрать профиль:
    profilesList := GetProfilesList()
    Gui, HotkeyGUI:Add, DropDownList, x170 y65 w160 vSelectedProfile, %profilesList%
    
    ; Кнопки для работы с профилями
    Gui, HotkeyGUI:Add, Button, x15 y105 w100 h25 gLoadProfileButton, Загрузить
    Gui, HotkeyGUI:Add, Button, x125 y105 w100 h25 gDeleteProfileButton, Удалить
    
    ; Создание нового профиля - используем светлый фон для текстового поля
    Gui, HotkeyGUI:Add, Text, x15 y145 w350 h20, Создать новый профиль:
    Gui, HotkeyGUI:Add, Text, x15 y175 w150 h20, Имя профиля:
    
    ; Используем контрастные цвета для видимости текста
    bgColor := "F0F0F0"  ; Светло-серый фон
    txtColor := "000000" ; Черный текст
    
    ; Создаем поле ввода с контрастными цветами
    Gui, HotkeyGUI:Add, Edit, x170 y175 w160 h20 vNewProfileName c%txtColor% Background%bgColor%
    
    ; Кнопка для сохранения профиля
    Gui, HotkeyGUI:Add, Button, x15 y205 w100 h25 gSaveProfileButton, Сохранить
 
; === ВКЛАДКА 4: ОБ АВТОРЕ ===
Gui, HotkeyGUI:Tab, 4

; Первый разделитель
Gui, HotkeyGUI:Add, Text, x15 y35 w420 h2 0x10 Center  ; Горизонтальная линия (0x10)

; Информация об авторе и скрипте в формате, близком к скриншоту - все тексты центрированы
Gui, HotkeyGUI:Add, Text, x15 y45 w420 h20 Center, Информация о скрипте:
Gui, HotkeyGUI:Add, Text, x15 y75 w420 h20 Center, Авторские права принадлежат Fluffy Barbara
Gui, HotkeyGUI:Add, Text, x15 y105 w420 h20 Center, ©Fluffy Barbara
Gui, HotkeyGUI:Add, Text, x15 y135 w420 h20 Center, Версия скрипта: 1.0
Gui, HotkeyGUI:Add, Text, x15 y165 w420 h20 Center, Последнее обновление скрипта: 24.04.2025

; Второй разделитель
Gui, HotkeyGUI:Add, Text, x15 y195 w420 h2 0x10 Center  ; Горизонтальная линия (0x10)

Gui, HotkeyGUI:Add, Text, x15 y205 w420 h20 Center, Следите за подробной информацией в Discord сервере:
; Используем элемент Link для кликабельной ссылки, также центрированный
Gui, HotkeyGUI:Add, Link, x15 y235 w420 h20 +Center, <a href="https://discord.gg/QxNGkTxgx2">https://discord.gg/QxNGkTxgx2</a>

; Третий разделитель
Gui, HotkeyGUI:Add, Text, x15 y265 w420 h2 0x10 Center  ; Горизонтальная линия (0x10)

; Добавляем дополнительную информацию о скрипте и контактах автора
Gui, HotkeyGUI:Add, Text, x15 y275 w420 h20 Center, Скрипт разработан с нуля и
Gui, HotkeyGUI:Add, Text, x15 y295 w420 h20 Center, принадлежит только его автору

; Четвертый разделитель
Gui, HotkeyGUI:Add, Text, x15 y325 w420 h2 0x10 Center  ; Горизонтальная линия (0x10)

; Контактная информация
Gui, HotkeyGUI:Add, Text, x15 y345 w420 h40 Center, По поводу предложений, улучшений пишите в личные`nсообщения discord - fluffybarbara

; Добавляем кнопки сохранения и отмены - теперь они намного ниже основных настроек
Gui, HotkeyGUI:Tab  ; Убираем выбор вкладки, чтобы кнопки были видны всегда
Gui, HotkeyGUI:Add, Button, x215 y470 w90 h25 gSaveSettings, Сохранить
Gui, HotkeyGUI:Add, Button, x315 y470 w80 h25 gCancelSettings, Отмена

; Устанавливаем текущую цветовую схему
currentScheme := "Темная (по умолчанию)"
if (backgroundColor = "000040" && textColor = "FFFFFF" && inactiveColor = "00FFFF" && activeColor = "FFA500")
    currentScheme := "Синяя"
else if (backgroundColor = "400000" && textColor = "FFFFFF" && inactiveColor = "00FF00" && activeColor = "FFFF00")
    currentScheme := "Красная"
else if (backgroundColor = "004000" && textColor = "FFFFFF" && inactiveColor = "00FFFF" && activeColor = "FF00FF")
    currentScheme := "Зеленая"
else if (backgroundColor = "400040" && textColor = "FFFFFF" && inactiveColor = "00FFFF" && activeColor = "FFFF00")
    currentScheme := "Фиолетовая"
GuiControl, Choose, ColorScheme, %currentScheme%

; Обновление значения прозрачности
SetTimer, UpdateTransparencyLabel, 100

; Отслеживаем изменения в поле имени профиля
SetTimer, UpdateProfileNameDisplay, 100

; Отображаем окно настроек - увеличиваем высоту окна
Gui, HotkeyGUI:Show, w450 h525
return

; Предпросмотр имени профиля
PreviewProfileName:
    GuiControlGet, profileName,, NewProfileName
    if (profileName = "") {
        MsgBox, Поле имени профиля пусто. Введите имя!
    } else {
        MsgBox, Введенное имя профиля: "%profileName%"
    }
return

; Отслеживание изменений в поле имени профиля
UpdateProfileNameDisplay:
    GuiControlGet, profileName,, NewProfileName
    GuiControl,, ProfileNameDisplay, %profileName%
return

; Загрузка выбранного профиля
LoadProfileButton:
    GuiControlGet, profile,, SelectedProfile
    if (profile != "") {
        if (LoadProfile(profile)) {
            TrayTip, Профили, Профиль "%profile%" успешно загружен!, 2, 0
        } else {
            TrayTip, Профили, Ошибка при загрузке профиля "%profile%"!, 2, 2
        }
    } else {
        TrayTip, Профили, Выберите профиль для загрузки!, 2, 2
    }
return

; Удаление выбранного профиля
DeleteProfileButton:
    GuiControlGet, profile,, SelectedProfile
    if (profile != "") {
        MsgBox, 4, Удаление профиля, Вы уверены, что хотите удалить профиль "%profile%"?
        IfMsgBox Yes
        {
            profilePath := "configs\" . profile . ".ini"
            FileDelete, %profilePath%
            TrayTip, Профили, Профиль "%profile%" удалён!, 2, 0
            
            ; Обновляем список профилей
            profilesList := GetProfilesList()
            GuiControl,, SelectedProfile, |%profilesList%
        }
    } else {
        TrayTip, Профили, Выберите профиль для удаления!, 2, 2
    }
return

; Сохранение нового профиля
SaveProfileButton:
    GuiControlGet, newName,, NewProfileName
    if (newName != "") {
        ; Проверяем на недопустимые символы
        if (RegExMatch(newName, "[\\/:*?""<>|]")) {
            TrayTip, Профили, Имя профиля содержит недопустимые символы!, 2, 2
            return
        }
        
        ; Применяем текущие настройки цветов и прозрачности из формы
        GuiControlGet, scheme,, ColorScheme
        ChangeColorSchemeByName(scheme)
        
        GuiControlGet, newTransparency,, TransparencySlider
        windowTransparency := newTransparency
        
        ; Обновляем настройки сразу
        ApplySettings()
        
        ; Сохраняем профиль
        if (SaveProfile(newName)) {
            TrayTip, Профили, Профиль "%newName%" успешно сохранён!, 2, 0
            
            ; Обновляем список профилей
            profilesList := GetProfilesList()
            GuiControl,, SelectedProfile, |%profilesList%
            
            ; Очищаем поле ввода
            GuiControl,, NewProfileName, 
            GuiControl,, ProfileNameDisplay, 
        } else {
            TrayTip, Профили, Ошибка при сохранении профиля!, 2, 2
        }
    } else {
        TrayTip, Профили, Введите имя для нового профиля!, 2, 2
    }
return

; Обновление значения прозрачности при перемещении слайдера
UpdateTransparency:
    GuiControlGet, newTransparency,, TransparencySlider
    windowTransparency := newTransparency
    
    ; Применяем прозрачность сразу к окну настроек
    WinGet, hwnd, ID, Настройки таймеров
    if (hwnd) {
        WinSet, Transparent, %windowTransparency%, ahk_id %hwnd%
    }
    
    ; Применяем к основному окну таймеров
    if (guiHWND) {
        WinSet, Transparent, %windowTransparency%, ahk_id %guiHWND%
    }
return

; Обновление значения прозрачности в настройках
UpdateTransparencyLabel:
    GuiControlGet, currentValue,, TransparencySlider
    GuiControl,, TransparencyValue, %currentValue%
return

; Изменение цветовой схемы по её названию
ChangeColorSchemeByName(scheme) {
    global backgroundColor, textColor, inactiveColor, activeColor, timerNames, timerEndTimes
    
    if (scheme = "Темная (по умолчанию)") {
        backgroundColor := "000000"  ; Черный
        textColor := "FFFFFF"        ; Белый
        inactiveColor := "00FF00"    ; Зеленый
        activeColor := "FF0000"      ; Красный
    } else if (scheme = "Синяя") {
        backgroundColor := "000040"  ; Темно-синий
        textColor := "FFFFFF"        ; Белый
        inactiveColor := "00FFFF"    ; Голубой
        activeColor := "FFA500"      ; Оранжевый
    } else if (scheme = "Красная") {
        backgroundColor := "400000"  ; Темно-красный
        textColor := "FFFFFF"        ; Белый
        inactiveColor := "00FF00"    ; Зеленый
        activeColor := "FFFF00"      ; Желтый
    } else if (scheme = "Зеленая") {
        backgroundColor := "004000"  ; Темно-зеленый
        textColor := "FFFFFF"        ; Белый
        inactiveColor := "00FFFF"    ; Голубой
        activeColor := "FF00FF"      ; Розовый
    } else if (scheme = "Фиолетовая") {
        backgroundColor := "400040"  ; Фиолетовый
        textColor := "FFFFFF"        ; Белый
        inactiveColor := "00FFFF"    ; Голубой
        activeColor := "FFFF00"      ; Желтый
    }
    
    ; Применяем настройки к основному окну и окну настроек сразу
    ApplySettings()
    ApplySettingsToHotkeyGUI()
}

; Изменение цветовой схемы из выпадающего списка
ChangeColorScheme:
    GuiControlGet, scheme,, ColorScheme
    ChangeColorSchemeByName(scheme)
return

; Сохранение настроек
SaveSettings:
    ; Получаем новые настройки из формы
    Loop, % timerNames.Length() {
        GuiControlGet, newHotkey, HotkeyGUI:, Hotkey%A_Index%
        hotkeyList[A_Index] := newHotkey
    }
    
    GuiControlGet, newTransparency, HotkeyGUI:, TransparencySlider
    windowTransparency := newTransparency
    
    ; Сохраняем текущие настройки
    SaveCurrentSettings()
    
    ; Применяем настройки
    ApplySettings()
    
    ; Регистрируем горячие клавиши заново
    RegisterHotkeys()
    
    ; Закрываем окно настроек
    SetTimer, UpdateTransparencyLabel, Off
    SetTimer, UpdateProfileNameDisplay, Off
    Gui, HotkeyGUI:Destroy
    
    ; Показываем уведомление о сохранении
    TrayTip, Таймеры ГТА, Настройки сохранены успешно!, 2, 0
return

; Отмена изменений настроек
CancelSettings:
    SetTimer, UpdateTransparencyLabel, Off
    SetTimer, UpdateProfileNameDisplay, Off
    Gui, HotkeyGUI:Destroy
return

; Функции для запуска таймеров
StartTimer1:
    StartTimer(1)
return

StartTimer2:
    StartTimer(2)
return

StartTimer3:
    StartTimer(3)
return

StartTimer4:
    StartTimer(4)
return

StartTimer5:
    StartTimer(5)
return

StartTimer6:
    StartTimer(6)
return

StartTimer7:
    StartTimer(7)
return

StartTimer8:
    StartTimer(8)
return

StartTimer9:
    StartTimer(9)
return

StartTimer10:
    StartTimer(10)
return

StartTimer11:
    StartTimer(11)
return

; Функция запуска таймера
StartTimer(index) {
    global inactiveColor, activeColor
    
    ; Если таймер уже запущен, сбрасываем его
    if (timerEndTimes[index] > 0) {
        timerEndTimes[index] := 0
        GuiControl, TimerGUI:+c%inactiveColor%, Time%index%
        GuiControl, TimerGUI:, Time%index%, Не активен
        GuiControl, TimerGUI:, Btn%index%, Старт  ; Меняем текст на "Старт"
        return
    }
    
    ; Запускаем таймер
    timerEndTimes[index] := A_TickCount + (timerDurations[index] * 1000)
    GuiControl, TimerGUI:+c%activeColor%, Time%index%
    GuiControl, TimerGUI:, Btn%index%, Стоп  ; Меняем текст на "Стоп"
}

; Функция обновления таймеров
UpdateTimers:
    currentTime := A_TickCount
    
    Loop, % timerEndTimes.Length() {
        if (timerEndTimes[A_Index] > 0) {
            timeLeft := (timerEndTimes[A_Index] - currentTime) / 1000
            
            if (timeLeft <= 0) {
                ; Таймер истек
                timerEndTimes[A_Index] := 0
                GuiControl, TimerGUI:+c%inactiveColor%, Time%A_Index%
                GuiControl, TimerGUI:, Time%A_Index%, Готово!
                GuiControl, TimerGUI:, Btn%A_Index%, Старт  ; Меняем текст обратно на "Старт"
                
                ; Воспроизводим звук уведомления
                SoundPlay, *64
                
                ; Показываем уведомление
                TrayTip, КД Завершен, % "КД для " timerNames[A_Index] " завершен!", 10, 1
            } else {
                ; Форматируем оставшееся время
                hours := Floor(timeLeft / 3600)
                minutes := Floor(Mod(timeLeft, 3600) / 60)
                seconds := Floor(Mod(timeLeft, 60))
                
                timeString := ""
                if (hours > 0)
                    timeString .= hours . "ч "
                if (minutes > 0 || hours > 0)
                    timeString .= minutes . "м "
                timeString .= seconds . "с"
                
                GuiControl, TimerGUI:, Time%A_Index%, %timeString%
            }
        }
    }
return

; Функция проверки запущенной игры и показа/скрытия окна
CheckGameRunning:
    ; Проверяем наличие игровых процессов
    gameFound := false
    
    ; Прямая проверка всех возможных процессов
    for _, processName in gameProcesses {
        Process, Exist, %processName%
        if (ErrorLevel > 0) {
            gameFound := true
            break
        }
    }
    
    ; Если игра найдена, окно скрыто и НЕ было скрыто вручную - показываем его
    if (gameFound && !timerGuiVisible && !manuallyHidden) {
        Gui, TimerGUI:Show, NoActivate
        timerGuiVisible := true
    }
    ; Если игра не найдена и окно видимо - скрываем его
    else if (!gameFound && timerGuiVisible) {
        Gui, TimerGUI:Hide
        timerGuiVisible := false
        manuallyHidden := false  ; Сбрасываем флаг, так как это автоматическое скрытие
    }
return

; Горячая клавиша для принудительного показа/скрытия окна
ToggleWindowVisibility:
    if (timerGuiVisible) {
        ; Если окно видимо - скрываем его и помечаем как скрытое вручную
        Gui, TimerGUI:Hide
        Gui, HotkeyGUI:Hide  ; Также скрываем окно настроек
        timerGuiVisible := false
        manuallyHidden := true
        TrayTip, Таймеры, Таймеры скрыты. Нажмите F12 для показа., 2, 0
    } else {
        ; Если окно скрыто - показываем его и снимаем отметку о ручном скрытии
        Gui, TimerGUI:Show, NoActivate
        timerGuiVisible := true
        manuallyHidden := false
    }
return

; Обработка закрытия окна настроек без сохранения
HotkeyGUIGuiClose:
HotkeyGUIGuiEscape:
    SetTimer, UpdateTransparencyLabel, Off
    SetTimer, UpdateProfileNameDisplay, Off
    Gui, HotkeyGUI:Destroy
return

; Выход из приложения
GuiClose:
    ExitApp
return