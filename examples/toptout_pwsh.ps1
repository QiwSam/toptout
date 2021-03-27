#Requires -Version 5

<#
.Synopsis
    Toptout shell script: Disable known telemetry channels for apps

.Parameter Env
    Set environment variables that disable telemetry

.Parameter Exec
    Execute shell commands that disable telemetry

.Parameter ShowLog
    Show operation log

.Example
    toptout_pwsh.ps1 -WhatIf

    Set environment variables and execute commands, dry run mode.

.Example
    toptout_pwsh.ps1 -ShowLog

    Set environment variables and execute commands, show log.

.Example
    toptout_pwsh.ps1 -Env -ShowLog

    Set environment variables, show log.

.Example
    toptout_pwsh.ps1 -Exec -ShowLog

    Execute commands, show log.

.Example
    toptout_pwsh.ps1

    Set environment variables and execute commands, silent.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    [switch]$Env,
    [switch]$Exec,
    [switch]$ShowLog
)

function Get-OsMoniker {
    if ($IsCoreCLR) {
        if ($IsWindows) {
            'windows'
        }
        elseif ($IsLinux) {
            'linux'
        }
        elseif ($IsMacOS) {
            'macos'
        }
    }
    else {
        'windows'
    }
}

function Invoke-ShellCommand {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Arguments,

        [switch]$ShowLog
    )

    if (Get-Command -Name $Command -CommandType Application -ErrorAction SilentlyContinue) {
        $LoggedCommand = "$Command $Arguments"

        if ($PSCmdlet.ShouldProcess($LoggedCommand, 'Execute command')) {
            if ($ShowLog) {
                Write-Host 'Executing command: ' -ForegroundColor Green -NoNewline
                Write-Host $LoggedCommand -ForegroundColor Yellow
            }

            $ret = Start-Process -FilePath $Command -ArgumentList $Arguments -NoNewWindow -Wait

            if ($ShowLog) {
                Write-Host $ret -ForegroundColor White
            }
        }
    }
}

function Set-EnvVar {
    [CmdletBinding(SupportsShouldProcess = $true)]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [switch]$ShowLog
    )

    $EnvVar = "$Name=$Value"

    if ($PSCmdlet.ShouldProcess($EnvVar, 'Set environment variable')) {
        if ($ShowLog) {
            Write-Host 'Setting environment variable: ' -ForegroundColor Green -NoNewline
            Write-Host "$EnvVar" -ForegroundColor Yellow
        }

        [System.Environment]::SetEnvironmentVariable($Name, $Value)
    }
}

if (-not $Env -and -not $Exec) {
    $Env = $Exec = $true
}


# Firefox
# https://www.mozilla.org/firefox/

# Enable policies (macOS)
# https://github.com/mozilla/policy-templates/tree/master/mac
switch (Get-OsMoniker) {
  'macos' {
    if ($Exec) {
        Invoke-ShellCommand -Command 'defaults' -Arguments 'write /Library/Preferences/org.mozilla.firefox EnterprisePoliciesEnabled -bool TRUE' -ShowLog:$ShowLog
    }
  }
}

# Firefox
# https://www.mozilla.org/firefox/

# Usage data
# https://github.com/mozilla/policy-templates/blob/master/README.md
switch (Get-OsMoniker) {
  'macos' {
    if ($Exec) {
        Invoke-ShellCommand -Command 'defaults' -Arguments 'write /Library/Preferences/org.mozilla.firefox DisableTelemetry -bool TRUE' -ShowLog:$ShowLog
    }
  }
}

# Homebrew
# https://brew.sh

# Usage data
if ($Env) {
    Set-EnvVar -Name 'HOMEBREW_NO_ANALYTICS' -Value '1' -ShowLog:$ShowLog
}

# Microsoft 365 | Enterprise
# https://www.microsoft.com/en-us/microsoft-365/enterprise

# Diagnostic data
# https://docs.microsoft.com/en-us/deployoffice/privacy/overview-privacy-controls#diagnostic-data-sent-from-microsoft-365-apps-for-enterprise-to-microsoftd
switch (Get-OsMoniker) {
  'macos' {
    if ($Exec) {
        Invoke-ShellCommand -Command 'defaults' -Arguments 'write com.microsoft.office DiagnosticDataTypePreference -string ZeroDiagnosticData' -ShowLog:$ShowLog
    }
  }
}

# AWS SAM CLI
# https://aws.amazon.com/serverless/sam/

# Usage data
if ($Env) {
    Set-EnvVar -Name 'SAM_CLI_TELEMETRY' -Value '0' -ShowLog:$ShowLog
}

# Azure CLI
# https://docs.microsoft.com/en-us/cli/azure

# Usage data
if ($Env) {
    Set-EnvVar -Name 'AZURE_CORE_COLLECT_TELEMETRY' -Value '0' -ShowLog:$ShowLog
}

# Google Cloud SDK
# https://cloud.google.com/sdk

# Usage data
if ($Exec) {
    Invoke-ShellCommand -Command 'gcloud' -Arguments 'config set disable_usage_reporting true' -ShowLog:$ShowLog
}

# Netdata
# https://www.netdata.cloud

# Usage data
if ($Env) {
    Set-EnvVar -Name 'DO_NOT_TRACK' -Value '1' -ShowLog:$ShowLog
}

# Netlify CLI
# https://netlify.com

# Usage data
if ($Exec) {
    Invoke-ShellCommand -Command 'netlify' -Arguments '--telemetry-disable' -ShowLog:$ShowLog
}

