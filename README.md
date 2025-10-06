# StableDiffusion-to-onnx-Amuse
Windows scripts to convert an SDXL or SD1.5 safetensors file to ONNX and generate an Amuse template to import.


Of course. Your description is accurate and concise. Here is a complete README.md file for your GitHub repository, structured to be clear and comprehensive for users.

Automated Stable Diffusion to ONNX Conversion Scripts
Windows batch scripts to convert an SDXL or SD1.5 .safetensors file to ONNX and generate an Amuse-compatible template for import.

These scripts provide a streamlined, automated workflow for converting Stable Diffusion models (.safetensors format) into the ONNX format, ready for use in applications that support it. Each script handles all necessary steps, from setting up a dedicated Python environment to generating the final model and a corresponding amuse_template.json file.




Features

Automated Environment Setup: Creates a dedicated Python virtual environment with the correct dependencies for each model type (SD1.5 or SDXL) to ensure a clean and reliable conversion process.



Single-File Conversion: Just place the script in the same directory as your .safetensors model and run it. No manual path configuration is needed.

Two Dedicated Scripts:


Automated_Conversion_Setup_SD-1.5_with_index.bat: For Stable Diffusion 1.5 models.


Automated_Conversion_Setup_SDXL_with_index.bat: For Stable Diffusion XL models.

Multi-Stage Process: The conversion is handled in distinct stages:

Convert .safetensors to the Hugging Face Diffusers format.


Export the Diffusers model to ONNX.



Generate a populated amuse_template.json for easy integration.




Automatic Cleanup: Temporary files and folders, such as the intermediate Diffusers model and the cloned repository, are removed upon successful completion.


Prerequisites
Before running these scripts, ensure you have the following installed on your Windows system:

Python: Version 3.10 is specified in the scripts. Ensure it's installed and the executable is added to your system's PATH.



Git: Required to clone the Hugging Face Diffusers repository.


Windows PowerShell: Used for downloading the SDXL configuration file and generating a unique ID for the template file. It is included by default in modern Windows versions.

How to Use
Download the Script: Choose the correct script for your model (SD-1.5 or SDXL).

Place Files Together: Create a new folder and place both the downloaded .bat script and your single .safetensors model file inside it.

Run the Script: Double-click the .bat file to execute it. A command prompt window will appear and display the progress of the conversion.

Wait for Completion: The first run will take several minutes as it needs to set up the virtual environment and download the required libraries. Subsequent runs will be faster.

Retrieve Your Files: Once completed, a new folder named MODEL_NAME_onnx will be present. This folder contains the converted ONNX model components and the amuse_template.json file.

Script Breakdown
The scripts perform the following actions automatically:

Model Detection: Locates the .safetensors file in the directory.

Environment Setup: Creates a Python virtual environment (onnx_converter_venv_sd15 or onnx_converter_venv_sdxl) and installs specific, version-locked libraries like diffusers, optimum, and torch to prevent version conflicts.


Repository Cloning: Clones the required version of the Hugging Face diffusers repository, which contains the necessary conversion scripts.



Stage 1 (Diffusers Conversion): The script runs convert_original_stable_diffusion_to_diffusers.py to convert the source .safetensors file into a Diffusers directory structure. The SDXL script additionally downloads and uses the official sd_xl_base.yaml config file for this stage.



Stage 2 (ONNX Export): The Diffusers format model is then exported to the ONNX format. The method differs slightly between the scripts to accommodate the architectural differences between SD1.5 and SDXL.



Stage 3 (Template Generation): An amuse_template.json file is generated with pre-filled values based on verified templates for either SD1.5 or SDXL , including a unique UUID and the current date.





Cleanup: All intermediate files, including the Diffusers model folder and the cloned repository, are deleted, leaving only the final ONNX output folder.

Troubleshooting
If the script fails, check the command prompt window for one of the following fatal error messages:


[FATAL] No .safetensors file found...: Make sure your model file has a .safetensors extension and is in the same directory as the script.


[FATAL] Failed to create the virtual environment...: This usually means Python 3.10 is not installed correctly or is not in your system's PATH.



[FATAL] Failed to clone the diffusers repository...: Git is likely not installed or cannot access GitHub due to network or firewall issues.



[FATAL] Failed to install required Python packages...: Your internet connection may be unstable, or a firewall could be blocking access to PyPI (the Python Package Index).



[FATAL] Stage 1 failed...: The model checkpoint may be corrupted, not a valid SD1.5/SDXL file, or otherwise incompatible with the conversion script.


[FATAL] Stage 2 failed...: The ONNX export process failed. This can be due to various issues, including insufficient RAM or problems with the underlying libraries.

[FATAL] Failed to download the required SDXL config YAML file...: (SDXL script only) The script could not download the configuration file from GitHub. Check your network connection.


[FATAL] Could not generate the amuse_template.json file...: This is a rare error that may indicate a problem with file permissions in the directory
