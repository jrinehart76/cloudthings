@echo off
REM SSH Key Setup Script - Generic Version
REM Author: Jason Rinehart aka Technical Anxiety
REM Version: 1.0.0
REM Created: 2025-01-01

setlocal enabledelayedexpansion

REM Prompt for username and email
set /p USERNAME="Enter your username: "
set /p EMAIL="Enter your email address: "
set SSH_DIR=%USERPROFILE%\.ssh
set HOSTNAME=%COMPUTERNAME%

echo.
echo ============================================================
echo SSH Key Setup for %USERNAME%
echo ============================================================
echo.

REM Create SSH directory if it doesn't exist
if not exist "%SSH_DIR%" (
    echo Creating SSH directory: %SSH_DIR%
    mkdir "%SSH_DIR%"
)

REM Generate Ed25519 key
set ED25519_KEY=%SSH_DIR%\id_ed25519_%USERNAME%
if not exist "%ED25519_KEY%" (
    echo Generating Ed25519 SSH key...
    ssh-keygen -t ed25519 -C "%EMAIL%" -f "%ED25519_KEY%" -N ""
    if !errorlevel! equ 0 (
        echo ✓ Ed25519 key generated successfully
    ) else (
        echo ✗ Failed to generate Ed25519 key
        goto :error
    )
) else (
    echo Ed25519 key already exists: %ED25519_KEY%
)

REM Generate RSA key for compatibility
set RSA_KEY=%SSH_DIR%\id_rsa_%USERNAME%
if not exist "%RSA_KEY%" (
    echo Generating RSA SSH key...
    ssh-keygen -t rsa -b 4096 -C "%EMAIL%" -f "%RSA_KEY%" -N ""
    if !errorlevel! equ 0 (
        echo ✓ RSA key generated successfully
    ) else (
        echo ✗ Failed to generate RSA key
        goto :error
    )
) else (
    echo RSA key already exists: %RSA_KEY%
)

echo.
echo ============================================================
echo PUBLIC KEYS GENERATED
echo ============================================================
echo.

if exist "%ED25519_KEY%.pub" (
    echo Ed25519 Public Key ^(RECOMMENDED^):
    echo ----------------------------------------
    type "%ED25519_KEY%.pub"
    echo.
)

if exist "%RSA_KEY%.pub" (
    echo RSA Public Key ^(COMPATIBILITY^):
    echo ----------------------------------------
    type "%RSA_KEY%.pub"
    echo.
)

echo ============================================================
echo NEXT STEPS:
echo ============================================================
echo 1. Copy the Ed25519 public key above
echo 2. Add it to your Git provider:
echo    - GitHub: Settings ^> SSH and GPG keys ^> New SSH key
echo    - Azure DevOps: User Settings ^> SSH public keys ^> Add
echo    - GitLab: User Settings ^> SSH Keys ^> Add key
echo 3. Test the connection:
echo    ssh -T git@github.com
echo 4. Configure Git to use SSH URLs:
echo    git remote set-url origin git@github.com:USERNAME/REPOSITORY.git
echo.
echo Keys stored in: %SSH_DIR%
echo.

goto :end

:error
echo.
echo ============================================================
echo ERROR: SSH key generation failed
echo ============================================================
echo Please ensure Git for Windows is installed and ssh-keygen is available
echo.
exit /b 1

:end
pause