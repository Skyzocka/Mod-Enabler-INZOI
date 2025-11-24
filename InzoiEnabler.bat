<# : batch portion
@echo off
title InZOI Mod Enabler
color 0b
echo Thanks for using my tool. For problems and suggestions, you can ask me (Skyzocka) on Nexus Mods and Github :)
echo Starting InZOI Mod Enabler...
echo Loading GUI, please wait...
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (${%~f0} | Out-String)"
goto :eof
#>

# --- START OF POWERSHELL GUI CODE ---
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURATION STORAGE LOGIC ---
$configDir = "$env:APPDATA\InzoiModFixer"
$configPath = "$configDir\config.json"

function Load-Config {
    if (Test-Path $configPath) {
        try {
            $json = Get-Content $configPath -Raw | ConvertFrom-Json
            if ($json.DocPath) { $script:savedDocPath = $json.DocPath }
            if ($json.GamePath) { $script:savedGamePath = $json.GamePath }
        } catch { 
            # Ignore config errors
        }
    }
}

function Save-Config {
    param($dPath, $gPath)
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
    
    $data = @{
        DocPath = $dPath
        GamePath = $gPath
    }
    $data | ConvertTo-Json | Set-Content $configPath -Encoding UTF8
}

Load-Config

# --- HELPER: MODERN FOLDER BROWSER ---
function Select-Folder {
    param([string]$Description, [string]$InitialDirectory)
    
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Title = $Description
    $ofd.FileName = "Select This Folder" # Default selection name
    $ofd.ValidateNames = $false
    $ofd.CheckFileExists = $false
    $ofd.CheckPathExists = $true
    
    if ($InitialDirectory -and (Test-Path $InitialDirectory)) { 
        $ofd.InitialDirectory = $InitialDirectory 
    }

    $ofd.Filter = "Folder Selection|*.*" 
    
    if ($ofd.ShowDialog() -eq "OK") {
        # Return the directory containing the "selected file"
        # Since we are selecting "Select This Folder" virtual file inside the target dir
        return [System.IO.Path]::GetDirectoryName($ofd.FileName)
    }
    return $null
}

# --- WINDOW CONFIGURATION ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "InZOI Mod Enabler"
$form.Size = New-Object System.Drawing.Size(800, 700)
$form.StartPosition = "CenterScreen"
$form.BackColor = "#2b2b2b"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# --- FONTS & COLORS ---
$fontHeader = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fontNormal = New-Object System.Drawing.Font("Segoe UI", 10)
$fontLog = New-Object System.Drawing.Font("Consolas", 9)
$colorText = "#ffffff"
$colorInput = "#404040"
$colorBtn = "#007acc"
$colorErr = "#ff5555"
$colorSuccess = "#50fa7b"
$colorWarn = "#f1fa8c"

# --- UI ELEMENTS ---

# Header
$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "InZOI Mod Enabler by Skyzocka"
$lblHeader.Location = New-Object System.Drawing.Point(20, 20)
$lblHeader.Size = New-Object System.Drawing.Size(760, 40)
$lblHeader.Font = $fontHeader
$lblHeader.ForeColor = $colorText
$form.Controls.Add($lblHeader)

# 1. Documents Path
$grpDocs = New-Object System.Windows.Forms.GroupBox
$grpDocs.Text = "Step 1: Mods Folder (Documents)"
$grpDocs.ForeColor = "#aaaaaa"
$grpDocs.Location = New-Object System.Drawing.Point(20, 70)
$grpDocs.Size = New-Object System.Drawing.Size(740, 80)
$form.Controls.Add($grpDocs)

$txtDocPath = New-Object System.Windows.Forms.TextBox
$txtDocPath.Location = New-Object System.Drawing.Point(15, 30)
$txtDocPath.Size = New-Object System.Drawing.Size(600, 25)
$txtDocPath.BackColor = $colorInput
$txtDocPath.ForeColor = $colorText
$txtDocPath.BorderStyle = "FixedSingle"
$grpDocs.Controls.Add($txtDocPath)

$btnBrowseDoc = New-Object System.Windows.Forms.Button
$btnBrowseDoc.Text = "Browse..."
$btnBrowseDoc.Location = New-Object System.Drawing.Point(625, 29)
$btnBrowseDoc.Size = New-Object System.Drawing.Size(100, 27)
$btnBrowseDoc.BackColor = "#555555"
$btnBrowseDoc.ForeColor = "White"
$btnBrowseDoc.FlatStyle = "Flat"
$grpDocs.Controls.Add($btnBrowseDoc)

# Logic: Use saved path if available, otherwise auto-detect
if ($script:savedDocPath) {
    $txtDocPath.Text = $script:savedDocPath
} else {
    $defaultDocs = [System.IO.Path]::Combine([Environment]::GetFolderPath("MyDocuments"), "inZOI", "Mods")
    if (Test-Path $defaultDocs) {
        $txtDocPath.Text = $defaultDocs
    } else {
        $fallbackDocs = [System.IO.Path]::Combine([Environment]::GetFolderPath("MyDocuments"), "inZOI")
        if (Test-Path $fallbackDocs) { $txtDocPath.Text = $fallbackDocs }
    }
}

