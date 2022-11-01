
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


<#
    .Synopsis
        Convert a compressed script in BASE64 string value back in CLEAR
    .Description
        Convert a compressed script in BASE64 string value back in CLEAR
    .Parameter ScriptBlock
        The ScriptBlock to convert
    .Inputs
        ScriptBlock
    .Outputs
        ScriptBlock
#>



function Remove-CommentsFromScriptBlock {

    [CmdletBinding()] 
    param(
        [String]$ScriptBlock
    )
    $IsOneLineComment = $False
    $IsComment = $False
    $Output = ""
    $NoCommentException = $False

    $Arr=$ScriptBlock.Split("`n")
    ForEach ($Line in $Arr) 
    {
        if ($Line -match "###NCX") { ###NCX
            $NoCommentException = $True
        }

        if ($Line -like "*<#*") {   ###NCX
            $IsComment = $True
        }

        if ($Line -like "#*") {     ###NCX
            $IsOneLineComment = $True
        }

        if($NoCommentException){
            $Output += "$Line`n"
        }
        elseif (-not $IsComment -And -not $IsOneLineComment) {
            $Output += "$Line`n"
        }

        $IsOneLineComment = $False

        if ($Line -like "*#>*") {   ###NCX
            $IsComment = $False
        }
    }

    return $Output
}

function Add-LoaderBlock{

 [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The Path argument must be a file. Directory paths are not allowed."
            }
            return $true 
        })]        
        [Alias('p')]
        [string]$Path
    )


    $LoaderBlock = @"
# ------------------------------------`
# Loader
# ------------------------------------
function ConvertFrom-Base64CompressedScriptBlock {

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=`$true, ValueFromPipeline=`$true, HelpMessage=`"ScriptBlock`", Position=0)]
        [string]`$ScriptBlock
    )

    #Write-Verbose `"==============================================================`"
    #Write-Verbose `"ConvertFrom-Base64CompressedScriptBlock `$ScriptBlock...`"
    #Write-Verbose `"==============================================================`"
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

foreach (`$h in `$ScriptsArray.GetEnumerator()) {
    try{
        `$ScriptBlock = `$(`$h.Value)
        `$SName = `$(`$h.Name)
        Write-Verbose `"Converting `$SName...`"
        `$ClearScript = ConvertFrom-Base64CompressedScriptBlock -ScriptBlock `$ScriptBlock
        Write-Verbose `"Running `$SName...`"
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

    Add-Content -Path $Path -Value "`n`n$LoaderBlock`n" -Force
}

function Convert-ScriptToString {

    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The Path argument must be a file. Directory paths are not allowed."
            }
            return $true 
        })]        
        [Alias('i')]
        [string]$InputScript,
        [Parameter(Mandatory=$false)]
        [Alias('o')]
        [string]$OutputScript,
        [Parameter(Mandatory=$false)]
        [Alias('r')]
        [switch]$Raw,
        [Parameter(Mandatory=$false)]
        [Alias('f')]
        [switch]$Force
    )

    try{
        $FileBaseName = (gi $InputScript).Basename
        $Content = Get-Content -Path $InputScript -Raw
         # Strip out comments
        $ScriptBlock = Remove-CommentsFromScriptBlock -ScriptBlock $Content
        
        $CompressedContent = Convert-ToBase64CompressedScriptBlock $ScriptBlock
        if($Raw){
            return $CompressedContent
        }
        $StringDecl = "`$$FileBaseName = `"$CompressedContent`""
        if($PSBoundParameters.ContainsKey("OutputScript")){
            if($Force){
                $Null = New-Item -Path "$OutputScript" -ItemType File -Force -ErrorAction Ignore
                $Null = Remove-Item -Path "$OutputScript" -Force -ErrorAction Ignore
            }
            if(Test-Path $OutputScript) { 
                write-host "[Warning] " -f DarkRed -NoNewLine ; 
                write-host "File $OutputScript already exists... " -f DarkYellow -n
                $a=Read-Host -Prompt "Overwrite (y/N)?" ; 
                if($a -notmatch "y") {
                    return;
                }
                 
            }
            Set-Content -Path $OutputScript -Value "`n`n$StringDecl`n" -Force
            return $OutputScript
        }else{
            return $StringDecl
        }
    }catch{
        Show-ExceptionDetails($_) -ShowStack
    }
}


