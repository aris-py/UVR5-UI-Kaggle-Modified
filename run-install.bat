@echo off
setlocal enabledelayedexpansion
title UVR5 Installer

echo Welcome to the UVR5 Installer!
echo.

set "principal=%cd%"
set "CONDA_ROOT_PREFIX=%UserProfile%\Miniconda3"
set "INSTALL_ENV_DIR=%principal%\env"
set "MINICONDA_DOWNLOAD_URL=https://repo.anaconda.com/miniconda/Miniconda3-py39_23.9.0-0-Windows-x86_64.exe"
set "CONDA_EXECUTABLE=%CONDA_ROOT_PREFIX%\Scripts\conda.exe"

echo Cleaning up unnecessary files...
for %%F in (Makefile Dockerfile docker-compose.yaml *.sh) do (
    if exist "%%F" del "%%F"
)
echo Cleanup complete.
echo.

if not exist "%CONDA_EXECUTABLE%" (
    echo Miniconda not found. Starting download and installation...
    echo Downloading Miniconda...
    powershell -Command "& {Invoke-WebRequest -Uri '%MINICONDA_DOWNLOAD_URL%' -OutFile 'miniconda.exe'}"
    if not exist "miniconda.exe" (
        echo Download failed. Please check your internet connection and try again.
        goto :error
    )

    echo Installing Miniconda...
    start /wait "" miniconda.exe /InstallationType=JustMe /RegisterPython=0 /S /D=%CONDA_ROOT_PREFIX%
    if errorlevel 1 (
        echo Miniconda installation failed.
        goto :error
    )
    del miniconda.exe
    echo Miniconda installation complete.
) else (
    echo Miniconda already installed. Skipping installation.
)
echo.

echo Creating Conda environment...
call "%CONDA_ROOT_PREFIX%\_conda.exe" create --no-shortcuts -y -k --prefix "%INSTALL_ENV_DIR%" python=3.10.12
if errorlevel 1 goto :error
echo Conda environment created successfully.
echo.

if exist "%INSTALL_ENV_DIR%\python.exe" (
    echo Installing specific pip version...
    "%INSTALL_ENV_DIR%\python.exe" -m pip install "pip<24.1"
    if errorlevel 1 goto :error
    echo Pip installation complete.
    echo.
)

echo Installing dependencies...
call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%" || goto :error
pip install --upgrade setuptools || goto :error
pip install -r "%principal%\requirements.txt" || goto :error
pip install --extra-index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/ort-cuda-12-nightly/pypi/simple/ onnxruntime-gpu
call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" deactivate
echo Dependencies installation complete.
echo

echo UVR5 has been installed successfully!
echo To start UVR5, please run 'run-uvr5.bat'.
echo.
pause
exit /b 0

:error
echo An error occurred during installation. Please check the output above for details.
pause
exit /b 1