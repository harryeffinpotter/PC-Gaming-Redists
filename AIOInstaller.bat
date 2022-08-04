@echo off

powershell -Command "&{[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12}; """"& { $((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/harryeffinpotter/PC-Gaming-Redists-AIO/main/Install.ps1').Content)}"""" | Invoke-Expression"

pause
exit /b
