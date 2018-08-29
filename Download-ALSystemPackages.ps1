function Download-ALSystemPackages
{
    param (
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $ContainerName,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Build='',
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $PlatformVersion,
        [Parameter(ValueFromPipelineByPropertyName=$True)]
        $Password='Pass@word1',
        $IncludeTestModule=$False,
        $AlPackagesPath,
        $TestApp
    )

    function Get-AlSymbolFile {
        param(
            
            [Parameter(Mandatory = $false)]
            [String] $Publisher = 'Microsoft',
            [Parameter(Mandatory = $true)]
            [String] $AppName,
            [Parameter(Mandatory = $true)]
            [String] $AppVersion,
            [Parameter(Mandatory = $true)]
            [String] $DownloadFolder,
            [ValidateSet('Windows', 'NavUserPassword')]
            [Parameter(Mandatory = $true)]
            [String] $Authentication='Windows',
            [Parameter(Mandatory = $true)] 
            [pscredential] $Credential 
        )

        $TargetFile = Join-Path -Path $DownloadFolder -ChildPath "$($Publisher)_$($AppName)_$($AppVersion).app"

        if ($Authentication -eq 'NavUserPassword') {
            $PasswordTemplate = "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"
            $PasswordBytes = [System.Text.Encoding]::Default.GetBytes($PasswordTemplate)
            $EncodedText = [Convert]::ToBase64String($PasswordBytes)
            
            $null = Invoke-RestMethod `
                        -Method get `
                        -Uri "http://$($ContainerName):7049/nav/dev/packages?publisher=$($Publisher)&appName=$($AppName)&versionText=$($AppVersion)&tenant=default" `
                        -Headers @{ "Authorization" = "Basic $EncodedText"} `
                        -OutFile $TargetFile `
                        -TimeoutSec 600 -Verbose
            
        }  else {
            $null = Invoke-RestMethod `
                        -Method get `
                        -Uri "http://$($ContainerName):7049/nav/dev/packages?publisher=$($Publisher)&appName=$($AppName)&versionText=$($AppVersion)&tenant=default" `
                        -Credential $Credential `
                        -OutFile $TargetFile `
                        -TimeoutSec 600 -Verbose
        }

        Get-Item $TargetFile
    }

    if (-not $AlPackagesPath) {
        $alpackages = (Join-Path $AppPath '.alpackages')
    } else {
        $alpackages = $AlPackagesPath
    }
    if (-not (Test-path $alpackages)) {
        mkdir $alpackages | out-null
    }

    if ($Build -eq '') {
        $credentials = Get-Credential -Message "Enter your WINDOWS password!!!" -UserName $env:USERNAME
        Get-AlSymbolFile `
            -AppName 'Application' `
            -AppVersion $PlatformVersion `
            -DownloadFolder $alpackages `
            -Authentication 'Windows' `
            -Credential $credentials   

        Get-AlSymbolFile `
            -AppName 'System' `
            -AppVersion $PlatformVersion `
            -DownloadFolder $alpackages `
            -Authentication 'Windows' `
            -Credential $credentials  

        if ($IncludeTestModule) {
            Get-AlSymbolFile `
            -AppName 'Test' `
            -AppVersion $PlatformVersion `
            -DownloadFolder $alpackages `
            -Authentication 'Windows' `
            -Credential $credentials  
        }

    } else {
        $PWord = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $User = $env:USERNAME
        $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User,$PWord
        Get-AlSymbolFile `
            -AppName 'Application' `
            -AppVersion $PlatformVersion `
            -DownloadFolder $alpackages `
            -Authentication 'Windows' `
            -Credential $credentials   

        Get-AlSymbolFile `
            -AppName 'System' `
            -AppVersion $PlatformVersion `
            -DownloadFolder $alpackages `
            -Authentication 'Windows' `
            -Credential $credentials  

        if ($IncludeTestModule) {
            Get-AlSymbolFile `
            -AppName 'Test' `
            -AppVersion $PlatformVersion `
            -DownloadFolder $alpackages `
            -Authentication 'Windows' `
            -Credential $credentials  
        }
    }
}