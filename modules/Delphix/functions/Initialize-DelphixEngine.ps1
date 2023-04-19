#Requires -Version 7.0

function Initialize-DelphixEngine {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    # The credentials of the default admin user to be created during initialisation of the engine
    [PSCredential]$DefaultAdminCredential
  )
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "storage/device")

    $data_disks = @()
    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost, "Get-DelphixDiskConfiguration")) {
      $response = Invoke-RestMethod `
        -Method "GET" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck

      if ($response.status -ieq "ERROR") {
        throw $response.error
      }

      $data_disks = @($response.result |
        Where-Object -FilterScript { $_.name -like "lun*" } |
        Select-Object -ExpandProperty "reference"
      )
    }

    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "domain/initializeSystem")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "POST" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($(
          ConvertTo-Json -InputObject @{
            type            = "SystemInitializationParameters"
            defaultUser     = $defaultAdminCredential.Username
            defaultPassword = (ConvertFrom-SecureString -SecureString $defaultAdminCredential.Password -AsPlainText)
            devices         = $data_disks
          }
        )))

      if ($response.status -ieq "ERROR") {
        throw $response.error
      }

      Write-Information "Sleeping for 30 seconds... 😴"
      Start-Sleep -Seconds 30
    }
  }
  end {}

  <#
  .SYNOPSIS
    Initialize Delphix storage, core domain objects and node type
  .DESCRIPTION
    Initialize Delphix storage, core domain objects and node type
  .EXAMPLE
    > Initialize-DelphixEngine
      Initializes the Delphix engine
  #>
}
