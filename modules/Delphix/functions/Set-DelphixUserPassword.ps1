#Requires -Version 7.0

function Set-DelphixUserPassword {
  [CmdletBinding(PositionalBinding, SupportsShouldProcess)]
  param(
    # Reference of the user whose password is to be updated
    [Parameter(Mandatory, ValueFromPipeline, Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$UserReference,

    # The user's new password
    [Parameter(Mandatory, Position=1)]
    [ValidateNotNull()]
    [securestring]$Password
  )
  begin {
    # Ensure that a Delphix session has already been created
    $delphixSession = Get-Variable -Name '__DelphixSession' -Scope Global -ErrorAction SilentlyContinue
    if (-not $delphixSession) {
      throw "No Delphix session found. Please run Enter-DelphixSession first."
    }
  }
  process {
    $uri = [System.Uri]::new($delphixSession.Value.BaseUri, "user/$($UserReference)/updateCredential")

    if ($PSCmdlet.ShouldProcess($uri.DnsSafeHost)) {
      $response = Invoke-RestMethod `
        -Method "POST" `
        -Uri $uri `
        -Headers @{ "Content-Type" = "application/json" } `
        -WebSession $delphixSession.Value.WebSession `
        -SkipCertificateCheck `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($(
          ConvertTo-Json -InputObject @{
            type          = "CredentialUpdateParameters"
            newCredential = @{
              type     = "PasswordCredential"
              password = (ConvertFrom-SecureString -SecureString $Password -AsPlainText)
            }
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
    Change the password of the specified user
  .DESCRIPTION
    Change the password of the specified user
  .EXAMPLE
    > $password = ConvertTo-SecureString "MyPassword" -AsPlainText
    > Set-DelphixUserPassword -UserReference "USER-1" -Password $password

      Sets the password of the Delphix User with reference "USER-1" to "MyPassword"
  #>
}
