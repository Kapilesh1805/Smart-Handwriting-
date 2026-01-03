Environment notes - Smartboard backend
=====================================

What I did (summary)
- Installed OpenCV (`opencv-python`) into the Python 3.10 interpreter at:
  `C:\Users\Kapilesh\AppData\Local\Programs\Python\Python310\python.exe`
- Installed TensorFlow, Keras and supporting ML packages into the same interpreter.
- Verified imports: `cv2`, `flask`, `pymongo`, `tensorflow` all import successfully when using the Python 3.10 executable.
- Wrote an exact freeze of the installed packages to `requirements-frozen.txt` in this folder.

Why this matters
- Your machine has multiple Python installations (e.g., Python 3.13 and Python 3.10). Packages installed with one `pip` may not be available to another `python` executable. That is why `ModuleNotFoundError: No module named 'cv2'` appeared previously.

How to run the backend reliably
- Always use the Python 3.10 executable I used, for example:

```powershell
& "C:\Users\Kapilesh\AppData\Local\Programs\Python\Python310\python.exe" app.py
```

- Or run with `python` only if that `python` resolves to the above interpreter (check with `python -c "import sys; print(sys.executable)"`).

Useful commands
- Install (reproducible):

```powershell
& "C:\Users\Kapilesh\AppData\Local\Programs\Python\Python310\python.exe" -m pip install -r requirements-frozen.txt
```

- Verify OpenCV is available:

```powershell
& "C:\Users\Kapilesh\AppData\Local\Programs\Python\Python310\python.exe" -c "import cv2; print(cv2.__version__)"
```

Notes & recommendations
- There are several Python installations on this machine. If you want convenience, consider using a virtual environment created with the Python 3.10 interpreter (`python -m venv .venv`) and activating it before installing packages or running the app.
- If you prefer a single canonical interpreter, consider removing/uninstalling unused Python versions or updating PATH so `python` points to the 3.10 install.
- I saw warnings about an invalid distribution named similar to `sympy` (`-ympy` or `~ip`). You may want to clean corrupted packages by reinstalling or removing the affected site-packages directory.

If you want, I can:
- Create and activate a virtualenv in the backend folder and install the frozen requirements there.
- Replace `requirements.txt` with the new pinned `requirements-frozen.txt` (or save as `requirements.txt.pinned`).
- Help you run the backend in the correct environment and run a smoke test HTTP request.

