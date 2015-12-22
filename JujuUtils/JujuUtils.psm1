# Copyright 2014-2015 Cloudbase Solutions Srl
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

function Convert-FileToBase64{
    <#
    .SYNOPSIS
    This powershell commandlet converts an entire file, byte by byte to base64 and returns the string.

    WARNING: Do not use this to convert large files, as it reads the entire contents of a file
    into memory. This function may be useful to transfer small amounts of data over a relation
    without having to worry about encoding or escaping, preserving at the same time any
    binary info/special
    characters.
    .PARAMETER File
    The path to the file you want to convert. It works for any type of file. Take great care not to
    try and convert large files.
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true)]
        [string]$File
    )
    PROCESS {
        if(!(Test-Path $File)) {
            Throw "No such file: $File"
        }
        $ct = [System.IO.File]::ReadAllBytes($File)
        $b64 = [Convert]::ToBase64String($ct)
        return $b64
    }
}

function Write-FileFromBase64 {
    <#
    .SYNOPSIS
    Helper function that converts base64 to bytes and then writes that stream to a file.
    .PARAMETER File
    Destination file to write to.
    .PARAMETER Content
    Base64 encoded string
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$File,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Content
    )
    PROCESS {
        $bytes = [Convert]::FromBase64String($Content)
        [System.IO.File]::WriteAllBytes($File, $bytes)
    }
}

function ConvertTo-Base64 {
    <#
    .SYNOPSIS
    Convert string to its base64 representation
    .PARAMETER Content
    String to be converted to base64
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Content
    )
    PROCESS {
        $x = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Content))
        return $x
    }
}

function ConvertFrom-Base64 {
    <#
    .SYNOPSIS
    Convert base64 back to string
    .PARAMETER Content
    Base64 encoded string
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Content
    )
    PROCESS {
        $x = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($content))
        return $x
    }
}

function Get-EncryptedString {
    <#
    .SYNOPSIS
    This is just a helper function that converts a plain string to a secure string and returns the encrypted
    string representation.
    .PARAMETER Content
    The string you want to encrypt
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Content
    )
    PROCESS {
        $ret = ConvertTo-SecureString -AsPlainText -Force $Content | ConvertFrom-SecureString
        return $ret
    }
}

function Get-DecryptedString {
    <#
    .SYNOPSIS
    Decrypt a securestring back to its plain text representation.
    .PARAMETER Content
    The encrypted content to decrypt.
    .NOTES
    This function is only meant to be used with encrypted strings, not binary.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Content
    )
    PROCESS {
        $c = ConvertTo-SecureString $Content
        $dec = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($c)
        $ret = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($dec)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($dec)
        return $ret
    }
}

function Get-UserPath {
    <#
    .SYNOPSIS
    Returns the $env:PATH variable for the current user.
    #>
    [CmdletBinding()]
    PROCESS {
        return [System.Environment]::GetEnvironmentVariable("PATH", "User")
    }
}

function Get-SystemPath {
    <#
    .SYNOPSIS
    Returns the system wide default $env:PATH.
    #>
    [CmdletBinding()]
    PROCESS {
        return [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    }
}

function Compare-ScriptBlocks {
    <#
    .SYNOPSIS
    Compare two script blocks
    .PARAMETER ScriptBlock1
    First script block
    .PARAMETER ScriptBlock2
    Second script block
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("scrBlock1")]
        [System.Management.Automation.ScriptBlock]$ScriptBlock1,
        [Parameter(Mandatory=$true)]
        [Alias("scrBlock2")]
        [System.Management.Automation.ScriptBlock]$ScriptBlock2
    )
    PROCESS {
        $sb1 = $ScriptBlock1.ToString()
        $sb2 = $ScriptBlock2.ToString()
        return ($sb1.CompareTo($sb2) -eq 0)
    }
}

function Compare-Arrays {
    <#
    .SYNOPSIS
    Compare two arrays. Returns a boolean value that determines whether or not the arrays are equal.
    .PARAMETER Array1
    First array to compare
    .PARAMETER Array2
    Second array to compare
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("arr1")]
        [array]$Array1,
        [Parameter(Mandatory=$true)]
        [Alias("arr2")]
        [array]$Array2
    )
    PROCESS {
        return (((Compare-Object $Array1 $Array2).InputObject).Length -eq 0)
    }
}