function Convert-ScriptDirectoryToString {

    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Container) ){
                throw "The Path argument must be a Directory. File paths are not allowed."
            }
            return $true 
        })]        
        [Alias('p')]
        [string]$Path,
        [Parameter(Mandatory=$false)]
        [Alias('o')]
        [string]$OutputScript,
        [Parameter(Mandatory=$false)]
        [Alias('f')]
        [switch]$Force
    )

    try{

        if($Force){
            $Null = New-Item -Path "$OutputScript" -ItemType File -Force -ErrorAction Ignore
            $Null = Remove-Item -Path "$OutputScript" -Force -ErrorAction Ignore
        }
        if(Test-Path $OutputScript) { 
            write-host "[Warning] " -f DarkRed -NoNewLine ; 
            write-host "File $OutputScript already exists... " -f DarkYellow -n
            $a=Read-Host -Prompt "Overwrite (y/N)?" ; 
            if($a -notmatch "y") {
                 return;
            }  
        }
        $Null = New-Item -Path "$OutputScript" -ItemType File -Force -ErrorAction Ignore

        $Header = @'
[CmdletBinding(SupportsShouldProcess)]
Param()

$ScriptsArray=@{}

'@

        Set-Content -Path $OutputScript -Value $Header -Force
        ForEach($script in (gci $Path -File -Filter '*.ps1')){
            $fname = $script.fullname
            $base = $script.basename
            $str = Convert-ScriptToString -i "$fname"
            Add-Content -Path $OutputScript -Value "# $base script" -Force
            Add-Content -Path $OutputScript -Value "$str" -Force
            Add-Content -Path $OutputScript -Value "`$ScriptsArray.Add(`"$base`",`$$base)`n" -Force
        
        }
        
        Add-LoaderBlock -Path $OutputScript
    }catch{
        Show-ExceptionDetails($_) -ShowStack
    }
    $OutputScript
}


function Convert-ToBase64CompressedScriptBlock {

    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory=$true,Position=0)]
        $ScriptBlock
    )

    # Script block as String to Byte array
    [System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8
    [Byte[]] $ScriptBlockEncoded = $Encoding.GetBytes($ScriptBlock)

    # Compress Byte array (gzip)
    [System.IO.MemoryStream] $MemoryStream = New-Object System.IO.MemoryStream
    $GzipStream = New-Object System.IO.Compression.GzipStream $MemoryStream, ([System.IO.Compression.CompressionMode]::Compress)
    $GzipStream.Write($ScriptBlockEncoded, 0, $ScriptBlockEncoded.Length)
    $GzipStream.Close()
    $MemoryStream.Close()
    $ScriptBlockCompressed = $MemoryStream.ToArray()

    # Byte array to Base64
    [System.Convert]::ToBase64String($ScriptBlockCompressed)
}

function Convert-FromBase64CompressedScriptBlock {

    [CmdletBinding()] param(
        [String]
        $ScriptBlock
    )

    # Base64 to Byte array of compressed data
    $ScriptBlockCompressed = [System.Convert]::FromBase64String($ScriptBlock)

    # Decompress data
    $InputStream = New-Object System.IO.MemoryStream(, $ScriptBlockCompressed)
    $MemoryStream = New-Object System.IO.MemoryStream
    $GzipStream = New-Object System.IO.Compression.GzipStream $InputStream, ([System.IO.Compression.CompressionMode]::Decompress)
    $GzipStream.CopyTo($MemoryStream)
    $GzipStream.Close()
    $MemoryStream.Close()
    $InputStream.Close()
    [Byte[]] $ScriptBlockEncoded = $MemoryStream.ToArray()

    # Byte array to String
    [System.Text.Encoding] $Encoding = [System.Text.Encoding]::UTF8
    $Encoding.GetString($ScriptBlockEncoded) | Out-String
}
