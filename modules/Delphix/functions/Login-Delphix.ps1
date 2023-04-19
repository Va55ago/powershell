#Requires -Version 7.0

function Login-Delphix {
  [CmdletBinding(PositionalBinding, SupportsShouldProcess, ConfirmImpact='Low')]
  param(
    # Credentials of the Delphix user account to login as
    [Parameter(Mandatory, ValueFromPipeline, Position=0)]
    [PSCredential]$Credential
  )
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "login")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "POST" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($(
          ConvertTo-Json -InputObject @{
            type     = "LoginRequest"
            username = $Credential.UserName
            password = (ConvertFrom-SecureString -SecureString $Credential.Password -AsPlainText)
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
    Connect to the Delphix engine using one of the Delphix system accounts
  .DESCRIPTION
    Connect to the Delphix engine using one of the Delphix system accounts
  .EXAMPLE
    > Login-Delphix -Credential (Get-Credential)
      Logs into the Delphix engine using user supplied credentials
  .OUTPUTS
    [System.String]
    The user reference of the logged in user
  #>
}
