@echo off
setlocal enabledelayedexpansion

:: --- SCRIPT METADATA ---
:: TITLE: Dedicated SDXL ONNX Conversion Workflow v13.9 (Final)
:: PURPOSE: A definitive script to convert SDXL models. This version removes the
::          unsupported 'torch_dtype' argument from the in-memory export script.
:: AUTHOR: Gemini
:: LAST UPDATED: 2025-09-28

:: --- CONFIGURATION ---
set "PYTHON_VERSION=3.10"
set "GIT_REPO_URL=https://github.com/huggingface/diffusers.git"
set "GIT_REPO_DIR=diffusers"
set "SDXL_CONFIG_URL=https://raw.githubusercontent.com/Stability-AI/generative-models/main/configs/inference/sd_xl_base.yaml"
set "SDXL_CONFIG_FILE=sd_xl_base.yaml"

:: --- SDXL PIPELINE CONFIG ---
set "VENV_DIR=onnx_converter_venv_sdxl"
set "DIFFUSERS_VERSION=v0.29.2"
set "PIP_PACKAGES="diffusers[torch]==0.29.2" "optimum[onnxruntime]==1.19.1" "safetensors" "accelerate==0.30.1" "transformers==4.40.2" "huggingface-hub==0.23.2""


:: --- SCRIPT BODY ---
pushd "%~dp0"
cls

:FIND_MODEL
:: 1. FIND MODEL
set "MODEL_FILE="
for %%F in (*.safetensors) do (
    if not defined MODEL_FILE (
        set "MODEL_FILE=%%F"
        set "MODEL_NAME=%%~nF"
    )
)
if not defined MODEL_FILE goto :ERROR_NO_MODEL

echo --- Automated SDXL ONNX Conversion (Stable v13.9) ---
echo [INFO] Model identified: %MODEL_FILE%
echo [INFO] Pipeline locked to: SDXL
echo.


set "STAGE1_DIR=%MODEL_NAME%_diffusers_format"
set "STAGE2_DIR=%MODEL_NAME%_onnx"

:: 2. SETUP VIRTUAL ENVIRONMENT
if exist "%VENV_DIR%\Scripts\activate.bat" goto :VENV_EXISTS

:CREATE_VENV
echo [INFO] Creating new SDXL virtual environment...
python -m venv "%VENV_DIR%" > NUL
if errorlevel 1 goto :ERROR_VENV_CREATE
call "%VENV_DIR%\Scripts\activate.bat"
echo [INFO] Installing SDXL libraries (this may take a few minutes)...
python -m pip install --upgrade pip > NUL
pip install torch torchvision torchaudio
if errorlevel 1 goto :ERROR_PIP_INSTALL
pip install %PIP_PACKAGES%
if errorlevel 1 goto :ERROR_PIP_INSTALL
goto :CLONE_REPO

:VENV_EXISTS
echo [INFO] Existing SDXL venv found. Activating and ensuring correct versions...
call "%VENV_DIR%\Scripts\activate.bat"
pip install --upgrade %PIP_PACKAGES%
if errorlevel 1 goto :ERROR_PIP_INSTALL

:CLONE_REPO
:: 3. ENSURE CLEAN DIFFUSERS REPO and GET CONFIG
if exist ".\%GIT_REPO_DIR%" rmdir /s /q ".\%GIT_REPO_DIR%"
echo [INFO] Cloning Hugging Face Diffusers repository (version %DIFFUSERS_VERSION%)...
git clone --depth 1 --branch %DIFFUSERS_VERSION% %GIT_REPO_URL% "%GIT_REPO_DIR%"
if errorlevel 1 goto :ERROR_GIT_CLONE

echo [INFO] Downloading official SDXL 1.0 Base config file...
powershell -Command "Invoke-WebRequest -Uri '%SDXL_CONFIG_URL%' -OutFile '%SDXL_CONFIG_FILE%'"
if errorlevel 1 goto :ERROR_YAML_DOWNLOAD
echo.


:STAGE1_CONVERT
:: 4. STAGE 1: Convert original checkpoint to Diffusers format
echo [STAGE 1 of 3] Converting checkpoint using SDXL config and FP16 flag...
python ".\%GIT_REPO_DIR%\scripts\convert_original_stable_diffusion_to_diffusers.py" ^
    --checkpoint_path "%MODEL_FILE%" ^
    --dump_path "%STAGE1_DIR%" ^
    --from_safetensors ^
    --original_config_file "%SDXL_CONFIG_FILE%" ^
    --half
if errorlevel 1 goto :ERROR_STAGE1
echo [SUCCESS] Stage 1 complete.
echo.


:STAGE2_EXPORT
:: 5. STAGE 2: Export the Diffusers format to ONNX
echo [STAGE 2 of 3] Running in-memory ONNX export script for sharded model...

python -c "import sys; from optimum.onnxruntime import ORTStableDiffusionXLPipeline; input_dir = sys.argv[1]; output_dir = sys.argv[2]; print(f'[EXPORT] Loading sharded FP16 model from: {input_dir}'); pipeline = ORTStableDiffusionXLPipeline.from_pretrained(input_dir, export=True); print(f'[EXPORT] Saving ONNX model to: {output_dir}'); pipeline.save_pretrained(output_dir); print('[EXPORT] ONNX export complete.')" "%STAGE1_DIR%" "%STAGE2_DIR%"
if errorlevel 1 goto :ERROR_STAGE2
echo [SUCCESS] Stage 2 complete.
echo.


