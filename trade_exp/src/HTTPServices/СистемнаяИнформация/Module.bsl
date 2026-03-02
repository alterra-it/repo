
Функция getSystemInformationGET(Запрос)  
	
	JSON = ПолучитьСистемнуюИнформациюВJSON();
    
    Если ПустаяСтрока(JSON) Тогда
        Ответ = Новый HTTPСервисОтвет(500);
		Ответ.УстановитьТелоИзСтроки("Ошибка получения данных системы");
    Иначе
       	Ответ = Новый HTTPСервисОтвет(200);

        Ответ.Заголовки["Content-Type"] = "application/json; charset=utf-8";
        Ответ.УстановитьТелоИзСтроки(JSON);
    КонецЕсли;
	
	Возврат Ответ;
КонецФункции    

Функция ПолучитьСистемнуюИнформациюВJSON() Экспорт

    // PowerShell-скрипт (в одну строку, без переносов)
    Скрипт = 
	    "$MemoryInfo = Get-CimInstance -ClassName Win32_OperatingSystem;" +
	    "$TotalMemory = [long]$MemoryInfo.TotalVisibleMemorySize * 1KB;" +
	    "$FreeMemory = [long]$MemoryInfo.FreePhysicalMemory * 1KB;" +
	    "$UsedMemory = $TotalMemory - $FreeMemory;" +
	    "$MemoryUsagePercent = [math]::Round(($UsedMemory / $TotalMemory) * 100, 2);" +
	    "try {" +
	        "$null = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop;" +
	        "Start-Sleep -Milliseconds 500;" +
	        "$CPUUsage = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop).CounterSamples.CookedValue;" +
	        "$CPUUsage = [math]::Round($CPUUsage, 2);" +
	    "} catch {" +
	        "$CPUUsage = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average;" +
	        "$CPUUsage = [math]::Round($CPUUsage, 2);" +
	    "};" +
	    "try {" +
	        "$DiskQueue = (Get-Counter '\PhysicalDisk(_Total)\Avg. Disk Queue Length' -ErrorAction Stop).CounterSamples.CookedValue;" +
	        "$DiskQueue = [math]::Round($DiskQueue, 2);" +
	    "} catch {" +
	        "$DiskQueue = 0;" +
	    "};" +
	    "$SystemInfo = [PSCustomObject]@{" +
	        "Timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss';" +
	        "CPUUsagePercent = $CPUUsage;" +
	        "TotalMemoryBytes = $TotalMemory;" +
	        "UsedMemoryBytes = $UsedMemory;" +
	        "FreeMemoryBytes = $FreeMemory;" +
	        "MemoryUsagePercent = $MemoryUsagePercent;" +
	        "DiskQueueLength = $DiskQueue" +
	    "};" +
	    "$SystemInfo | ConvertTo-Json";	
    // Подготовка команды
    КомандаЗапуска = "powershell.exe -Command """ + Скрипт + """";
    
    Попытка
        // Создаём COM-объект WshShell
        WshShell = Новый COMОбъект("WScript.Shell");

        // Создаём процесс через Exec
        Process = WshShell.Exec(КомандаЗапуска);

        // Ждём завершения выполнения команды
        Пока Process.Status = 0 Цикл
            
        КонецЦикла;

        // Читаем вывод из stdout
        РезультатJSON = Process.StdOut.ReadAll();

        // Опционально: проверяем stderr, если были ошибки
        StdErrOutput = Process.StdErr.ReadAll();
        Если НЕ ПустаяСтрока(StdErrOutput) Тогда
            Сообщить("Ошибки PowerShell: " + StdErrOutput);
        КонецЕсли;

        Возврат РезультатJSON;

    Исключение
        // Логирование ошибки
        Сообщить("Ошибка при выполнении PowerShell: " + ОписаниеОшибки());
        Возврат "";
    КонецПопытки;

КонецФункции