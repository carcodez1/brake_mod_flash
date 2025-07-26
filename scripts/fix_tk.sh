# Remove broken venv
rm -rf .venv

# Recreate with access to system site-packages
python3 -m venv .venv --system-site-packages

# Activate
source .venv/bin/activate

# Test tkinter availability
python -c "import tkinter; print('[✓] tkinter is now available')"