function Compare-HashTables {
    <#
    .SYNOPSIS
    Compare two arrays. Returns a boolean value that determines whether or not the arrays are equal.
    .PARAMETER Array1
    First array to compare
    .PARAMETER Array2
    Second array to compare
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("tab1")]
        [HashTable]$HashTable1,
        [Parameter(Mandatory=$true)]
        [Alias("tab2")]
        [HashTable]$HashTable2
    )
    PROCESS {
        if ($HashTable1.Count -ne $HashTable2.Count) {
            return $false
        }
        foreach ($i in $HashTable1.Keys) {
            if (($HashTable2.ContainsKey($i) -eq $false) -or ($HashTable1[$i] -ne $HashTable2[$i])) {
                return $false
            }
        }
        return $true
    }
}

function Start-ExternalCommand {
    <#
    .SYNOPSIS
    Helper function to execute a script block and throw an exception in case of error.
    .PARAMETER ScriptBlock
    Script block to execute
    .PARAMETER ArgumentList
    A list of parameters to pass to Invoke-Command
    .PARAMETER ErrorMessage
    Optional error message. This will become part of the exception message we throw in case of an error.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Command")]
        [ScriptBlock]$ScriptBlock,
        [array]$ArgumentList=@(),
        [string]$ErrorMessage
    )
    PROCESS {
        $res = Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
        if ($LASTEXITCODE -ne 0) {
            if(!$ErrorMessage){
                Throw ("Command exited with status: {0}" -f $LASTEXITCODE)
            }
            throw (("{0} (Exit code: $LASTEXITCODE)" -f $ErrorMessage)
        }
        return $res
    }
}

function Write-HookTracebackToLog {
    <#
    .SYNOPSIS
    A helper function that accepts an ErrorRecord and writes a full call stack trace of that error to the juju log. This function
    works best when used in a try/catch block. You get a chance to log the error with proper log level before you re-throw it, or
    exit the hook. 
    .PARAMETER ErrorRecord
    The error record to log.
    .PARAMETER LogLevel
    Optional log level to use. Defaults to ERROR.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [string]$LogLevel="ERROR"
    )
    PROCESS {
        $name = $MyInvocation.PSCommandPath
        Write-JujuLog "Error while running $name" -LogLevel $LogLevel
        $info = Get-CallStack $ErrorRecord
        foreach ($i in $info){
            Write-JujuLog $i -LogLevel $LogLevel
        }
    }
}

function Get-CallStack {
    <#
    .SYNOPSIS
    Returns an array of three elements, containing: Error message, error position, and stack trace.
    .PARAMETER ErrorRecord
    The error record to extract details from.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    PROCESS {
        $message = $ErrorRecord.Exception.Message
        $position = $ErrorRecord.InvocationInfo.PositionMessage
        $trace = $ErrorRecord.ScriptStackTrace
        $info = @($message, $position, $trace)
        return $info
    }
}

