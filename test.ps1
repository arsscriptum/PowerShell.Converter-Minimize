#=================================================
# Generated on Tue, 01 Nov 2022 02:32:01 GMT
#=================================================

# ------------------------------------
# Script file - app_categories - 
# ------------------------------------
$ScriptBlockapp_categories = "H4sIAAAAAAAACrVT74vTQBD9Xuj/sPQCSaE9DhE/CAXP4qngncWifjiOsE0m6drNzjq7aa5o/3cnTWvTHwcimlLC7rz35r3Jbrcjup36l5Um8QqNeAt+eG3tWHrIkRS4H92O4Od+XKQa/GtlUmXyaFpai+TddI6lTieECTjXf2iwVpIson6zCPZSYiReRaEBXyEtYo+o3eXcFzrcQi8GYYKFLT1QnCGBcSqJHWa+kgQNchA+vngep1gZjTKNrUwWMt/VGhVOtHld8D/E0mvERYxZphI4EbOEOXstuGHLziCsYBbPCCt3VNhK19qhWzkPxSHPSuc4XBoTJLgEWp1JeYP0RibzKEikF8q0B9TfDnszN0uw5MHmxJOdEGTAA0mAZxjkGmdSvzwttthPYlggnCoNxuvVGI1XpoSwRfwKs0/gLBpXQ9+bJS5guNn8XoLzjPhMuj4yf9TqiRQNu6Ux9dKXbozphtTycLmv7OEqi9qMoQHx7OqqPb368XP+gqLHEaRWqaBtANqla2v0e3vu+iDdB2UW7thUs/lTTEFD4sWcgx1TmvWaQ67/3wXbiJ8o7vy3ut5BVWO04kPH64+zb+z7rzvvs95P6g3gGxvdSpNKj7QaBZnUDgbii9Ql3BAWE2VBKwOjwFPJhXeg7S2r8tUd9e6Y39vpbzSvtZIu6pnDXeeJ7T0ENf73RfwnDvhAnzVQnjfA8G3/3Rfo/AJqtKRwSAUAAA=="



# ------------------------------------
# Loader
# ------------------------------------
function ConvertFrom-Base64CompressedScriptBlock {

    [CmdletBinding()] param(
        [String]
        $ScriptBlock
    )

    # Take my B64 string and do a Base64 to Byte array conversion of compressed data
    $ScriptBlockCompressed = [System.Convert]::FromBase64String($ScriptBlock)

    # Then decompress script's data
    $InputStream = New-Object System.IO.MemoryStream(, $ScriptBlockCompressed)
    $GzipStream = New-Object System.IO.Compression.GzipStream $InputStream, ([System.IO.Compression.CompressionMode]::Decompress)
    $StreamReader = New-Object System.IO.StreamReader($GzipStream)
    $ScriptBlockDecompressed = $StreamReader.ReadToEnd()
    # And close the streams
    $GzipStream.Close()
    $InputStream.Close()

    $ScriptBlockDecompressed
}

# For each scripts in the module, decompress and load it.
# Set a flag in the Script Scope so that the scripts know we are loading a module
# so he can have a specific logic
$Script:LoadingState = $True
$ScriptList = @('app_categories')
$ScriptList | ForEach-Object {
    $ScriptId = $_
     $ScriptBlock = "`$ScriptBlock$($ScriptId)" | Invoke-Expression
    $ClearScript = ConvertFrom-Base64CompressedScriptBlock -ScriptBlock $ScriptBlock
    try{
        $ClearScript | Invoke-Expression
    }catch{
        Write-Host "===============================" -f DarkGray
        Write-Host "$ClearScript" -f DarkGray
        Write-Host "===============================" -f DarkGray
        Write-Error "ERROR IN script $ScriptId . Details $_"
    }
}
$Script:LoadingState = $False



