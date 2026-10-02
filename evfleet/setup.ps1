# EVFleet exam_2_103 - setup script (Windows PowerShell)
$ErrorActionPreference = 'Stop'
$proj = 'exam_2_103'
$root = $PSScriptRoot
Set-Location $root

function Read-Text($p)  { [System.IO.File]::ReadAllText($p) }
function Write-Text($p, $t) { [System.IO.File]::WriteAllText($p, $t) }

# 1) flutter create
if (-not (Test-Path (Join-Path $root $proj))) {
    flutter create $proj --org com.example --platforms android
}
$app = Join-Path $root $proj

# 2) copy lib/ + pubspec.yaml
if (Test-Path "$app\lib") { Remove-Item "$app\lib" -Recurse -Force }
Copy-Item "$root\lib" "$app\lib" -Recurse
Copy-Item "$root\pubspec.yaml" "$app\pubspec.yaml" -Force
if (Test-Path "$app\test") { Remove-Item "$app\test" -Recurse -Force }   # widget_test เดิมอ้าง MyApp

# 3) Gradle
$settings = "$app\android\settings.gradle.kts"
$t = Read-Text $settings
if ($t -notmatch 'google-services') {
    $t = $t -replace '(id\("org\.jetbrains\.kotlin\.android"\)[^\r\n]*)', ('$1' + "`r`n    " + 'id("com.google.gms.google-services") version "4.4.2" apply false')
    Write-Text $settings $t
}
$build = "$app\android\app\build.gradle.kts"
$t = Read-Text $build
if ($t -notmatch 'google-services') {
    $t = $t -replace '(id\("com\.android\.application"\)[^\r\n]*)', ('$1' + "`r`n    " + 'id("com.google.gms.google-services")')
}
$t = $t -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23'
Write-Text $build $t

# 4) App name
$manifest = "$app\android\app\src\main\AndroidManifest.xml"
$t = Read-Text $manifest
$t = $t -replace 'android:label="[^"]*"', 'android:label="EVFleet"'
Write-Text $manifest $t

# 5) Icon (สร้างไอคอนสายชาร์จ/แบตเตอรี่อัตโนมัติถ้ายังไม่มี assets/icon.png)
New-Item -ItemType Directory -Force "$app\assets" | Out-Null
$icon = "$app\assets\icon.png"
if (Test-Path "$root\assets\icon.png") { Copy-Item "$root\assets\icon.png" $icon -Force }
if (-not (Test-Path $icon)) {
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap 1024, 1024
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.Clear([System.Drawing.Color]::FromArgb(22, 163, 74))
    $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $dark  = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(22, 163, 74))
    $g.FillRectangle($white, 232, 312, 520, 400)      # ตัวแบตเตอรี่
    $g.FillRectangle($white, 752, 442, 70, 140)       # ขั้วแบตเตอรี่
    function P($x, $y) { New-Object System.Drawing.Point $x, $y }
    $bolt = [System.Drawing.Point[]]@((P 520 340), (P 380 540), (P 470 540), (P 430 690), (P 610 470), (P 515 470))
    $g.FillPolygon($dark, $bolt)
    $bmp.Save($icon, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

# 6) pub get + launcher icons
Set-Location $app
flutter pub get
dart run flutter_launcher_icons

Write-Host ""
Write-Host "เสร็จแล้ว! ขั้นต่อไป:" -ForegroundColor Green
Write-Host " 1) Firebase Console: สร้างโปรเจกต์ exam-2-103 (Auth Email/Password + Firestore Test Mode)"
Write-Host " 2) เพิ่ม Android app package: com.example.exam_2_103"
Write-Host " 3) วาง google-services.json ที่ $app\android\app\"
Write-Host " 4) cd $proj ; flutter run ; กด 'สร้างบัญชีทดสอบ' 1 ครั้ง"
