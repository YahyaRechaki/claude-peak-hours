# ⚡ Claude Peak Hours

> Live status page for Claude AI peak hours — know when your session limits deplete faster.

🌐 **[https://yahyarechaki.github.io/claude-peak-hours/](https://yahyarechaki.github.io/claude-peak-hours)**

---

Based on the [official Anthropic announcement](https://x.com/trq212/status/2037254607001559305): during weekday peak hours, your **5-hour session limits are consumed faster** than normal. This affects free, Pro, and Max plans.

---

## 🕒 Peak Hours

| Timezone | Window |
|---|---|
| 🇺🇸 Pacific (PT) | 5:00 AM – 11:00 AM |
| 🌐 UTC / GMT | 13:00 – 19:00 |
| 🌍 Your local time | Auto-detected on the status page |

Active **weekdays only**. Weekly limits stay the same — only the rate of depletion changes during peak.

---

## 🌐 Status Page

The live status page is hosted on GitHub Pages — just open the link above in any browser, no install or account needed.

**What it shows:**
- 🔴 / ✅ / ⚠️ real-time status indicator
- Peak hours auto-converted to **your local timezone**
- Live countdown to next peak start or end
- Progress bar during active peak hours

---

## 💻 Optional: Windows Desktop Notifier

If you want **pop-up alerts** on your Windows PC without having to check the page, you can run the included PowerShell script in the background.

It will notify you with a Windows toast notification + sound at three moments:

| Alert | Trigger |
|---|---|
| ⚠️ Warning | 10 minutes before peak starts |
| 🔴 Peak starts | Session limits now depleting faster |
| ✅ Peak ends | Back to normal — safe to run heavy jobs |

### How to use it

**1. Download** `ClaudePeakHoursNotifier.ps1` from this repo

**2. Unblock the file — mandatory, one-time step**

> **Why is this required?**
> Windows automatically flags any file downloaded from the internet as "untrusted" and will refuse to run it — even if the script is completely harmless. This has nothing to do with the script itself; Windows does this to *every* downloaded `.ps1` file without exception. The command below simply tells Windows "I downloaded this myself and I trust it", which is the standard way to enable any PowerShell script on Windows. You only need to do this once.

Open PowerShell in the folder where you saved the file and run:
```powershell
Unblock-File -Path .\ClaudePeakHoursNotifier.ps1
```
No output means it worked. **The script will not run without this step.**

**3. Allow PowerShell scripts on your machine — also one-time**

Windows disables all PowerShell scripts by default. Run this once to allow scripts you downloaded yourself:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
Type `Y` and press Enter when prompted.

**4. Run it:**
```powershell
.\ClaudePeakHoursNotifier.ps1
```
On first launch it will ask if you want it to auto-start with Windows (optional).

**5. Other commands:**
```powershell
.\ClaudePeakHoursNotifier.ps1 -Status       # Show your local peak times and exit
.\ClaudePeakHoursNotifier.ps1 -Setup        # Enable auto-startup at Windows login
.\ClaudePeakHoursNotifier.ps1 -RemoveSetup  # Disable auto-startup
```

**Requirements:** Windows 10 / 11 · PowerShell 5.1+

---

## 💡 Tips to stretch your session limits

- **Shift heavy tasks to off-peak** — long documents, code generation, and batch jobs run more efficiently outside the peak window
- **Weekends are always off-peak** — great time for intensive workflows
- **Your weekly total is unchanged** — just be mindful of when you spend it

---

## 📣 Source

Official announcement by [@trq212](https://x.com/trq212/status/2037254607001559305) (Anthropic):

> *"During weekdays between 5am–11am PT / 1pm–7pm GMT, you'll move through your 5-hour session limits faster than before... If you run token-intensive background jobs, shifting them to off-peak hours will stretch your session limits further."*

---

## 🤝 Contributing

Want to add a macOS or Linux notifier? PRs are welcome.
