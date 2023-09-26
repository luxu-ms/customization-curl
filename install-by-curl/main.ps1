param (
    [Parameter()]
    [string]$SourceURL,
    [Parameter()]
    [string]$Package,
    [Parameter()]
    [string]$Version,
    [Parameter()]
    [string]$DestinationDirectory,
    [Parameter()]
    [string]$PostInstallFile,
    [Parameter()]
    [string]$PostInstallArguments
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

if($SourceURL -ne "" -and $Package -ne "" -and $Version -ne "" -and $DestinationDirectory -ne "") {
    $SourceURL = $SourceURL.TrimEnd('/')
    $packageFileURL = "$SourceURL/$Package/$Package-$Version.zip"
    Write-Host "packageFileURL:$packageFileURL"

    if(!(Test-Path $DestinationDirectory)) {
        New-Item $DestinationDirectory -ItemType Directory
    }

    if(!(${env:REPO-GET-SECRET})){
        curl -O --output-dir $DestinationDirectory $packageFileURL
    }else{
        $credential=[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(${env:REPO-GET-SECRET}))
        curl -O -u $credential --output-dir $DestinationDirectory $packageFileURL
    }
    

    $zipFile = Join-Path $DestinationDirectory "$Package-$Version.zip"

    if(Test-Path $zipfile){
        $packageFolder = "$DestinationDirectory/$Package-$Version" 
        if(Test-Path $packageFolder) {
            Remove-Item $packageFolder -Force -Recurse
        }

        Unzip $zipFile $packageFolder

        Set-Location $DestinationDirectory
        if($PostInstallFile -ne "") {
            $installerPath = Join-Path $packageFolder $PostInstallFile
            Write-Host "Executing installerPath: $installerPath"
            Start-Process -FilePath $installerPath -ArgumentList $PostInstallArguments -NoNewWindow -Wait -PassThru
            Write-Host "Completed installing $Package"
        }
    }else{
        Write-Host "Cannot download the zip file: $packageFileURL to $zipFile"
    }

    
} else {
    Write-Host "SourceURL, Package, Version and DestinationDirectory are not expected. SourceURL: $SourceURL, Package: $Package, Version: $Version, DestinationDirectory: $DestinationDirectory"
}
