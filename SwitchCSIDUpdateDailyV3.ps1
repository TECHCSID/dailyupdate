#####################################################
######## PASSAGE GUPDATE EN MAJ JOURNALIERE #########
#####################################################

# Paramètres
$configFilename = 'genserv.exe.config';
$starttime = "18:00";

# Récupération du path CSID Update
$csidUpdatePath = Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\CSiD\CSiDUpdate | Select-Object -ExpandProperty InstallLocation;

# Lecture du fichier XML de configuration du GUpdate
$completeFilePath = Join-Path -Path $csidUpdatePath -ChildPath $configFilename;

# Est ce que le fichier est présent ?
if (Test-Path -Path $completeFilePath) {
    Write-Host "Fichier de configuration du GU trouvé à cet emplacement : $completeFilePath";

    [XML] $configXml = Get-Content -Path $completeFilePath -ErrorAction 'Stop';
    # Est ce que le contenu du fichier est bien en XML ?
    if ($null -ne $configXml) {
        $launchDailies = $configXml.SelectNodes("//Launch[starts-with(@schedule,'Journali')]");

        foreach ($launchDaily in $launchDailies) {
            $launchDaily.ParentNode.RemoveChild($launchDaily);
        }
        $configXml.Save($completeFilePath);
        
        Write-Host "Démarage de la modification du fichier de configuration";

        $launchConfig = $configXml.SelectSingleNode("/Parameters/Launch[@schedule='Hebdomadaire']");

        # Est ce qu'il y a bien une configuration ?
        if ($null -ne $launchConfig) {
            $login = $launchConfig.login;
            $password = $launchConfig.password;
            $application = Join-Path -Path $csidUpdatePath -ChildPath 'genapiupdate.exe';

            # Création de l'entrée "Journalière"
            $newLaunchXML = $configXml.Parameters.AppendChild($configXml.CreateElement("Launch"));

            if (![String]::IsNullOrEmpty($login)) {
                $newLaunchXML.SetAttribute("login", $login);
            }
            if (![String]::IsNullOrEmpty($password)) {
                $newLaunchXML.SetAttribute("password", $password);
            }
            $guid = [guid]::newguid();
            $newLaunchXML.SetAttribute("id", "{" + $guid.ToString().ToUpper() + "}");

            $newLaunchXML.SetAttribute("application", $application);
            $newLaunchXML.SetAttribute("schedule", "Journalière");
            $newLaunchXML.SetAttribute("argument", "/AUTO");
            $newLaunchXML.SetAttribute("lastaccessed", "");
            $newLaunchXML.SetAttribute("startTime", $starttime);
            $newLaunchXML.SetAttribute("times", "1");
            $newLaunchXML.SetAttribute("workingDay", "Faux");
            $newLaunchXML.SetAttribute("lasttimeaccessed", "");

            # Sauvegarde du fichier modifié
            $configXml.Save($completeFilePath);

            Write-Host "Fin de la modification du fichier de configuration";
        }
        else {
            Write-Host "Le fichier de configuration n'a pas de configuration hebdomadaire, intervention manuelle nécessaire.";
        }
    }
    else {
        Write-Host "Le fichier de configuration n'a pas le bon format, intervention manuelle nécessaire.";
    }
}
else {
    Write-Host "Le fichier $completeFilePath n'existe pas, intervention manuelle nécessaire."
}
