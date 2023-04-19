function Disable-DelphixUsageAnalytics {
  [CmdletBinding(SupportsShouldProcess)]
  param()
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "service/userInterface")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "POST" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($(
          ConvertTo-Json -InputObject @{
            type             = "UserInterfaceConfig"
            analyticsEnabled = $false
          }
        )))

      if ($response.status -ieq "ERROR") {
        throw $response.error
      }
      return $response.result
    }
  }
  end {}
  <#
  .SYNOPSIS
    Stops the Delphix engine from sending usage analytcs data back to Delphix
  .DESCRIPTION
    Stops the Delphix engine from sending usage analytcs data back to Delphix
  .EXAMPLE
    > Disable-DelphixUsageAnalytics
  #>
}
