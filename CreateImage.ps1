#This scripts is only can be used when VMware PowerCLI is installed correctly. 
#Only for ESXi 5.x

# Check Arguments

param($VibsBundle, $BaseBundle, $ExportISO, $ExportBundle)

function Usage {
@'

Create.ps1 -VibsBundle <string> -BaseBundle <string> -ExportISO <string>

-VibsBundle : Specifies the directory to the vib bundle zip file
-BaseBundle : Specifies the directory to the base bundle zip file from VMware
-ExportISO  : Specifies the directory of ISO file to be created
-ExportBundle : Specifies the directory of the zip bundle file to be created.

'@
exit 1 # or throw here if you prefer
}

if (!$VibsBundle -or !$BaseBundle -or !$ExportISO -or !$ExportBundle ) {
Usage
}
else
{



# Load VMware enviroment and snapin.
Add-PSSnapin VMware.VimAutomation.Core 

$productName = "vSphere PowerCLI"
$productShortName = "PowerCLI"
$host.ui.RawUI.WindowTitle = "[$productName] Not Connected"

[void][Reflection.Assembly]::LoadWithPartialName("VMware.Vim")

# Returns the path (with trailing backslash) to the directory where PowerCLI is installed.
function Get-InstallPath {
   $regKeys = Get-ItemProperty "hklm:\software\VMware, Inc.\VMware vSphere PowerCLI" -ErrorAction SilentlyContinue
   
   #64bit os fix
   if($regKeys -eq $null){
      $regKeys = Get-ItemProperty "hklm:\software\wow6432node\VMware, Inc.\VMware vSphere PowerCLI"  -ErrorAction SilentlyContinue
   }

   return $regKeys.InstallPath
}

# Loads additional snapins and their init scripts
function LoadSnapins(){
	$snapinList = @( "VMware.VimAutomation.License", "VMware.DeployAutomation", "VMware.ImageBuilder")

	$loaded = Get-PSSnapin -Name $snapinList -ErrorAction SilentlyContinue | % {$_.Name}
	$registered = Get-pssnapin -Name $snapinList -Registered -ErrorAction SilentlyContinue  | % {$_.Name}
	$notLoaded = $registered | ? {$loaded -notcontains $_}
	
   if ($notLoaded -ne $null) {
      foreach ($newlyLoaded in $notLoaded) {
         Add-PSSnapin $newlyLoaded
         
         # Load the Intitialize-<snapin_name_with_underscores>.ps1 file
         # File lookup is based on install path istead of script folder because the PowerCLI
         # shortuts load this script through dot-sourcing and script path is not available.
         $filePath = "{0}Scripts\Initialize-{1}.ps1" -f (Get-InstallPath), $newlyLoaded.ToString().Replace(".", "_")
         if (Test-Path $filePath) {
            & $filePath
         }
      }
   }
}
LoadSnapins



function CreateISO(){ 
    if (Test-Path $ExportISO)
    {
        rm -Force -r $ExportISO
    }
    echo "Add vibs bundle"
    $pkfs = get-esxsoftwarepackage
    
    #Clear the current packages before add new packages
    if ($pkfs -ne $null)
    {
        
    }
    Add-EsxSoftwareDepot $VibsBundle
    echo "Get software packages from vibs bundle and save it into a variable"
    #$pkfs = get-esxsoftwarechannel $VibsBundle | get-esxsoftwarepackage
    $pkfs = get-esxsoftwarepackage
    echo $pkfs | Out-File .\pakages.txt -width 2000
   
    echo "Add Base bundle"
    Add-EsxSoftwareDepot $BaseBundle
    echo "Create a new profile "
    $profs = Get-EsxImageProfile
    echo $profs
    $random = Get-Random
    for($i = 0 ;$i -lt $profs.Count; $i++)
    {
        if ($profs[$i].Name.contains("standard") -eq "true" )
        {
            $ip = New-EsxImageProfile -CloneProfile $profs[$i] -Name $random -Vendor "IBM"
            break
        }
    }
    
    #$ip = New-EsxImageProfile -CloneProfile $profs[3] -Name $random
         
    #echo $profs[$i].Name + " is standard profile!!!!!!!"
    echo "Add vibs software packages into the newly created bundle"
    Add-EsxSoftwarePackage -ImageProfile $ip -SoftwarePackage $pkfs
    echo "Export to a iso file"
    #export-esximageprofile -imageprofile $ip -filepath $ExportISO –exporttoiso -nosignaturecheck;
    #Export-EsxImageProfile -ImageProfile $ip -ExportToBundle -FilePath $ExportBundle -nosignaturecheck;
    export-esximageprofile -imageprofile $ip -filepath $ExportISO –exporttoiso 
    Export-EsxImageProfile -ImageProfile $ip -ExportToBundle -FilePath $ExportBundle
    #Clear software packages from vibs bundle.
    Remove-EsxSoftwarePackage -ImageProfile $ip -SoftwarePackage $pkfs
}

CreateISO
Remove-PSSnapin VMware.VimAutomation.Core
}

#'C:\temp\5.0u1 Build\bundle.zip'

#'C:\temp\5.0u1 Build\VMware-ESXi-5.0.0-528739-depot.zip'
#'C:\temp\5.0u1 Build\VMware-ESXi-5.0.0-528739.iso'