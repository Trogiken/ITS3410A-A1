#############################################################################
##
## Read-HostWithPrompt.ps1
##
## From PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#
.SYNOPSIS

Read user input, with choices restricted to the list of options you
provide. Adds a -NonInteractive switch to return the default for automated tests.
#>

Set-StrictMode -Version 3

function Read-HostWithPrompt {
    param(
        ## The caption for the prompt
        $Caption = $null,

        ## The message to display in the prompt
        $Message = $null,

        ## Options to provide in the prompt
        [Parameter(Mandatory = $true)]
        [string[]] $Option,

        ## Any help text to provide
        [string[]] $HelpText = $null,

        ## The default choice (0-based index)
        [int] $Default = 0,

        ## Non-interactive mode: return the default immediately
        [switch] $NonInteractive
    )

    if($NonInteractive)
    {
        Write-Host "NonInteractive: returning default index $Default"
        return $Default
    }

    ## Create the list of choices
    $choices = New-Object `
        Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]

    ## Go through each of the options, and add them to the choice collection
    for($counter = 0; $counter -lt $option.Length; $counter++)
    {
        $choice = New-Object Management.Automation.Host.ChoiceDescription `
            $option[$counter]

        if($helpText -and $helpText[$counter])
        {
            $choice.HelpMessage = $helpText[$counter]
        }

        $choices.Add($choice)
    }

    ## Prompt for the choice, returning the item the user selected
    $host.UI.PromptForChoice($caption, $message, $choices, $default)
}

