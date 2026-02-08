rem robocopy "." "C:\Games\World of Warcraft-USA\_retail_\Interface\AddOns\!MyAddon" /E /XD .git .vs /XF deploy.bat *.sln .git*
robocopy . "C:\Games\World of Warcraft-USA\_retail_\Interface\AddOns\!MyAddon" /E /XD .git .vs /XF deploy.bat *.sln .git* /XA:H /R:0 /W:0
