@ECHO Build Extension
    set EXTENSIONNAME=RecordVideo
    set TEMPDIR=%~dp0Temp
    set FILETOZIP1=description.xml
    set FILETOZIP2=VideoStart-16.png
    set FILETOZIP3=VideoStop-16.png
    set FILETOZIP4=script.sj
    set OUTPUTFOLDER=%~dp0Output
    set OUTPUTFILE=%OUTPUTFOLDER%\%EXTENSIONNAME%
    mkdir "%TEMPDIR%"
    mkdir "%OUTPUTFOLDER%"
    for %%f in (%FILETOZIP1%, %FILETOZIP2%, %FILETOZIP3%, %FILETOZIP4%) do copy /y "%~dp0%%f" "%TEMPDIR%"
    echo Set objArgs = WScript.Arguments > _zipIt.vbs
    echo InputFolder = objArgs(0) >> _zipIt.vbs
    echo ZipFile = objArgs(1) >> _zipIt.vbs
    echo CreateObject("Scripting.FileSystemObject").CreateTextFile(ZipFile, True).Write "PK" ^& Chr(5) ^& Chr(6) ^& String(18, vbNullChar) >> _zipIt.vbs
    echo Set objShell = CreateObject("Shell.Application") >> _zipIt.vbs
    echo Wscript.Echo InputFolder >> _zipIt.vbs
    echo Set objFolder = objShell.NameSpace(InputFolder) >> _zipIt.vbs
    echo Set source = objFolder.Items >> _zipIt.vbs
    echo objShell.NameSpace(ZipFile).CopyHere(source) >> _zipIt.vbs
@ECHO *******************************************
@ECHO Zipping, please wait..
    echo wScript.Sleep 2000 >> _zipIt.vbs
    CScript  _zipIt.vbs  "%TEMPDIR%\"  "%OUTPUTFILE%.zip"
    del _zipIt.vbs
    rmdir /s /q  "%TEMPDIR%"
    rename "%OUTPUTFILE%.zip" %EXTENSIONNAME%.tcx
@ECHO *******************************************
@ECHO      ZIP Completed
pause