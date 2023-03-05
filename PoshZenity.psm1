$ZenitySeparator = [char] 1 # zenity does not play nice with null, and the default '|' character is bad so use \u{1} as the separator


function Get-CredentialWithZenity {
    <#
    .Synopsis
    Get-Credential alternative that uses Zenity to create a GTK popup prompt

    .Description
    An alternative to Get-Credential that uses Zenity to create a GTK popup
    prompt. The implementation should be usable as a drop-in replacement
    for Get-Credential
    #>
    [CmdletBinding(DefaultParameterSetName='Default')]
    Param (
        [string] $Message,
        [string] $Title,
        [Parameter(Mandatory=$False,ParameterSetName="Default")]
        [string] $UserName,
        [Parameter(Mandatory=$True,ParameterSetName="FromExistingCredential")]
        $Credential
    )

    Begin {
        if ($PsCmdlet.ParameterSetName -eq "FromExistingCredential") {
            if ($Credential.GetType() -eq [System.Management.Automation.PSCredential]) {
                return $Credential
            } else {
                $UserName = $Credential
            }
        }

        $ZenityArgs = @('--forms', "--separator=$ZenitySeparator")

        # if $Title is set, use it, otherwise, use the fallback title  "PoshZenity Password Prompt"
        if ($Title) {
            $ZenityArgs += "--title=$Title"
        } else {
            $ZenityArgs += "--title=PoshZenity Password Prompt"
        }

        # Add message if it is set.
        if ($Message) {
            $ZenityArgs += "--text=$Message"
        }

        # Add a username line with Username: followed by either the pre-set username or a text box
        if ( -Not $UserName) {
            $ZenityArgs += "--add-entry=Username:"
        }
        # Finally, add the password prompt
        $ZenityArgs += "--add-password=Password:"

        # call zenity, and create the PSCredential object from the result

        if ($UserName) {
            return New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, (ConvertTo-SecureString -String $(zenity $ZenityArgs) -Force -AsPlainText)
        } else {

            $UserName, $RawPassword = $(zenity $ZenityArgs).split($ZenitySeparator)
            $Password = ConvertTo-SecureString -String $RawPassword  -Force -AsPlainText
            Remove-Variable RawPassword # Delete this variable ASAP
            return New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $Password
        }
    }
}

