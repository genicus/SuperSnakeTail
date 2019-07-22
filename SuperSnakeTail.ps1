<#
.SYNOPSIS
  Filters lines from a logfile, based on defined words.
.DESCRIPTION
  This script reads a logfile, checks the lines for defined words and will highlight the words. Also possible to highlight errors and warnings.
  Keeps running until canceled, new lines appended to the logfile will be added on console. Words in filter are case insensitive.
.PARAMETER FileName
  The log to analyze
.PARAMETER ColorFilter
  The words to look for in the log. Maximum 8 (available colors), delimited by the pipe (|) symbol. Defined words will be highlighted
.PARAMETER Exclude
  Exclude lines from overview if one of these words is found in the log
.PARAMETER ShowAll
  Will show all lines in the log, not only the ones with filtered words.
.PARAMETER HighlightErrorsAndWarnings
  If this switch is set, the script will highlight warnings and errors.
.PARAMETER OutFile
  The script will write the filtered loglines to this file if defined.
.OUTPUTS
  Only if parameter OutFile is defined.
.NOTES
  Version:        1.0
  Author:         Leendert De Cae
  Creation Date:  06/02/2019
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\SuperSnakeTail.ps1 -FileName .\test.txt -ColorFilter "cool|awesome"
  Will search the log "test.txt" for words "cool" and "awesome" and display lines of the log with these words highlighted
.EXAMPLE
  .\SuperSnakeTail.ps1 -FileName .\test.txt -ColorFilter "cool|awesome" -HighlightErrorsAndWarnings
  Will search the log "test.txt" for words "cool" and "awesome" and display lines of the log with these words highlighted, as well as highlight any errors or warnings
.EXAMPLE
  .\SuperSnakeTail.ps1 -FileName .\test.txt -ColorFilter "cool|awesome" -OutFile .\out.txt
  Will search the log "test.txt" for words "cool" and "awesome" and display lines of the log with these words highlighted and save the filtered log to "out.txt"
#>

Param(
        [Parameter(Mandatory=$true)][string]$FileName,
        [Alias("Filter")][string]$ColorFilter,
        [string]$Exclude,
        [switch]$ShowAll,
        [switch]$HighlightErrorsAndWarnings,
        [string]$OutFile
)

#beautiful library by u/Kewlb on Reddit, modded to fit what we want
Function Write-Color
{
<#
  .SYNOPSIS
    Enables support to write multiple color text on a single line
  .DESCRIPTION
    Users color codes to enable support to write multiple color text on a single line
    ################################################
    # Write-Color Color Codes
    ################################################
    # ^cn = Normal Output Color
    # ^ck = Black
    # ^cb = Blue
    # ^ca = Cyan
    # ^ce = Gray
    # ^cg = Green
    # ^cm = Magenta
    # ^cr = Red
    # ^cw = White
    # ^cy = Yellow
    # ^cB = DarkBlue
    # ^cA = DarkCyan
    # ^cE = DarkGray
    # ^cG = DarkGreen
    # ^cM = DarkMagenta
    # ^cR = DarkRed
    # ^cY = DarkYellow [Unsupported in Powershell]
    ################################################
  .PARAMETER text
    Mandatory. Line of text to write
  .INPUTS
    [string]$text
  .OUTPUTS
    None
  .NOTES
    Version:        1.0
    Author:         Brian Clark
    Creation Date:  01/21/2017
    Purpose/Change: Initial function development
    Version:        1.1
    Author:         Brian Clark
    Creation Date:  01/23/2017
    Purpose/Change: Fix Gray / Code Format Fixes
  .EXAMPLE
    Write-Color "Hey look ^crThis is red ^cgAnd this is green!"
#>
 
  [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)][string]$text
    )
     
    ### If $text contains no color codes just write-host as normal
    if (-not $text.Contains("^c"))
    {
        Write-Host "$($text)"
        return
    }
 
 
    ### Set to true if the beginning of $text is a color code. The reason for this is that
    ### the generated array will have an empty/null value for the first element in the array
    ### if this is the case.
    ### Since we also assume that the first character of a split string is a color code we
    ### also need to know if it is, in fact, a color code or if it is a legitimate character.
    $blnStartsWithColor = $false
    if ($text.StartsWith("^c")) {
        $blnStartsWithColor = $true
    }
 
    ### Split the array based on our color code delimeter
    $strArray = $text -split "\^c"
    ### Loop Counter so we can generate a new empty line on the last element of the loop
    $count = 1
 
    ### Loop through the array
    $strArray | ForEach-Object {
        if ($count -eq 1 -and $blnStartsWithColor -eq $false)
        {
            Write-Host $_ -NoNewline
            $count++
        }
        elseif ($_.Length -eq 0)
        {
            $count++
        }
        else
        {
 
            $char = $_.Substring(0,1)
            $color = ""
            switch -CaseSensitive ($char) {
                "b" { $color = "Blue" }
                "B" { $color = "DarkBlue" }
                "a" { $color = "Cyan" }
                "A" { $color = "DarkCyan" }
                "e" { $color = "Gray" }
                "E" { $color = "DarkGray" }
                "g" { $color = "Green" }
                "G" { $color = "DarkGreen" }
                "k" { $color = "Black" }
                "m" { $color = "Magenta" }
                "M" { $color = "DarkMagenta" }
                "r" { $color = "Red" }
                "R" { $color = "DarkRed" }
                "w" { $color = "White" }
                "y" { $color = "Yellow" }
                "Y" { $color = "DarkYellow" }
            }
 
            ### If $color is empty write a Normal line without ForgroundColor Option
            ### else write our colored line without a new line.
            if ($color -eq "")
            {
                Write-Host $_.Substring(1) -NoNewline
            }
            else
            {
                if([char]::IsUpper($char))
                {
                    Write-Host $_.Substring(1) -NoNewline -BackgroundColor $color
                } else
                {
                    Write-Host $_.Substring(1) -NoNewline -ForegroundColor Black -BackgroundColor $color
                }
            }
            ### Last element in the array writes a blank line.
            if ($count -eq $strArray.Count)
            {
                Write-Host ""
            }
            $count++
        }
    }
}

