## **PC Gaming Redistributable Packages AIO Installer**
 - Written by [@harryeffinpotter](https://github.com/harryeffinpotter) & greatly improved upon by the legendary [@skrimix.](https://github.com/skrimix)
&nbsp;


UPDATED ON SEPTEMBER 16TH 2024:
- Noticed that on fresh installs the script would only get the couple of extra tools at the end, ignoring the entire purpose of the script, this was due to Windows now including winget with more recent windows builds, but not including the proper sources with winget, not until windows is fully updated, and many of the times when I, and others, are running this script, we are running it after a reformat, and not necessarily after we have all cumulative updates installed. So I added lines that *SHOULD* fix this. If this issue persists for anyone please open an issue. Also wouldn't mind if someone opened an issue just to tell me "Hey this worked on a fresh install again!". Thanks!
- Added 2 packages to .net exclusions and 1 package to VC++ exclusions since they were all mismatches.
- Same code that fixes the fresh install issue mentioned above SHOULD install winget much cleaner for systems without it.

Instructions
-----
 - **Option 1)** Download **[Install.bat](https://raw.githack.com/harryeffinpotter/PC-Gaming-Redists-AIO/master/Install.bat)** and double click it to run it (DON'T RUN AS ADMIN!).

 - **Option 2)** Open a regular **PowerShell** (DON'T RUN AS ADMIN) and run the following one-liner:
 &nbsp; 

    `iwr -useb https://raw.githack.com/harryeffinpotter/PC-Gaming-Redists-AIO/master/Install.ps1 | iex`

   
[![Github All Releases](https://img.shields.io/github/downloads/harryeffinpotter/PC-Gaming-Redists/total.svg)]()  ![](https://komarev.com/ghpvc/?username=harryeffinpotter) (since 04-12-2024)


Troubleshooting:
----
If for whatever reason when you try to run the script you get [this error (Click to view)](https://i.imgur.com/TOvxPUq.png), simply [click here to download WinGet.msixbundle](https://github.com/harryeffinpotter/PC-Gaming-Redists/raw/main/WinGet.msixbundle), run it, and click Update/Install. Then try either option above again.
