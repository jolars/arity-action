Param()

$ErrorActionPreference = 'Stop'

$repo = if ($env:ARITY_REPO) { $env:ARITY_REPO } else { 'jolars/arity' }
$version = if ($env:ARITY_VERSION) { $env:ARITY_VERSION } else { 'latest' }
$installDir = if ($env:ARITY_INSTALL_DIR) { $env:ARITY_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'Programs\arity\bin' }
$verify = if ($env:ARITY_VERIFY_CHECKSUM) { $env:ARITY_VERIFY_CHECKSUM } else { 'true' }

$arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
switch ($arch) {
    'X64' { $target = 'x86_64-pc-windows-msvc' }
    'Arm64' { $target = 'aarch64-pc-windows-msvc' }
    default { throw "Unsupported Windows architecture: $arch" }
}

$asset = "arity-$target.zip"

if ($version -eq 'latest') {
    $base = "https://github.com/$repo/releases/latest/download"
} else {
    $tag = if ($version.StartsWith('v')) { $version } else { "v$version" }
    $base = "https://github.com/$repo/releases/download/$tag"
}
$url = "$base/$asset"

$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("arity-install-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpDir | Out-Null

try {
    $zipPath = Join-Path $tmpDir $asset
    Write-Host "Downloading $asset ($version)..."
    Invoke-WebRequest -Uri $url -OutFile $zipPath

    if ($verify -eq 'true') {
        # Fetch the published checksum sidecar. Older releases may not have one,
        # in which case we warn and continue rather than fail.
        $shaPath = "$zipPath.sha256"
        $haveChecksum = $true
        try {
            Invoke-WebRequest -Uri "$url.sha256" -OutFile $shaPath
        } catch {
            $haveChecksum = $false
            Write-Warning "No published checksum for $asset; skipping verification."
        }
        if ($haveChecksum) {
            $expected = ((Get-Content -Raw $shaPath).Trim() -split '\s+')[0].ToLower()
            $actual = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLower()
            if ($expected -ne $actual) {
                throw "Checksum mismatch for ${asset}: expected $expected, actual $actual"
            }
            Write-Host "Checksum verified."
        }
    }

    Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Copy-Item -Path (Join-Path $tmpDir 'arity.exe') -Destination (Join-Path $installDir 'arity.exe') -Force

    Write-Host "Installed arity to $(Join-Path $installDir 'arity.exe')"
}
finally {
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
}
