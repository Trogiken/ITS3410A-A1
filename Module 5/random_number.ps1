param(
    [int] $Minimum = 1,
    [int] $Maximum = 100
)

# Get-Random's -Maximum is exclusive; to include the specified maximum add 1
$randomNumber = Get-Random -Minimum $Minimum -Maximum ($Maximum + 1)

Write-Host $randomNumber
