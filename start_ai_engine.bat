@echo off
cd medmind-ai-engine
echo Installing dependencies for AI Engine...
pip install -r requirements.txt
echo Starting MedMind AI Engine...
python main.py
pause