# 2. Game Path
$grpGame = New-Object System.Windows.Forms.GroupBox
$grpGame.Text = "Step 2: Game Installation Path (For .pak fixes)"
$grpGame.ForeColor = "#aaaaaa"
$grpGame.Location = New-Object System.Drawing.Point(20, 160)
$grpGame.Size = New-Object System.Drawing.Size(740, 80)
$form.Controls.Add($grpGame)

$lblGameHint = New-Object System.Windows.Forms.Label
$lblGameHint.Text = "Inside the game, find or create a new mods folder. Example: C:\inZOI\BlueClient\Content\Paks\~mods"
$lblGameHint.Location = New-Object System.Drawing.Point(15, 60)
$lblGameHint.Size = New-Object System.Drawing.Size(700, 20)
$lblGameHint.ForeColor = "#888888"
$grpGame.Controls.Add($lblGameHint)

$txtGamePath = New-Object System.Windows.Forms.TextBox
$txtGamePath.Location = New-Object System.Drawing.Point(15, 30)
$txtGamePath.Size = New-Object System.Drawing.Size(600, 25)
$txtGamePath.BackColor = $colorInput
$txtGamePath.ForeColor = $colorText
$txtGamePath.BorderStyle = "FixedSingle"
if ($script:savedGamePath) { $txtGamePath.Text = $script:savedGamePath }
$grpGame.Controls.Add($txtGamePath)

$btnBrowseGame = New-Object System.Windows.Forms.Button
$btnBrowseGame.Text = "Select"
$btnBrowseGame.Location = New-Object System.Drawing.Point(625, 29)
$btnBrowseGame.Size = New-Object System.Drawing.Size(100, 27)
$btnBrowseGame.BackColor = "#555555"
$btnBrowseGame.ForeColor = "White"
$btnBrowseGame.FlatStyle = "Flat"
$grpGame.Controls.Add($btnBrowseGame)

# Status Label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Ready to scan."
$lblStatus.Location = New-Object System.Drawing.Point(20, 260)
$lblStatus.Size = New-Object System.Drawing.Size(740, 30)
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblStatus.ForeColor = "#aaaaaa"
$lblStatus.TextAlign = "MiddleCenter"
$form.Controls.Add($lblStatus)

# Fix Button
$btnFix = New-Object System.Windows.Forms.Button
$btnFix.Text = "SCAN & FIX MODS"
$btnFix.Location = New-Object System.Drawing.Point(250, 300)
$btnFix.Size = New-Object System.Drawing.Size(300, 50)
$btnFix.BackColor = $colorBtn
$btnFix.ForeColor = "White"
$btnFix.Font = [System.Drawing.Font]::new($fontNormal.FontFamily, 11, [System.Drawing.FontStyle]::Bold)
$btnFix.FlatStyle = "Flat"
$btnFix.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnFix)

# Log Output
$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 370)
$txtLog.Size = New-Object System.Drawing.Size(740, 250)
$txtLog.BackColor = "#1e1e1e"
$txtLog.ForeColor = "#dddddd"
$txtLog.Font = $fontLog
$txtLog.ReadOnly = $true
$txtLog.BorderStyle = "None"
$form.Controls.Add($txtLog)

# --- FUNCTIONS ---

function Append-Log {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    $color = [System.Drawing.Color]::White
    if ($Type -eq "ERROR") { $color = [System.Drawing.ColorTranslator]::FromHtml($colorErr) }
    if ($Type -eq "SUCCESS") { $color = [System.Drawing.ColorTranslator]::FromHtml($colorSuccess) }
    if ($Type -eq "WARN") { $color = [System.Drawing.ColorTranslator]::FromHtml($colorWarn) }

    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.SelectionColor = [System.Drawing.Color]::Gray
    $txtLog.AppendText("[$timestamp] ")
    
    $txtLog.SelectionColor = $color
    $txtLog.AppendText("$Message`r`n")
    $txtLog.ScrollToCaret()
}

$btnBrowseDoc.Add_Click({
    $selected = Select-Folder -Description "Select inZOI Mods Folder (Documents)" -InitialDirectory $txtDocPath.Text
    if ($selected) {
        $txtDocPath.Text = $selected
        Check-Status
    }
})

$btnBrowseGame.Add_Click({
    $selected = Select-Folder -Description "Select Game Folder (Content/Paks...)" -InitialDirectory $txtGamePath.Text
    if ($selected) {
        $txtGamePath.Text = $selected
        Check-Status
    }
})

