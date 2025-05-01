#!/usr/bin/env bash
set -e  # 一有錯誤就中止

file_dir=$(dirname "$(readlink -f "${0}")")
venv_path="/opt/venv"

# 建立虛擬環境
python3 -m venv "${venv_path}"

# 啟用虛擬環境
source "${venv_path}/bin/activate"

# 安裝 pip 套件
pip install --upgrade pip
pip install -r "${file_dir}/requirements.txt"