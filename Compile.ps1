dependencies\<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍   
#̷𝓍   PowerShell.ModuleBuilder
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/
#>



[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true,Position=0, ValueFromPipeline=$true, 
        HelpMessage="Path of the files to compile") ]
    [String]$Path,
    [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true, 
        HelpMessage="Out file") ]
    [String]$OutFile
    )


#Requires -Version 5


function Get-Script([string]$prop){
    $ThisFile = $script:MyInvocation.MyCommand.Path
    return ((Get-Item $ThisFile)|select $prop).$prop
}

$ScriptPath = split-path $script:MyInvocation.MyCommand.Path
$ScriptFullName =(Get-Item -Path $script:MyInvocation.MyCommand.Path).DirectoryName

#===============================================================================
# Root Path
#===============================================================================
$Global:ConsoleOutEnabled              = $true
$Global:CurrentRunningScript           = Get-Script basename
$Script:CurrPath                       = $ScriptPath
$Script:RootPath                       = (Get-Location).Path
If( $PSBoundParameters.ContainsKey('Path') -eq $True ){
    $Script:RootPath = $Path
}

$Script:Time                           = Get-Date
$Script:Date                           = $Time.GetDateTimeFormats()[19]
$Script:ScriptList                     = New-Object System.Collections.ArrayList
$Script:FileHeader                     = "#=================================================`n# Generated on $Script:Date`n#================================================="
$Script:Psm1Content                    = "$Script:FileHeader`n`n"

$Script:Converter                     = Join-Path $Script:CurrPath "dependencies\Converter.ps1"
 
Write-Host "`n`n===============================================================================" -f DarkRed
Write-Host "COMPILING SCRIPT FILE" -f DarkYellow;
Write-Host "===============================================================================" -f DarkRed

. "$Script:Converter"

$Script:CompilationErrorsCount = 0


Get-ChildItem -Path "$Path" -File -Filter '*.ps1' -Recurse | ForEach-Object {
    $Path = $_.fullname
    $Filename = $_.Name
    $Basename = (Get-Item -Path $Path).Basename
    $ScriptName = $Basename
    try {

        [void] $ScriptList.Add($Basename)
        Write-Host "COMPILING SCRIPT FILE $Basename" -f DarkYellow;
        # Read script block from module file
        [string]$ScriptBlock = Get-Content -Path $Path -Raw

        # Strip out comments
        $ScriptBlock = Remove-CommentsFromScriptBlock -ScriptBlock $ScriptBlock

        # Compress and Base64 encode script block
        $ScriptBlockBase64 = Convert-ToBase64CompressedScriptBlock -ScriptBlock $ScriptBlock

        $Psm1Content += "# ------------------------------------`n"
        $Psm1Content += "# Script file - $ScriptName - `n"
        $Psm1Content += "# ------------------------------------`n"
        $Psm1Content += "`$ScriptBlock$($ScriptName) = `"$($ScriptBlockBase64)`"`n`n"
    }catch { 
        Show-ExceptionDetails($_) -ShowStack
        $Script:CompilationErrorsCount += 1
    }
}

$LoaderBlock = ''
if ($Script:DebugMode -ne $True) {
    $LoaderBlock = @"
# ------------------------------------`
# Loader
# ------------------------------------
function ConvertFrom-Base64CompressedScriptBlock {

    [CmdletBinding()] param(
        [String]
        `$ScriptBlock
    )

    # Take my B64 string and do a Base64 to Byte array conversion of compressed data
    `$ScriptBlockCompressed = [System.Convert]::FromBase64String(`$ScriptBlock)

    # Then decompress script's data
    `$InputStream = New-Object System.IO.MemoryStream(, `$ScriptBlockCompressed)
    `$GzipStream = New-Object System.IO.Compression.GzipStream `$InputStream, ([System.IO.Compression.CompressionMode]::Decompress)
    `$StreamReader = New-Object System.IO.StreamReader(`$GzipStream)
    `$ScriptBlockDecompressed = `$StreamReader.ReadToEnd()
    # And close the streams
    `$GzipStream.Close()
    `$InputStream.Close()

    `$ScriptBlockDecompressed
}

# For each scripts in the module, decompress and load it.
# Set a flag in the Script Scope so that the scripts know we are loading a module
# so he can have a specific logic
`$Script:LoadingState = `$True
`$ScriptList = @($( ($ScriptList | ForEach-Object { "'$_'" }) -join ','))
`$ScriptList | ForEach-Object {
    `$ScriptId = `$_
     `$ScriptBlock = `"```$ScriptBlock`$(`$ScriptId)`" | Invoke-Expression
    `$ClearScript = ConvertFrom-Base64CompressedScriptBlock -ScriptBlock `$ScriptBlock
    try{
        `$ClearScript | Invoke-Expression
    }catch{
        Write-Host `"===============================`" -f DarkGray
        Write-Host `"`$ClearScript`" -f DarkGray
        Write-Host `"===============================`" -f DarkGray
        Write-Error `"ERROR IN script `$ScriptId . Details `$_`"
    }
}
`$Script:LoadingState = `$False

"@

}

$Psm1Content += "`n`n$($LoaderBlock)`n`n"

Set-Content "$OutFile" -Value $Psm1Content 