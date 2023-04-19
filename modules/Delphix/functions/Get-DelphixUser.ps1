function Get-DelphixUser {
  [CmdletBinding(PositionalBinding, SupportsShouldProcess, DefaultParameterSetName="CurrentUser")]
  param(
    # If specified, details of the currenly logged in user will be returned
    [Parameter(ParameterSetName="CurrentUser", Position=0)]
    [switch]$Current,

    # Reference of the Delphix user
    [Parameter(ValueFromPipeline, ParameterSetName="SpecifiedUser", Position=0)]
    [string]$UserReference = $null,

    # Type the Delphix user
    [Parameter(Position=1)]
    [ValidateSet("SYSTEM", "DOMAIN")]
    [string]$UserType
  )
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "user")

    if ($Current) {
      $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "user/current")
    }
    elseif ($UserReference) {
      $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "user/$UserReference")
    }
    
    if ($UserType) {
      $uri = $uri = [System.Uri]::new($uri, "?type=$UserType")
    }

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "GET" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck

      if ($response.status -ieq "ERROR") {
        throw $response.error
      }
      return $response.result
    }
  }
  end {}

  <#
  .SYNOPSIS
    Gets details of the specified user
  .DESCRIPTION
    Gets details of the specified user
  .EXAMPLE
    > Get-DelphixUser -Current
      Gets the currently logged in Delphix User

    > Get-DelphixUser -DelphixUserReference "USER-1"
      Gets the Delphix User with reference "USER-1"
  .OUTPUTS
    System.Object
    An object containing details of the currently logged in user
  #>
}