# Stripe CLI
# https://stripe.com/docs/stripe-cli

# Usage data
if ($Env) {
    Set-EnvVar -Name 'STRIPE_CLI_TELEMETRY_OPTOUT' -Value '1' -ShowLog:$ShowLog
}

# Tilt
# https://tilt.dev

# Usage data
if ($Env) {
    Set-EnvVar -Name 'DO_NOT_TRACK' -Value '1' -ShowLog:$ShowLog
}

# TimescaleDB 
# https://www.timescale.com/

# Usage data
if ($Exec) {
    Invoke-ShellCommand -Command 'psql' -Arguments '-c "ALTER SYSTEM SET timescaledb.telemetry_level=off"' -ShowLog:$ShowLog
}

# Apache Cordova CLI
# https://cordova.apache.org

# Usage data
if ($Env) {
    Set-EnvVar -Name 'CI' -Value 'ANY_VALUE' -ShowLog:$ShowLog
}

# Gatsby
# https://www.gatsbyjs.org

# Usage data
if ($Env) {
    Set-EnvVar -Name 'GATSBY_TELEMETRY_DISABLED' -Value '1' -ShowLog:$ShowLog
}

# Hasura GraphQL engine
# https://hasura.io

# Usage data (CLI and Console)
if ($Env) {
    Set-EnvVar -Name 'HASURA_GRAPHQL_ENABLE_TELEMETRY' -Value 'false' -ShowLog:$ShowLog
}

# .NET Core SDK
# https://docs.microsoft.com/en-us/dotnet/core/tools/index

# Usage data
if ($Env) {
    Set-EnvVar -Name 'DOTNET_CLI_TELEMETRY_OPTOUT' -Value 'true' -ShowLog:$ShowLog
}

# Next.js
# https://nextjs.org

# Usage data
if ($Env) {
    Set-EnvVar -Name 'NEXT_TELEMETRY_DISABLED' -Value '1' -ShowLog:$ShowLog
}

# Nuxt.js
# https://nuxtjs.org/

# Usage data
if ($Env) {
    Set-EnvVar -Name 'NUXT_TELEMETRY_DISABLED' -Value '1' -ShowLog:$ShowLog
}

# Prisma
# https://www.prisma.io/

# Usage data
# https://www.prisma.io/docs/concepts/more/telemetry#usage-data
if ($Env) {
    Set-EnvVar -Name 'CHECKPOINT_DISABLE' -Value '1' -ShowLog:$ShowLog
}

# Rasa
# https://rasa.com/

# Usage data
if ($Env) {
    Set-EnvVar -Name 'RASA_TELEMETRY_ENABLED' -Value 'false' -ShowLog:$ShowLog
}

# AutomatedLab
# https://github.com/AutomatedLab/AutomatedLab

# Usage data
if ($Env) {
    Set-EnvVar -Name 'AUTOMATEDLAB_TELEMETRY_OPTOUT' -Value '1' -ShowLog:$ShowLog
}

# Consul
# https://www.consul.io/

# Update check
# https://www.consul.io/docs/agent/options#disable_update_check
if ($Env) {
    Set-EnvVar -Name 'CHECKPOINT_DISABLE' -Value 'ANY_VALUE' -ShowLog:$ShowLog
}

# Packer
# https://www.packer.io/

# Update check
if ($Env) {
    Set-EnvVar -Name 'CHECKPOINT_DISABLE' -Value '1' -ShowLog:$ShowLog
}

# Terraform
# https://www.terraform.io/

# Update check
# https://www.terraform.io/docs/commands/index.html#disable_checkpoint
if ($Env) {
    Set-EnvVar -Name 'CHECKPOINT_DISABLE' -Value 'ANY_VALUE' -ShowLog:$ShowLog
}

# Cloud Development Kit for Terraform
# https://github.com/hashicorp/terraform-cdk

# Usage data
if ($Env) {
    Set-EnvVar -Name 'CHECKPOINT_DISABLE' -Value 'ANY_VALUE' -ShowLog:$ShowLog
}

# Vagrant
# https://www.vagrantup.com/

# Vagrant update check
# https://www.vagrantup.com/docs/other/environmental-variables#vagrant_checkpoint_disable
if ($Env) {
    Set-EnvVar -Name 'VAGRANT_CHECKPOINT_DISABLE' -Value 'ANY_VALUE' -ShowLog:$ShowLog
}

# Vagrant
# https://www.vagrantup.com/

# Vagrant box update check
# https://www.vagrantup.com/docs/other/environmental-variables#vagrant_box_update_check_disable
if ($Env) {
    Set-EnvVar -Name 'VAGRANT_BOX_UPDATE_CHECK_DISABLE' -Value 'ANY_VALUE' -ShowLog:$ShowLog
}

# Weave Net
# https://www.weave.works/

# Update check
if ($Env) {
    Set-EnvVar -Name 'CHECKPOINT_DISABLE' -Value '1' -ShowLog:$ShowLog
}

# WKSctl
# https://www.weave.works/oss/wksctl/

# Update check
if ($Env) {
    Set-EnvVar -Name 'CHECKPOINT_DISABLE' -Value '1' -ShowLog:$ShowLog
}

# PowerShell Core
# https://github.com/powershell/powershell

# Usage data
if ($Env) {
    Set-EnvVar -Name 'POWERSHELL_TELEMETRY_OPTOUT' -Value '1' -ShowLog:$ShowLog
}
