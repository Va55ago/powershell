function Test-DelphixInitializationState {
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
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "domain")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "GET" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck `
        -SkipHttpErrorCheck

      # If the name is already set, then the engine must have been initialised previously
      return ($response.result) -and ($response.result.name)
    }
  }
  end {}

  <#
  .SYNOPSIS
    Determines whether the Delphix engine has already been initialised
  .DESCRIPTION
    Determines whether the Delphix engine has already been initialised
  .EXAMPLE
    > Test-DelphixInitializationState
  .OUTPUTS
    Boolean
    `true` if the Delphix engine has already been initialised. Otherwise `false`
  #>
}