function colorFilter
{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)][string]$pipe,
        [string[]]$filter,
        [string[]]$excludes
    )
    process {
        $colorNbr = 0 #keep a hold of the colors we've already used
        $output = $false
        $originalPipe = $pipe #we'll be modifying the original string, but maybe the user wants to output it to another file so we're remembering it
        if($filter)
        {
            foreach($f in $filter)
            {
                if($pipe.toLower().contains($f.toLower())) #comparing toLower values -> case insensitive
                {
                    $output = $true
                    $wordIndex = ($pipe | Select-String $f -AllMatches).Matches.Index #find all occurances of the string we're looking for
                    for($i=0;$i -lt $wordIndex.length;$i++)
                    {
                        $colorMarker = "^c"+$colorMap[$colorNbr] #generate colormarker

                        $pipe = $pipe.Insert($wordIndex[$i]+(2*3*$i),$colorMarker) #take in concideration we already added a few times 3 characters twice characters!
                        $pipe = $pipe.Insert($wordIndex[$i]+(2*3*$i)+$f.length+3,"^cn")
                    }
                }       
                $colorNbr++
            }
        }
        else {
            $output = $true
        }
        if($HighlightErrorsAndWarnings) #if user asks for it, we'll highlight the error and warning lines. Processing after initial coloring -> initial trigger kept
        {
            foreach($e in $errorWords)
            {
                if($pipe.toLower().Contains($e.toLower()))
                {
                    $pipe = "^cR" + $pipe.Replace("^cn",'^cR') #replace the back to normals with appropriate colors
                }
            }
            foreach($w in $warningWords)
            {
                if($pipe.toLower().Contains($w.toLower()))
                {
                    $pipe = "^cy" + $pipe.Replace("^cn",'^cy')
                }
            }
        }

        if($excludes)
        {
            foreach($exclude in $excludes)
            {
                if($pipe.ToLower().Contains($exclude.ToLower()))
                {
                    $output = $false
                }
            }
        }

        if($pipe -ne "" -and ($output -or $showAll))
        {
            Write-Color $pipe
            if($OutFile)
            {
                Add-Content $OutFile $originalPipe
            }
        }
    }
}
$colorMap = "agmeAGME" #all possible sane colors to use in Write-Color function
$errorWords = @("error","critical","exception") #define words that trigger errors to highlight line red
$warningWords = @("warning","warn") #define words that trigger warnings to highlight line yellow

$filterSplit = $ColorFilter.Split("|") #split filters to array
$excludeSplit = $Exclude.Split("|")

if($filterSplit.Length -gt $colorMap.Length) #limit amount of filters: we might run out of colors!
{
    Write-Host "Hold your horses! You've defined way too many filters!"
} else 
{
    if(Test-Path $FileName) #check if file exists
    {
        Get-Content $fileName -Wait -Tail 10 | colorFilter -filter $filterSplit -excludes $excludeSplit #send input to filter
    } else
    {
        Write-Host "File not found"
    }
}