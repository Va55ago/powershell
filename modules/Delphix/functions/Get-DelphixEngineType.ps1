function Get-DelphixEngineType {
  [CmdletBinding(PositionalBinding, SupportsShouldProcess)]
  param()
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
        -Method "GET" `
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
      return $response.result.engineType
    }
  }
  end {}

  <#
  .SYNOPSIS
    Gets the type of the Delphix engine
  .DESCRIPTION
    Gets the type of the Delphix engine
  .EXAMPLE
    > Get-DelphixEngineType
  #>
}
