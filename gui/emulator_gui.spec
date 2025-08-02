# File: gui/emulator_gui.spec
# PyInstaller hardened build spec – BrakeFlasher Emulator GUI
# Author: Jeffrey Plewak
# License: Proprietary – NDA / IP Assigned

import os
from PyInstaller.utils.hooks import collect_data_files

block_cipher = None

pathex = [os.path.abspath('gui')]

a = Analysis(
    ['emulator_gui.py'],
    pathex=pathex,
    binaries=[],
    datas=[
        ('gui/assets/icon.ico', 'gui/assets'),
        ('gui/config_template.json', 'gui'),
        ('gui/state/presets/', 'gui/state/presets'),
    ],
    hiddenimports=['tkinter', 'yaml', 'jsonschema'],
    hookspath=[],
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='BrakeFlasherEmulator',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    icon='gui/assets/icon.ico',
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    name='BrakeFlasherEmulator'
)
