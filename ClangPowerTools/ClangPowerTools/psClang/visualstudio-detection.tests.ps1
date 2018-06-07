﻿#Clear-Host

# IMPORT code blocks

Set-Variable -name "kScriptLocation"                                              `
             -value (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) <#`
             -option Constant#>

@(
 , "$kScriptLocation\io.ps1"
 , "$kScriptLocation\visualstudio-detection.ps1"
 ) | ForEach-Object { . $_ }

Describe "Visual Studio detection" {
  # Mock script parameters
  $aVisualStudioVersion = "2017"
  $aVisualStudioSku     = "Professional"

  It "Get-MscVer" {
    [string[]] $mscVer = Get-MscVer
    $mscVer.Count | Should -BeExactly 1
    $mscVer[0] | Should -Not -BeNullOrEmpty
    $mscVer[0].Length | Should -BeGreaterThan 3
    $mscVer[0].Contains(".") | Should -BeExactly $true
  }

  It "Get-VisualStudio-Path" {
    $vsPath = Get-VisualStudio-Path
    $vsPath | Should -Not -BeNullOrEmpty
  }

  It "Get-VisualStudio-Path [2015]" {
    # see first if VS 2015 is installed
    [Microsoft.Win32.RegistryKey] $vs14Key = Get-Item "HKLM:SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0"
    [bool] $vs2015isInstalled = $vs14Key -and ![string]::IsNullOrEmpty($vs14Key.GetValue("InstallDir"))

    $oldMockValue = $aVisualStudioVersion

    $vsPath = Get-VisualStudio-Path
    $vsPath | Should -Not -BeNullOrEmpty

    # Re-Mock script parameter
    $aVisualStudioVersion = "2015"

    if ($vs2015isInstalled)
    {
      $vs2015Path = Get-VisualStudio-Path
      $vs2015Path | Should -Not -BeNullOrEmpty
      $vs2015Path | Should -Not -Be $vsPath
    }
    else
    {
      { Get-VisualStudio-Path } | Should -Throw
    }

    $aVisualStudioVersion = $oldMockValue
  }

  It "Get-VisualStudio-Includes" {
    [string] $vsPath = Get-VisualStudio-Path
    [string] $mscver = Get-MscVer
    [string[]] $includes = Get-VisualStudio-Includes -vsPath $vsPath -mscVer $mscver
    $includes.Count | Should -BeGreaterThan 1
    $includes | ForEach-Object { [System.IO.Directory]::Exists($_) | Should -BeExactly $true }
  }
}
