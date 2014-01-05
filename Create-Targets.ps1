# Created by Tridion.Zen

# define new target types (doeltypen)
$AliveWebTT = new-object psobject -Property @{ 
    title="A live web";    description="live web";    tcmId=""; }
$AstagWebTT = new-object psobject -Property @{ 
    title="A staging web"; description="staging web"; tcmId=""; }
$newATypes = @($AliveWebTT, $AstagWebTT)
# define new publication targets (publicatiedoelen)
$AliveWebPT = new-object psobject -Property @{ 
    title="A live web";    description="live web";    tcmId=""; target=$AliveWebTT;
	dest1="SERVER A"; uid1="?"; pwd1="?"; url1="http://SERVER:803/httpupload.aspx";
	dest2="";           uid2="";  pwd2="";  url2="" }
$AstagWebPT = new-object psobject -Property @{ 
    title="A staging web"; description="staging web"; tcmId=""; target=$AstagWebTT;
    dest1="SERVER B"; uid1="?"; pwd1="?"; url1="http://SERVER:804/httpupload.aspx";
    dest2="SERVER C";  uid2="?"; pwd2="?"; url2="http://SERVER_C:804/httpupload.aspx" }
$newATargets = @($AliveWebPT, $AstagWebPT)
#
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$admin = "DOMAIN\USER"
if ($user -ne $admin) {
	write-host "SDL Tridion 2011 SP1 must be installed by:" $admin -foregroundcolor red
	write-host "This script must be run as:" $admin  -foregroundcolor red
	return
}
#
clear-host
write-host "Loading DLL's..."
[appdomain]::CurrentDomain.SetData("APP_CONFIG_FILE", "$env:TRIDION_HOME\config\Tridion.ContentManager.config")
get-childitem "$env:TRIDION_HOME\bin\client\*.*" -Include *.dll | foreach { add-type -path $_.fullname }
#
write-host "Creating TOM.NET Session..."
$session = new-object Tridion.ContentManager.Session
#
write-host "Reading target-types and publication targets..."
#
$filter = new-object Tridion.ContentManager.CommunicationManagement.TargetTypesFilter($session)
$xml = $session.GetList($filter)
$types = $xml.item
# cache targettype titles
$oldTypes = @()
foreach ($type in $types) {
    $oldTypes += $type.title
}
# cache targettype id's
foreach ($type in $types) {
	$title = $type.title
	foreach ($todo in $newATypes) {
		if ($todo.title -eq $title) {
			$todo.tcmId = $type.id
		}
	}
}
# report target types
write-host " Current Target Types:                   " -backgroundcolor white -foregroundcolor black
foreach ($type in $types) {
    write-host $type.id "| " -nonewline
    write-host $type.title   -nonewline -foregroundcolor blue -backgroundcolor cyan
    write-host " | "         -nonewline
     
    $infos = $session.GetObject($type.id)
    foreach ($info in $infos.AccessControlList.AccessControlEntries) { 
        foreach ($trustee in $info.Trustee) {
            write-host $trustee.title -nonewline -foregroundcolor gray
            write-host "; "           -nonewline
        }
    }
    write-host
}
write-host
#
$filter = new-object Tridion.ContentManager.CommunicationManagement.PublicationTargetsFilter($session)
$xml = $session.GetList($filter)
$targets = $xml.item
# cache publicationtarget titles
$oldTargets = @()
foreach ($target in $targets) {
    $oldTargets += $target.title
}
# cache publicationtarget id's
foreach ($target in $targets) {
	$title = $target.title
	foreach ($todo in $newATargets) {
		if ($todo.title -eq $title) {
			$todo.tcmId = $type.id
		}
	}
}
# report publication targets
write-host " Current Publication Targets:            " -backgroundcolor white -foregroundcolor black
foreach ($target in $targets) {
    write-host $target.id "| " -nonewline
    write-host $target.title   -nonewline -foregroundcolor cyan 
    write-host " | "           -nonewline

    $infos = $session.GetObject($target.id)
    write-host $infos.TargetLanguage -nonewline -foregroundcolor yellow
    write-host " | "                 -nonewline
    write-host $infos.DefaultCodePage -nonewline -foregroundcolor green
    write-host " | "                  -nonewline 
    write-host $infos.MinApprovalStatus -nonewline -foregroundcolor yellow
    write-host " | "                    -nonewline
    write-host $infos.Priority -nonewline -foregroundcolor green
    write-host " | "           -nonewline 
    foreach ($pub in $infos.Publications) {
        write-host $pub.id -nonewline -foregroundcolor magenta
        write-host " | "    -nonewline 
    }
    foreach ($type in $infos.TargetTypes) {
        write-host $type.title -nonewline -foregroundcolor blue -backgroundcolor cyan
        write-host " | "      -nonewline
    }
    foreach ($dest in $infos.Destinations) {     
        write-host $dest.title -nonewline -foregroundcolor yellow -backgroundcolor gray
        write-host " | " -nonewline
        write-host $dest.Protocol.title -nonewline -foregroundcolor red -backgroundcolor gray
        write-host " | " -nonewline
        $fields = $dest.ProtocolFields.OuterXml
        $fields = $fields -replace "`n", ""
        $fields = $fields -replace '\s+', ""
        write-host $fields -nonewline -foregroundcolor green -backgroundcolor gray
        write-host " | " 
    }    
    write-host
}
# start of functions
function createTargetType ($type) { 
	$temp = new-object Tridion.ContentManager.CommunicationManagement.TargetType($session)
	$temp.Title = $type.title
	$temp.Description = $type.description
	$temp.Save()
	$type.tcmId = $temp.Id
	write-host $temp.Title               -nonewline -foregroundcolor yellow
	write-host " : is gemaakt met id : " -nonewline
	write-host $type.tcmId                          -foregroundcolor yellow
}
#
function createPublicationTarget ($target) {
	$protocolSchema = new-object Tridion.Contentmanager.ContentManagement.Schema("tcm:0-55187-8", $session)
	$dom = new-object System.Xml.XmlDocument
	$ns  = new-object System.Xml.XmlNamespaceManager($dom.Nametable)
	$ns.AddNamespace("tcm", "http://www.tridion.com/ContentManager/5.0/Protocol/HTTPS")	
	$user1 = $dom.CreateElement("UserName", "http://www.tridion.com/ContentManager/5.0/Protocol/HTTPS")
	$pass1 = $dom.CreateElement("Password", "http://www.tridion.com/ContentManager/5.0/Protocol/HTTPS")
	$URL1  = $dom.CreateElement("URL", "http://www.tridion.com/ContentManager/5.0/Protocol/HTTPS")
	$user1.InnerText = $target.uid1
	$pass1.InnerText = $target.pwd1	
	$URL1.InnerText  = $target.url1	
	$protocolData1 = $dom.CreateElement("HTTPS", "http://www.tridion.com/ContentManager/5.0/Protocol/HTTPS")
	$protocolData1.AppendChild($user1) | out-null
	$protocolData1.AppendChild($pass1) | out-null
	$protocolData1.AppendChild($URL1)  | out-null
	$destination1 = new-object Tridion.ContentManager.Communicationmanagement.Destination($target.dest1, $protocolSchema, $protocolData1)
	# $destination2 = new-object Tridion.ContentManager.Communicationmanagement.Destination($target.dest2, $protocolSchema, $protocolData2)
	$temp = new-object Tridion.ContentManager.CommunicationManagement.PublicationTarget($session)
	$temp.Destinations.Add($destination1)
	# $temp.Destinations.Add($destination2)
	$temp.Title = $target.title
	$temp.Description = $target.description
	$temp.Save()	
	$target.tcmId = $temp.Id
	write-host $temp.Title               -nonewline -foregroundcolor yellow
	write-host " : is gemaakt met id : " -nonewline
	write-host $target.tcmId                        -foregroundcolor yellow
}
# make new target types?
write-host " Creating Target Types?                  " -backgroundcolor white -foregroundcolor black
foreach ($type in $newATypes) {
	$title = $type.title
    if ($oldTypes -contains $title) {
		write-host $title                         -nonewline -foregroundcolor green
		write-host " : bestaat al en heeft id : " -nonewline
		write-host $type.tcmId                               -foregroundcolor green
	} else {
        write-host $title                              -nonewline -foregroundcolor red
		write-host " : ontbreekt en wordt gemaakt : "  -nonewline
		createTargetType $type
	}
}
# make new publication targets?
write-host " Creating Publication Targets?            " -backgroundcolor white -foregroundcolor black
foreach ($target in $newATargets) {
	$title = $target.title
    if ($oldTargets -contains $title) {
		write-host $title                         -nonewline -foregroundcolor green
		write-host " : bestaat al en heeft id : " -nonewline
		write-host $target.tcmId
	} else {
        write-host $title                              -nonewline -foregroundcolor red
		write-host " : ontbreekt en wordt gemaakt : "  -nonewline
		createPublicationTarget $target
	}
}

#
$session.Dispose()
$session = $null
