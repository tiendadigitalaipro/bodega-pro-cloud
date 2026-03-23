@echo off
title Bodega Pro Cloud — Servidor Local
echo.
echo  ================================================
echo   Bodega Pro Cloud - A2K Digital Studio
echo   Iniciando servidor local en puerto 8080...
echo  ================================================
echo.
echo  Abre tu navegador en:
echo  http://localhost:8080/cliente.html
echo.
echo  Presiona Ctrl+C para detener el servidor.
echo.
cd /d "%~dp0"
start "" "http://localhost:8080/cliente.html"
http-server . -p 8080 --cors
pause
