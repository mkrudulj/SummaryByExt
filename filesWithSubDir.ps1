Function customExit($customMessage)
{
    Write-Host -ForegroundColor Red "Error: $customMessage"
    Exit
}

$reportType = "summByExt"
$valueTitle = "Summary Value in Mb"
$supportedReportTypes = "largestFileByExt","summByExt"
$ouptutList = @{ }
$scriptTestedOn = '$IsLinux -or (!(Test-Path Variable:\IsWindows) -or $IsWindows)'
########################################^^^"IsWindows" does not exist on regular (non Core) PowerShell which is Windows only



if (!(Invoke-Expression $scriptTestedOn)) {
    if((Read-Host "Script is not tested on this platform. Dou you want to continue? (y/N)") -ne "y"){
        customExit("Execution canceled by user.")
    }
}

for ($i = 0; $i -lt $args.count; $i++) {
  if ($args[$i] -eq "-InputDirectory"){$i++;$inputDirectory=$args[$i]} 
  elseif ($args[$i] -eq "-OutputDirectory"){$i++;$outputDirectory=$args[$i]}
  elseif (($args[$i] -eq "-ReportType") -and ($null -ne $args[$i+1])){$i++;$reportType=$args[$i]}
  else {customExit("Parameter $($args[$i]) is not supported.")}
}

if ($null -eq $inputDirectory){customExit("InputDirectory is missing.")}
if ($null -eq $outputDirectory){customExit("OutputDirectory is missing.")}
if (!(Test-Path -Path $inputDirectory -PathType container)){customExit("InputDirectory (",$inputDirectory,") does not exist.")}
if (!(Test-Path -Path $outputDirectory -PathType container)){customExit("OutputDirectory (",$outputDirectory,") does not exist.")}
if (!($supportedReportTypes -contains $reportType)){customExit("Report type (",$reportType,") is not supported.")}


foreach($file in Get-ChildItem -Path $inputDirectory -File -Recurse -Force -ErrorAction SilentlyContinue)
{
  if($ouptutList.ContainsKey($file.Extension)) {
    switch ($reportType)
    {
      "largestFileByExt" {
        if($ouptutList[$file.Extension] -le $file.Length){
          $ouptutList[$file.Extension] = $file.Length
        }
      }
      "summByExt" {
        $ouptutList[$file.Extension] = $ouptutList[$file.Extension]+$file.Length
      }
    }
  } else {
    $ouptutList.Add($file.Extension,$file.Length)
  }
}

$outputFile = Join-Path -Path $outputDirectory -ChildPath report.csv

#If need absolut path, uncomment next line
#$outputFile = Convert-Path -Path $outputFile

if ($reportType -eq "largestFileByExt"){$valueTitle = "Largest file in Mb"}

$ouptutList.GetEnumerator() | Sort-Object -Property Value -Descending |
  Select-Object Name, Value -First 10 |
  Select-Object -property @{Label="Extension";Expression={($_.Name)}}, @{label=$valueTitle;Expression={"{0:N2}" -f ($_.Value / 1MB)}} | 
  Out-File $outputFile
