$git = "C:\Program Files\Git\cmd\git.exe"
$root = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent

Set-Location $root

# Initialize repository
& $git init
& $git branch -M main

# Configure local git user
& $git config user.name "jaylouvipinosa7-bit"
& $git config user.email "jaylouvipinosa7@users.noreply.github.com"

# Check remote
$existingRemote = & $git remote get-url origin 2>$null
if ($existingRemote) {
    & $git remote set-url origin "https://github.com/jaylouvipinosa7-bit/ProcjectParakayRene2.git"
} else {
    & $git remote add origin "https://github.com/jaylouvipinosa7-bit/ProcjectParakayRene2.git"
}

# Add files
Write-Host "Adding files to git..."
& $git add .

# Status
& $git status --short

# Commit
& $git commit -m "Initial release: PvZ Fusion 4.0 Interactive Stream Studio with TikTok & Google login"

Write-Host "Local commit ready for push!"