function Start-ExecuteWithRetry {
    <#
    .SYNOPSIS
    In some cases a command may fail several times before it succeeds, be it because of network outage, or a service
    not being ready yet, etc. This is a helper function to allow you to execute a function or binary a number of times
    before actually failing.

    Its important to note, that any powershell commandlet or native command can be executed using this function. The result
    of that command or powershell commandlet will be returned by this function.

    Only the last exception will be thrown, and will be logged with a log level of ERROR.
    .PARAMETER ScriptBlock
    The script block to run.
    .PARAMETER MaxRetryCount
    The number of retries before we throw an exception.
    .PARAMETER RetryInterval
    Number of seconds to sleep between retries.
    .PARAMETER ArgumentList
    Arguments to pass to your wrapped commandlet/command.

    .EXAMPLE
    # If the computer just booted after the machine just joined the domain, and your charm starts running,
    # it may error out until the security policy has been fully applied. In the bellow example we retry 10
    # times and wait 10 seconds between retries before we give up. If successful, $ret will contain the result
    # of Get-ADUser. If it does not, an exception is thrown. 
    $ret = Start-ExecuteWithRetry -ScriptBlock {
        Get-ADUser testuser
    } -MaxRetryCount 10 -RetryInterval 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Command")]
        [ScriptBlock]$ScriptBlock,
        [int]$MaxRetryCount=10,
        [int]$RetryInterval=3,
        [array]$ArgumentList=@()
    )
    PROCESS {
        $currentErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"

        $retryCount = 0
        while ($true) {
            try {
                $res = Invoke-Command -ScriptBlock $ScriptBlock `
                         -ArgumentList $ArgumentList
                $ErrorActionPreference = $currentErrorActionPreference
                return $res
            } catch [System.Exception] {
                $retryCount++
                if ($retryCount -gt $MaxRetryCount) {
                    $ErrorActionPreference = $currentErrorActionPreference
                    throw
                } else {
                    Write-HookTracebackToLog $_ -LogLevel WARNING
                    Start-Sleep $RetryInterval
                }
            }
        }
    }
}

function Test-FileIntegrity {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [string]$File,
        [Parameter(Mandatory=$true)]
        [string]$ExpectedHash,
        [Parameter(Mandatory=$false)]
        [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MACTripleDES", "MD5", "RIPEMD160")]
        [string]$Algorithm="SHA1"
    )
    PROCESS {
        $hash = (Get-FileHash -Path $File -Algorithm $Algorithm).Hash
        if ($hash -ne $ExpectedHash) {
            throw ("File integrity check failed for {0}. Expected {1}, got {2}" -f @($File, $ExpectedHash, $hash))
        }
    }
}

function Invoke-FastWebRequest {
    <#
    .SYNOPSIS
    Invoke-FastWebRequest downloads a file form the web via HTTP. This function will work on all modern windows versions,
    including Windows Server Nano. This function also allows file integrity checks using common hashing algorithms:

    "SHA1", "SHA256", "SHA384", "SHA512", "MACTripleDES", "MD5", "RIPEMD160"

    The hash of the file being downloaded should be specified in the Uri itself. See examples.
    .PARAMETER Uri
    The address from where to fetch the file
    .PARAMETER OutFile
    Destination file
    .PARAMETER SkipIntegrityCheck
    Skip file integrity check even if a valid hash is specified in the Uri.

    .EXAMPLE

    # Download file without file integrity check
    Invoke-FastWebRequest -Uri http://example.com/archive.zip -OutFile (Join-Path $env:TMP archive.zip)

    .EXAMPLE
    # Download file with file integrity check
    Invoke-FastWebRequest -Uri http://example.com/archive.zip#md5=43d89a2f6b8a8918ce3eb76227685276 `
                          -OutFile (Join-Path $env:TMP archive.zip)

    .EXAMPLE
    # Force skip file integrity check
    Invoke-FastWebRequest -Uri http://example.com/archive.zip#md5=43d89a2f6b8a8918ce3eb76227685276 `
                          -OutFile (Join-Path $env:TMP archive.zip) -SkipIntegrityCheck:$true
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,Position=0)]
        [System.Uri]$Uri,
        [Parameter(Position=1)]
        [string]$OutFile,
        [switch]$SkipIntegrityCheck=$false
    )
    PROCESS
    {
        if(!([System.Management.Automation.PSTypeName]'System.Net.Http.HttpClient').Type)
        {
            $assembly = [System.Reflection.Assembly]::LoadWithPartialName("System.Net.Http")
        }

        [Environment]::CurrentDirectory = (pwd).Path

        if(!$OutFile) {
            $OutFile = $Uri.PathAndQuery.Substring($Uri.PathAndQuery.LastIndexOf("/") + 1)
            if(!$OutFile) {
                throw "The ""OutFile"" parameter needs to be specified"
            }
        }

        $client = new-object System.Net.Http.HttpClient
        $task = $client.GetAsync($Uri)
        $task.wait()
        $response = $task.Result
        $status = $response.EnsureSuccessStatusCode()

        $outStream = New-Object IO.FileStream $OutFile, Create, Write, None

        try {
            $task = $response.Content.ReadAsStreamAsync()
            $task.Wait()
            $inStream = $task.Result

            $contentLength = $response.Content.Headers.ContentLength

            $totRead = 0
            $buffer = New-Object Byte[] 1MB
            while (($read = $inStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $totRead += $read
                $outStream.Write($buffer, 0, $read);

                if($contentLength){
                    $percComplete = $totRead * 100 / $contentLength
                    Write-Progress -Activity "Downloading: $Uri" -PercentComplete $percComplete
                }
            }

            if(!$SkipIntegrityCheck) {
                $fragment = $Uri.Fragment.Trim('#')
                if (!$fragment){
                    return
                }
                $details = $fragment.Split("=")
                $algorithm = $details[0]
                $hash = $details[1]
                if($algorithm -in @("SHA1", "SHA256", "SHA384", "SHA512", "MACTripleDES", "MD5", "RIPEMD160")){
                    Test-FileIntegrity -File $OutFile -Algorithm $algorithm -ExpectedHash $hash
                } else {
                    Write-JujuWarning "Hash algorithm $algorithm not recognized. Skipping file integrity check."
                }
            }
        }
        finally {
            $outStream.Close()
        }
    }
}