:GENERATE_TEMPLATE
:: 6. STAGE 3: Generate amuse_template.json
echo [STAGE 3 of 3] Generating amuse_template.json for SDXL model...

:: Generate a new GUID and strip trailing whitespace
for /f %%i in ('powershell -Command "[guid]::NewGuid().ToString()" ^| findstr .') do set "UUID=%%i"

:: Get current date with a fixed time of midnight using native batch commands.
set "YYYY=%date:~10,4%"
set "MM=%date:~4,2%"
set "DD=%date:~7,2%"
set "dt=%YYYY%-%MM%-%DD%T00:00:00"

:: Write the JSON file based on the verified SDXL template
(
    echo {
    echo   "Id": "%UUID%",
    echo   "FileVersion": "1",
    echo   "Created": "%dt%",
    echo   "IsProtected": false,
    echo   "Name": "%MODEL_NAME%",
    echo   "ImageIcon": "REPLACE_WITH_IMAGE_URL",
    echo   "Author": "REPLACE_WITH_AUTHOR",
    echo   "Description": "REPLACE_WITH_DESCRIPTION",
    echo   "Rank": 6000,
    echo   "Group": "Online",
    echo   "Template": "SDXL",
    echo   "Category": "StableDiffusion",
    echo   "StableDiffusionTemplate": {
    echo     "PipelineType": "StableDiffusionXL",
    echo     "ModelType": "Base",
    echo     "SampleSize": 1024,
    echo     "TokenizerLength": 768,
    echo     "Tokenizer2Limit": 77,
    echo     "DiffuserTypes": [
    echo       "TextToImage",
    echo       "ImageToImage",
    echo       "ImageInpaintLegacy"
    echo     ],
    echo     "SchedulerDefaults": {
    echo       "SchedulerType": "EulerAncestral",
    echo       "Steps": 20,
    echo       "StepsMin": 4,
    echo       "StepsMax": 100,
    echo       "Guidance": 4,
    echo       "GuidanceMin": 0,
    echo       "GuidanceMax": 30,
    echo       "TimestepSpacing": "Leading",
    echo       "BetaSchedule": "ScaledLinear",
    echo       "BetaStart": 0.00085,
    echo       "BetaEnd": 0.012
    echo     }
    echo   },
    echo   "Precision": "F16",
    echo   "MemoryMin": 6,
    echo   "MemoryMax": 12,
    echo   "DownloadSize": 0,
    echo   "Website": "REPLACE_WITH_WEBSITE_URL",
    echo   "Licence": "REPLACE_WITH_LICENCE_URL",
    echo   "LicenceType": "NonCommercial",
    echo   "IsLicenceAccepted": false,
    echo   "Repository": "REPLACE_WITH_REPOSITORY_URL",
    echo   "RepositoryOwner": "REPLACE_WITH_OWNER",
    echo   "RepositoryFiles": [ "REPLACE_WITH_REPOSITORY_FILE_URLS" ],
    echo   "PreviewImages": [ "REPLACE_WITH_PREVIEW_IMAGE_URLS" ],
    echo   "Tags": [ "GPU", "F16" ]
    echo }
) > "%STAGE2_DIR%\amuse_template.json"

if errorlevel 1 goto :ERROR_TEMPLATE_GEN
echo [SUCCESS] Stage 3 complete.
echo.

:CLEANUP
:: 7. CLEANUP
echo [INFO] Cleaning up temporary files...
rmdir /s /q "%STAGE1_DIR%"
rmdir /s /q ".\%GIT_REPO_DIR%"
del "%SDXL_CONFIG_FILE%"

:SUCCESS
echo ---------------------------------
echo --- CONVERSION COMPLETE ---
echo ONNX model and template saved to: %cd%\%STAGE2_DIR%
echo ---------------------------------
goto :END

:: --- ERROR HANDLING ---
:ERROR_VENV_CREATE
echo [FATAL] Failed to create the virtual environment. Ensure Python %PYTHON_VERSION% is installed and in your PATH.
goto :END
:ERROR_PIP_INSTALL
echo [FATAL] Failed to install required Python packages. Check your network connection.
goto :END
:ERROR_GIT_CLONE
echo [FATAL] Failed to clone the diffusers repository. Ensure Git is installed and can access GitHub.
goto :END
:ERROR_YAML_DOWNLOAD
echo [FATAL] Failed to download the required SDXL config YAML file.
goto :END
:ERROR_NO_MODEL
echo [FATAL] No .safetensors file found in this directory.
goto :END
:ERROR_STAGE1
echo [FATAL] Stage 1 failed. The checkpoint may be corrupt or an incompatible format.
goto :END
:ERROR_STAGE2
echo [FATAL] Stage 2 failed. The ONNX export process encountered an error.
goto :END
:ERROR_TEMPLATE_GEN
echo [FATAL] Stage 3 failed. Could not generate the amuse_template.json file.
goto :END

:END
pause
exit /b

