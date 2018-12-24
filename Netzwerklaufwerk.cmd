@echo off
REM ################################################################################
REM # Skript zum automatischen Verbinden von Netzwerklaufwerken                    #
REM # Autor: Maximilian Bauknecht (max@maexbower.de) 24.12.2018                    #
REM # Bitte für jedes Laufwerk eine Kopie erstellen und in den Autostart legen     #
REM ################################################################################

REM REMOTE_SERVER ist der Name oder die IP Adresse der NAS.
SET REMOTE_SERVER=192.168.2.1

REM REMOTE_PFAD ist das Verzeichnis auf der NAS, das eingebunden werden soll.
SET REMOTE_PFAD=\angebote

REM REMOTE_USER ist der Benutzer der NAS, mit der auf die Freigabe zugegriffen werden kann.
SET REMOTE_USER=user1

REM REMOTE_PASSWORT ist das zu dem Benutzer gehörende Passwort
SET REMOTE_PASSWORT=abc123

REM LAUFWERK ist der lokale Laufwerksbuchstabe, der verwendet werden soll.
SET LAUFWERK=X


REM ##################################################
REM ##########Ab hier nichts mehr Ändern #############
REM ##################################################

@echo ##################################
@echo # Verbinde das Laufwerk: 
@echo #  PFAD=%REMOTE_PFAD%
@echo #  BENUTZER=%REMOTE_USER%
@echo #  LAUFWERK=%LAUFWERK%
@echo ##################################
@echo Lösche aktive Verbindungen für Laufwerk %LAUFWERK%
NET USE %LAUFWERK%: /DELETE >nul 2>&1
SET ER_NET_DEL=%ERRORLEVEL%

IF %ER_NET_DEL%==0 (
	@ECHO Das Trennen von %LAUFWERK%: war erfolgreich
) ELSE (
	IF %ER_NET_DEL%==2 (
		REM Netzwerklaufwerk war noch nicht verbunden.
		@echo Laufwerk war noch nicht verbunden.
	) ELSE (
		@ECHO Das Trennen von %LAUFWERK%: war nicht erfolgreich
	)
)

@echo Versuche die Verbindung zum Netzwerklaufwerk herzustellen:
@echo Teste Erreichbarkeit:
@ECHO ...
PING %REMOTE_SERVER% -n 2 -w 1000 >nul 2>&1
SET ER_REMOTE_PING=%ERRORLEVEL%
IF %ER_REMOTE_PING%==1 (
	@ECHO Die NAS scheint nicht erreichbar zu sein. Bitte Prüfen, ob Sie läuft.
	@ECHO Errorcode %ER_REMOTE_PING%
	GOTO NICHT_ERREICHBAR
)
@ECHO Die NAS ist erreichbar, versuche das Laufwerk einzubinden:
@ECHO ...
@ECHO # Beginn Systemmeldung
NET USE %LAUFWERK%: \\%REMOTE_SERVER%%REMOTE_PFAD% %REMOTE_PASSWORT% /USER:%REMOTE_USER% /PERSISTENT:YES 
SET ER_NET_USE=%ERRORLEVEL%
@ECHO # Ende Systemmeldung
IF %ER_NET_USE%==0 (
	@ECHO Laufwerk %LAUFWERK% wurde verbunden.
) ELSE (
	@ECHO Die Verbindung zum Laufwerk kann nicht hergestellt werden.
	@ECHO Errorcode %ER_NET_USE%
	GOTO SONSTIGER_FEHLER
)
@ECHO Prüfe Zugriff auf das Laufwerk:
@ECHO ...
SET CURRENT_DIR=%CD%
CD %LAUFWERK%: >nul 2>&1
SET ER_CD_LAUFWERK=%ERRORLEVEL%
CD %CURRENT_DIR% >nul 2>&1
IF %ER_CD_LAUFWERK%==0 (
	@ECHO Das Laufwerk ist nun Verfügbar
) ELSE (
	@ECHO Das einbinden des Laufwerks war nicht erfolgreich
	@ECHO Errorcode %ER_CD_LAUFWERK%
	GOTO SONSTIGER_FEHLER
)

exit 0
:NICHT_ERREICHBAR
PAUSE
exit 1

:SONSTIGER_FEHLER
PAUSE
exit 2