function Expand-ZipArchive {
    <#
    .SYNOPSIS
    Helper function to unzip a file. This function should work on all modern windows versions, including Windows Server Nano.
    .PARAMETER ZipFile
    The path to the zip archive
    .PARAMETER Destination
    The destination folder into which to unarchive the zipfile.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ZipFile,
        [Parameter(Mandatory=$true)]
        [string]$Destination
    )
    PROCESS {
        try {
            # This will work on Windows 10/Windows Server 2016.
            Expand-Archive -Path $ZipFile -DestinationPath $Destination
        } catch [System.Management.Automation.CommandNotFoundException] {
            try {
                # Try without loading system.io.compression.filesystem. This will work by default on Nano
                [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $Destination)
            }catch [System.Management.Automation.RuntimeException] {
                # Load system.io.compression.filesystem. This will work on the full version of Windows Server
                Add-Type -assembly "system.io.compression.filesystem"
                [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $Destination)
            }
        }
    }
}

function Get-SanePath {
    <#
    .SYNOPSIS
    There are some situations in which the $env:PATH variable may contain duplicate paths. This function returns
    a sanitized $env:PATH without any duplicates.
    #>
    [CmdletBinding()]
    PROCESS {
        $path = $env:PATH
        $arrayPath = $path.Split(';')
        $arrayPath = $arrayPath | Select-Object -Unique
        $newPath = $arrayPath -join ';'
        return $newPath
    }
}

function Add-ToUserPath {
    <#
    .SYNOPSIS
    Permanently add an additional path to $env:PATH for current user, and also set the current $env:PATH to the new value.
    .PARAMETER Path
    Extra path to add to $env:PATH
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    PROCESS {
        $currentPath = Get-SanePath
        if ($Path -in $env:Path.Split(';')){
            return
        }
        $newPath = "$currentPath;$Path"
        Start-ExternalCommand -Command {
            setx PATH $newPath
        } -ErrorMessage "Failed to set user path"
        $env:PATH = $newPath
    }
}

function Get-MarshaledObject {
    <#
    .SYNOPSIS
    Get a base64 encoded representation of a json encoded powershell object. "Why?" you might ask. Well, in some cases you
    may need to send more complex information through a relation to another charm. This function allows you to send simple
    powershell objects (hashtables, arrays, etc) as base64 encoded strings. This function first encodes them to json, and
    then to base64 encoded strings.

    This also allows us to send the same information to any kind of charm that can unmarshal json to a native type (say python).
    .PARAMETER Object

    .NOTES
    Powershell uses utf-16-le encoding for objects

    .EXAMPLE

    $obj = @{"Hello"="world";}
    Get-MarshaledObject -Object $obj
    ewANAAoAIAAgACAAIAAiAEgAZQBsAGwAbwAiADoAIAAgACIAdwBvAHIAbABkACIADQAKAH0A
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("obj")]
        $Object
    )
    PROCESS {
        $encoded = $Object | ConvertTo-Json
        $b64 = ConvertTo-Base64 $encoded
        return $b64
    }
}

function Get-UnmarshaledObject {
    <#
    .SYNOPSIS
    Try to convert a base64 encoded string back to a powershell object.
    .PARAMETER Object
    The base64 encoded representation of the object we want to unmarshal. 
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("obj")]
        [string]$Object
    )
    PROCESS {
        $decode = ConvertFrom-Base64 $Object
        $ret = $decode | ConvertFrom-Json
        return $ret
    }
}

function Get-CmdStringFromHashtable {
    <#
    .SYNOPSIS
    Convert a hashtable to a command line key/value string. Values for hashtable keys must be string or int. The result is usually suitable for native commands executed via cmd.exe.
    .PARAMETER Parameters
    hashtable containing command line parameters.

    .EXAMPLE
    $params = @{
        "firstname"="John";
        "lastname"="Doe";
        "age"="20";
    }
    Get-CmdStringFromHashtable $params
    age=20 firstname=John lastname=Doe
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("params")]
        [Hashtable]$Parameters
    )
    PROCESS {
        $args = ""
        foreach($i in $params.GetEnumerator()) {
            $args += $i.key + "=" + $i.value + " "
        }
        return $args
    }
}

function Get-EscapedQuotedString {
    [CmdletBinding()]
    param(
        [string]$value
    )
    PROCESS {
        return "'" + $value.Replace("'", "''") + "'"
    }
}

function Get-PSStringParamsFromHashtable {
    <#
    .SYNOPSIS
    Convert a hashtable to a powershell command line options. Values can be any powershell object.
    .PARAMETER Parameters
    hashtable containing command line parameters.

    .EXAMPLE
    $params = @{
        "firstname"="John";
        "lastname"="Doe";
        "age"="20";
    }
    Get-CmdStringFromHashtable $params
    -age 20 -firstname John -lastname Doe
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Hashtable]$params
    )
    PROCESS {
        $args = ""
        foreach($i in $params.GetEnumerator()) {
            $args += ("-" + $i.key + " " + $i.value + " ")
        }

        return $args -join " "
    }
}