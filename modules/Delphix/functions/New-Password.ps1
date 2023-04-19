function New-Password {
  param (
    # Length of the password required
    [Parameter(Mandatory)]
    [ValidateRange(10,[int]::MaxValue)]
    [int]$Length,
    
    # Minimum number of lowercase characters to be included in the password
    [Parameter()]
    [ValidateRange(0)]
    [int]$MinimumLowercase = 1,

    # Minimum number of uppercase characters to be included in the password
    [Parameter()]
    [ValidateRange(0)]
    [int]$MinimumUppercase = 1,

    # Minimum number of numeric characters to be included in the password
    [Parameter()]
    [ValidateRange(0)]
    [int]$MinimumNumeric = 1,

    # Minimum number of special characters to be included in the password
    [Parameter()]
    [ValidateRange(0)]
    [int]$MinimumSpecial = 1,

    # List of allowed lowercase characters to be used when generating the password
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [char[]]$AllowedLowercase = "abcdefghijklmnopqrstuvwxyz",

    # List of allowed uppercase characters to be used when generating the password
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [char[]]$AllowedUppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",

    # List of allowed numeric characters to be used when generating the password
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [char[]]$AllowedNumeric = "0123456789",

    # List of allowed special characters to be used when generating the password
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [char[]]$AllowedSpecial = "/*-+,!?=()@;:._"
  )
  begin {
    if ($MinimumLowercase + $MinimumUppercase + $MinimumNumeric + $MinimumSpecial -eq 0) {
      throw "The minimum number of at least one of the Lowercase, Uppercase, Numeric or Special characters must be greater than 0"
    }
    if ($MinimumLowercase + $MinimumUppercase + $MinimumNumeric + $MinimumSpecial -gt $Length) {
      throw "Sum of the minimum number of Lowercase, Uppercase, Numeric & Special characters must not exceed the total Length"
    }

    [char[]]$fullCharSet = @(
      if ($MinimumLowercase -gt 0) { $AllowedLowercase } else { @() }
      if ($MinimumUppercase -gt 0) { $AllowedUppercase } else { @() }
      if ($MinimumNumeric -gt 0) { $AllowedNumeric } else { @() }
      if ($MinimumSpecial -gt 0) { $AllowedSpecial } else { @() }
    )
  }
  process {
    # $result will be a hashtable of random integers --> random characters from the allowed character set.
    $result = @{}

    # Add the minimum number of random lowecase chars
    for ($i = 0; $i -lt $MinimumLowercase; $i++) {
      $result.Add((Get-Random), $AllowedLowercase[(Get-Random) % $AllowedLowercase.Length])
    }
    # Add the minimum number of random uppercase chars
    for ($i = 0; $i -lt $MinimumUppercase; $i++) {
      $result.Add((Get-Random), $AllowedUppercase[(Get-Random) % $AllowedUppercase.Length])
    }
    # Add the minimum number of random numeric chars
    for ($i = 0; $i -lt $MinimumNumeric; $i++) {
      $result.Add((Get-Random), $AllowedNumeric[(Get-Random) % $AllowedNumeric.Length])
    }
    # Add the minimum number of random special chars
    for ($i = 0; $i -lt $MinimumSpecial; $i++) {
      $result.Add((Get-Random), $AllowedSpecial[(Get-Random) % $AllowedSpecial.Length])
    }
    # Add any remaining chars by picking randomly from the full character set
    for ($i = 0; $i -lt ($Length-$MinimumLowercase-$MinimumUppercase-$MinimumNumeric-$MinimumSpecial); $i++) {
      $result.Add((Get-Random), $fullCharSet[(Get-Random) % $fullCharSet.Length])
    }

    # Sorting the hashtable by its random key will result in the password characters being randomly shuffled.
    $password = -join ($result.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value)

    return ConvertTo-SecureString -String $password -AsPlainText -Force
  }
  end {}

  <#
  .SYNOPSIS
    Generates a password
  .DESCRIPTION
    Generates a password that meets the specified requirements.
  .EXAMPLE
    > New-Password -Length 20
      Generates a 20 character password with at least
      - 1 lowercase character within the full range of lowercase characters,
      - 1 uppercase character within the full range of uppercase characters,
      - 1 numeric character within the full range of numeric characters and
      - 1 special character within the default range of allowed special characters
    
    > New-Password -Length 128 -Lower 5 -Upper 4 -Numeric 3 -Special 2 -AllowedSpecial "*_"
      Generates a 128 character password with at least
      - 5 lowercase characters within the full range of lowercase characters,
      - 4 uppercase characters within the full range of uppercase characters,
      - 3 numeric characters within the full range of numeric characters and
      - 2 special characters, using only the '*' and '_' special characters
  .OUTPUTS
    [securestring]
    The generated password

  .NOTES
    If you set any of the `Minimum` parameters to 0, then exactly _none_ of
    that type of character will be used in the generated password.

    I.e. A minimum of '0' is treated as a special case that means:
      "I want _none_ of those types of characters"
    ... rather than:
      "I want _any number_ of those types of characters".
  #>
}