function Set-DelphixEngineType {
  [CmdletBinding(PositionalBinding, SupportsShouldProcess)]
  param(
    # The type of Delphix engine
    [Parameter(Position=0)]
    [ValidateSet("VIRTUALIZATION", "MASKING", "BOTH", "UNSET")]
    [string]$EngineType = "VIRTUALIZATION"
  )
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "system")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "POST" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($(
          ConvertTo-Json -InputObject @{
            type       = "SystemInfo"
            engineType = $EngineType
          }
        )))

      if ($response.status -ieq "ERROR") {
        throw $response.error
      }
    }
  }
  end {}

  <#
  .SYNOPSIS
    Sets the type of the Delphix engine
  .DESCRIPTION
    Sets the type of the Delphix engine
  .EXAMPLE
    > Set-DelphixEngineType -EngineType VIRTUALIZATION
      Sets Delphix to run as a Virtualization engine
  #>
}
