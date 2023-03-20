<#
.SYNOPSIS
This is a cli tool to speed up and automate some processes made by me

.DESCRIPTION
USAGE
    .cli.ps1 <command>

COMMANDS
    clear       clears all node_modules from the current directory onwards
    speak       speaks the text provided as argument
    copy        copies the content of the file provided as an argument
    size        gets the size of the provided file
    approve     approves the current pull request
    node        installs node's lts version along with nestjs and yarn cli
    cpf         generates a random cpf using 4devs api, defaults to AC state and copies to clipboard
    help, -?    show this help message
#>

param(
  [Parameter(Position = 0)]
  [ValidateSet("clear", "approve", "speak", "copy", "size", "help", "node", "cpf")]
  [string]$Command,

  [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
  $Rest
)

function Help {
  Get-Help $PSCommandPath
}

if (!$Command) {
  Help
  exit
}

function Speak {
  param (
    [Parameter(Position = 0, Mandatory = $True)]
    [string]$Text
  )

  if (!$IsWindows) {
    Write-Error "Sorry, the 'speak' command is only supported on Windows"
    exit
  }

  Write-Host "Speaking the text: "
  Write-Host `t $Text -F Cyan
  $sp = New-Object -ComObject SAPI.SpVoice
  $sp.Speak($Text) | Out-Null
}

function Copy-Content {
  param (
    [Parameter(Position = 0, Mandatory = $True)]
    [string]$Text
  )

  Get-Content $Text | Set-Clipboard 
}

function Clear-Modules {

  param(
    [Parameter(Position = 0, Mandatory = $False)]
    [string] $base_dir = ".\"
  )

  $folderToClear = 'node_modules'

  Get-ChildItem $base_dir -Recurse -Force | Where-Object {
    $_.PSIsContainer -and
    $_.Name -eq $folderToClear
  } | ForEach-Object {
    Write-Host "Cleaning " -N
    Write-Host $_.Parent.Name -F Green
    Remove-Item -Path $_ -Force -Recurse -ErrorAction SilentlyContinue
    Write-Output "$folderToClear were erased from $($_.Parent)"
  }

}

function Get-Size {

  param(
    [Parameter(Position = 0, Mandatory = $False)]
    [string] $base_dir = ".\"
  )

  return "{0} MB" -f ((Get-ChildItem $base_dir -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / 1MB)
}

function Approve-Pr {
  Write-Output "Approving PR"
  if (-not ( which gh )) {
    Write-Output 'GitHub CLI is not installed'
    return;
  };
  gh pr review --approve -b "![gif](https://i.shipit.today/)"
}

function Install-Node-Lts {
  Write-Output "Starting to download Nodejs LTS version"

  if (-not (which nvm)) {
    Write-Output 'nvm is not installed'
    return;
  }

  if (-not (which sudo)) {
    Write-Output 'sudo is not installed'
    return;
  }

  sudo nvm install lts && sudo nvm use lts && npm i -g @nestjs/cli yarn
}

function Get-Cpf {
  param (
    [Parameter(Position = 0, Mandatory = $False)]
    [string]$State = "AC"
  )

  if (-not (which http)) {
    Write-Output 'httpie is not installed'
    return;
  }

  $response = http --form POST https://www.4devs.com.br/ferramentas_online.php content-type:application/x-www-form-urlencoded acao=gerar_cpf pontuacao=S cpf_estado=$State

  $response | Set-Clipboard

  return $response
}

switch ($Command) {
  "clear" { Clear-Modules $Rest }
  "size" { Get-Size $Rest }
  "approve" { Approve-Pr }
  "speak" { Speak $Rest }
  "copy" { Copy-Content $Rest }
  "help" { Help }
  "node" { Install-Node-Lts }
  "cpf" { Get-Cpf $Rest }
}
