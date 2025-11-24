#param(
#    [Parameter(Mandatory = $true, Position = 0)]
#    [string]$ClangExecutable,
#
#    [Parameter(ValueFromRemainingArguments = $true)]
#    [string[]]$CompilerArgs
#)

# Create a temporary argfile for that linker call
function New-TempArgfile
{
    # Create a temporary directory for argfiles if not existing
    $ARGFILES_DIR = Join-Path $env:TEMP "toolchains_llvm\argfiles"
    if (-not (Test-Path $ARGFILES_DIR))
    {
        New-Item -ItemType Directory -Path $ARGFILES_DIR -Force | Out-Null
    }
    do
    {
        $guid = [guid]::NewGuid().ToString()
        $outputFile = Join-Path $ARGFILES_DIR "${guid}_args.txt"
    } while (Test-Path $outputFile)
    return $outputFile
}

# Process a single argument, dealing with argfile argument recursively
function Process-SingleArg
{
    param([string]$arg)

    if ( $arg.StartsWith("@"))
    {
        $argfile = $arg.Substring(1)
        Process-Argfile $argfile
    }
    else
    {
        Transform-AndWriteArgumentToArgfile $arg
    }
}

# Read an argfile and process each line recursively
function Process-Argfile
{
    param([string]$file)

    if (Test-Path $file)
    {
        foreach ($line in Get-Content -Path $file)
        {
            Process-SingleArg $line
        }
    }
}

# Apply transformation rules and write to output file
function Transform-AndWriteArgumentToArgfile
{
    param([string]$arg)

    # Strip surrounding quotes if present
    if ($arg.StartsWith('"') -and $arg.EndsWith('"'))
    {
        $arg = $arg.Substring(1, $arg.Length - 2)
    }

    $needs_xlinker = $false

    # Special case: --sysroot=path -> -Xlinker /LIBPATH:path
    if ($arg -match "^--sysroot=(.+)$")
    {
        $sysroot_path = $Matches[1]
        $arg = "/LIBPATH:$sysroot_path"
        $needs_xlinker = $true
    }

    # Check for prefix matches
    $prefixPatterns = @(
        "^/MACHINE:",
        "^/OPT:",
        "^/DEF:",
        "^/LIBPATH:",
        "^/PDBALTPATH:",
        "^/NATVIS:",
        "^/SUBSYSTEM:",
        "^/OUT:",
        "^/defaultlib:",
        "^/IMPLIB:",
        "^/INCREMENTAL:"
    )

    foreach ($pattern in $prefixPatterns)
    {
        if ($arg -match $pattern)
        {
            $needs_xlinker = $true
            break
        }
    }

    # Check for exact matches
    $exactMatches = @("/NOLOGO", "/NXCOMPAT", "/DYNAMICBASE", "/DLL", "/DEBUG")
    if ($arg -in $exactMatches)
    {
        $needs_xlinker = $true
    }

    # TODO: seems like PDBALTPATH's value `%_PDB%` is being evaluated in this script instead of by the linker
    # Write -Xlinker and argument on same line if rule matched, otherwise just argument
    if (-not [string]::IsNullOrWhiteSpace($arg))
    {
        if ($needs_xlinker)
        {
            Add-Content -Path $OUTPUT_FILE -Value "-Xlinker $arg"
        }
        else
        {
            Add-Content -Path $OUTPUT_FILE -Value $arg
        }
    }
}

$OUTPUT_FILE = New-TempArgfile

$ClangExecutable = $args[1]
foreach ($arg in $args[2..($args.Length-1)])
{
    Process-SingleArg $arg
}

# Call linker
if (Test-Path $OUTPUT_FILE)
{
    & $ClangExecutable "-v" "-Xlinker" "-verbose" "@$OUTPUT_FILE"
    $exit_code = $LASTEXITCODE
}
else
{
    $exit_code = 0
}

exit $exit_code