function Check-Status {
    $issuesFound = $false
    $docPath = $txtDocPath.Text
    $gamePath = $txtGamePath.Text

    # SAFE CHECK: Documents Path
    if (![string]::IsNullOrWhiteSpace($docPath)) {
        try {
            if (Test-Path $docPath) {
                $manifests = Get-ChildItem -Path $docPath -Recurse -Filter "mod_manifest.json" -ErrorAction SilentlyContinue
                foreach ($file in $manifests) {
                    try {
                        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
                        if ($json.bEnable -eq $false) { $issuesFound = $true; break }
                    } catch {}
                }
            }
        } catch {}
    }

    # SAFE CHECK: Game Path (Fixed Exception here)
    if (!$issuesFound -and ![string]::IsNullOrWhiteSpace($gamePath)) {
        try {
            if (Test-Path $gamePath) {
                $paks = Get-ChildItem -Path $gamePath -Recurse -Filter "*.pak_disabled" -ErrorAction SilentlyContinue
                if ($paks) { $issuesFound = $true }
            }
        } catch {
            # Ignore invalid paths during typing
        }
    }

    if ($issuesFound) {
        $lblStatus.Text = "Mods need to be enabled again!"
        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($colorErr)
    } else {
        $lblStatus.Text = "Ready to scan."
        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#aaaaaa")
    }
}

$btnFix.Add_Click({
    $txtLog.Clear()
    $docPath = $txtDocPath.Text
    $gamePath = $txtGamePath.Text
    
    # SAVE CONFIG HERE
    Save-Config $docPath $gamePath

    $totalFound = 0
    $patched = 0
    $failed = 0

    Append-Log "Starting repair process..." "INFO"

    # STEP 1: JSON FIX
    if (![string]::IsNullOrWhiteSpace($docPath) -and (Test-Path $docPath)) {
        Append-Log "Scanning Documents: $docPath" "INFO"
        $manifests = Get-ChildItem -Path $docPath -Recurse -Filter "mod_manifest.json"
        
        foreach ($file in $manifests) {
            try {
                $content = Get-Content $file.FullName -Raw -Encoding UTF8
                $json = $content | ConvertFrom-Json
                
                $modName = if ($json.FriendlyName) { $json.FriendlyName } else { $file.Name }

                if ($json.bEnable -eq $false) {
                    $json.bEnable = $true
                    $newContent = $json | ConvertTo-Json -Depth 20
                    $newContent | Set-Content $file.FullName -Encoding UTF8
                    
                    Append-Log "Fixed Manifest: $modName" "SUCCESS"
                    $patched++
                }
            } catch {
                Append-Log "ERROR with $modName : $_" "ERROR"
                $failed++
            }
        }
    } else {
        if ([string]::IsNullOrWhiteSpace($docPath)) {
             Append-Log "Documents path is empty!" "ERROR"
        } else {
             Append-Log "Documents path not found!" "ERROR"
        }
        [System.Windows.Forms.MessageBox]::Show("Documents path is invalid or empty.", "Error", "OK", "Error")
        return
    }

    # STEP 2: PAK FIX
    if (![string]::IsNullOrWhiteSpace($gamePath) -and (Test-Path $gamePath)) {
        Append-Log "Scanning Game Folder: $gamePath" "INFO"
        $disabledPaks = Get-ChildItem -Path $gamePath -Recurse -Filter "*.pak_disabled"
        
        foreach ($file in $disabledPaks) {
            try {
                $newName = $file.FullName -replace "\.pak_disabled$", ".pak"
                Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
                Append-Log "Renamed: $($file.Name) -> .pak" "SUCCESS"
                $patched++
            } catch {
                Append-Log "ERROR renaming $($file.Name): $_" "ERROR"
                $failed++
            }
        }
    } else {
        Append-Log "No game path selected or invalid. Skipping .pak fix." "WARN"
    }

    # FINAL LOGIC
    if ($failed -eq 0 -and $patched -gt 0) {
        $lblStatus.Text = "Successfully patched all found mods"
        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#006400") # Dark Green
        [System.Windows.Forms.MessageBox]::Show("All mods have been successfully enabled!", "Success", "OK", "Information")
    } elseif ($failed -eq 0 -and $patched -eq 0) {
        $lblStatus.Text = "No disabled mods found."
        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($colorText)
    } elseif ($failed -gt 0) {
        $logPath = "$env:USERPROFILE\inzoi_patcher_error_log.txt"
        $txtLog.Text | Out-File $logPath -Encoding UTF8
        
        Append-Log "LOG FILE CREATED: $logPath" "ERROR"
        Append-Log "Could not patch, you can contact me (Skyzocka) for help." "ERROR"

        if ($patched -gt $failed) {
            $lblStatus.Text = "Successfully patched most files except $failed Mods"
            $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($colorSuccess)
        } else {
            $lblStatus.Text = "$patched were patched, while $failed weren't. Check Log."
            $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("Yellow")
        }
    }
})

# Initial Check (delayed slightly to ensure UI is ready)
Check-Status

# Start GUI
$form.ShowDialog() | Out-Null

# Copyright (c) 2025 Skyzocka