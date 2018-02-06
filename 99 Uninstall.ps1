param(
	#Website related parameters
	[string]$Prefix = 'sc9u1',
	[string]$WebsiteOhysicalRootPath = 'C:\inetpub\wwwroot\',

	#Database related parameters
	[string]$SQLInstanceName = '.\',
	[string]$SQLUsername = 'sa',
	[string]$SQLPassword = 'b',

	#Certificate related parameters
	[string]$CertificateRootStore = 'Cert:\Localmachine\Root',
	[string]$CertificatePersonalStore = 'Cert:\Localmachine\My',
	[string]$XConnectCertName = "$Prefix.xconnect",
	[string]$XConnectClientCertName = "$Prefix.xconnect_client",
	[string]$SitecoreRootCertName = 'DO_NOT_TRUST_SitecoreRootCert',
	[string]$SitecoreFundamentalsRootCertName = 'DO_NOT_TRUST_SitecoreFundamentalsRoot',
	[string]$CertPath = 'C:\Certificates',
	
	#Solr related parameters
	[string]$SolrPath = 'C:\Solr\solr-6.6.2\'

)

$XConnectWebsiteName = "$Prefix.xconnect"
$SitecoreWebsiteName = "$Prefix.sc"
$XConnectWebsitePhysicalPath = "$WebsiteOhysicalRootPath$Prefix.xconnect"
$SitecoreWebsitePhysicalPath = "$WebsiteOhysicalRootPath$Prefix.sc"
$HostFileLocation = "c:\windows\system32\drivers\etc\hosts"
$MarketingAutomationService = "$Prefix.xconnect-MarketingAutomationService"
$IndexWorker = "$Prefix.xconnect-IndexWorker"

Write-Host -foregroundcolor Green  "Starting Sitecore 9 instance removal..."

#Remove Sitecore website
if([bool](Get-Website $SitecoreWebsiteName)) {
	Write-host -foregroundcolor Green "Deleting Website $SitecoreWebsiteName"
	Remove-WebSite -Name $SitecoreWebsiteName
	Write-host -foregroundcolor Green "Deleting App Pool $SitecoreWebsiteName"
	Remove-WebAppPool $SitecoreWebsiteName
}
else {
	Write-host -foregroundcolor Red "Website $SitecoreWebsiteName does not exists."
}

#Remove XConnect website
if([bool](Get-Website $XConnectWebsiteName)) {
	Write-host -foregroundcolor Green "Deleting Website $XConnectWebsiteName"
	Remove-WebSite -Name $XConnectWebsiteName
	Write-host -foregroundcolor Green "Deleting App Pool $XConnectWebsiteName"
	Remove-WebAppPool $XConnectWebsiteName
}
else {
	Write-host -foregroundcolor Red "Website $XConnectWebsiteName does not exists."
}

#Remove hosts entries
if([bool]((get-content $HostFileLocation) -match $Prefix)) {
Write-Host -foregroundcolor Green  "Deleting hosts entires."
(get-content $HostFileLocation) -notmatch $Prefix | Out-File $HostFileLocation
}
else {
	Write-Host -foregroundcolor Red  "No hosts entires found."
}

#Stop and remove maengine
Get-WmiObject -Class Win32_Service -Filter "Name='$MarketingAutomationService'" | Remove-WmiObject

$Service = Get-WmiObject -Class Win32_Service -Filter "Name='$MarketingAutomationService'"
if($Service) {
	Get-Process -Name "maengine" | Stop-Process -Force
	Write-Host -foregroundcolor Green  "Deleting " $MarketingAutomationService
	$Service.StopService()
	$Service.delete()
}
else {
	Write-Host -foregroundcolor Red  $MarketingAutomationService " service does not exists."
}

$Service = Get-WmiObject -Class Win32_Service -Filter "Name='$IndexWorker'"
if($Service) {
	Write-Host -foregroundcolor Green  "Deleting " $IndexWorker
	$Service.StopService()
	$Service.delete()
}
else {
	Write-Host -foregroundcolor Red  $IndexWorker " service does not exists."
}

#Remove Sitecore Files
if (Test-Path $SitecoreWebsitePhysicalPath) { 
     
Remove-Item -path $SitecoreWebsitePhysicalPath\* -recurse 
Remove-Item -path $SitecoreWebsitePhysicalPath 
Write-host -foregroundcolor Green $SitecoreWebsitePhysicalPath " Deleted" 
[System.Threading.Thread]::Sleep(1500) 
 
} else { 
 
Write-host -foregroundcolor Red  $SitecoreWebsitePhysicalPath  " Does not exist" 
 
} 

#Remove XConnect files
if (Test-Path $XConnectWebsitePhysicalPath) { 
     
Remove-Item -path $XConnectWebsitePhysicalPath\* -recurse -Force -ErrorAction SilentlyContinue
Remove-Item -path $XConnectWebsitePhysicalPath -Force
Write-host -foregroundcolor Green $XConnectWebsitePhysicalPath " Deleted" 
[System.Threading.Thread]::Sleep(1500) 
 
} else { 
 
Write-host -foregroundcolor Red  $XConnectWebsitePhysicalPath  " Does not exist" 
}

#Remove SQL Databases
import-module sqlps 
$DBListQuery = "select * from sys.databases where Name like '" + $Prefix + "_%';"
$DBList = invoke-sqlcmd -ServerInstance ".\$SQLInstanceName" -U "$SQLUsername" -P "$SQLPassword" -Query $DBListQuery 
ForEach($DB in $DBList) {
	Write-host -foregroundcolor Green "Deleting Database " $DB.Name 
	$AlterQuery = "ALTER DATABASE [" + $DB.Name + "] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;"
	$DropQuery = "DROP DATABASE [" + $DB.Name + "];"
	invoke-sqlcmd -ServerInstance ".\$SQLInstanceName" -U "$SQLUsername" -P "$SQLPassword" -Query $AlterQuery
	invoke-sqlcmd -ServerInstance ".\$SQLInstanceName" -U "$SQLUsername" -P "$SQLPassword" -Query $DropQuery
}

#Remove Certificates
if([bool](Get-ChildItem -Path $CertificateRootStore -dnsname $SitecoreRootCertName)) {
	Write-host -foregroundcolor Green "Deleting certificate " $SitecoreRootCertName
	Get-ChildItem -Path $CertificateRootStore -dnsname $SitecoreRootCertName | Remove-Item
}
else {
	Write-host -foregroundcolor Red "Certificate " $SitecoreRootCertName " does not exists."
}

if([bool](Get-ChildItem -Path $CertificateRootStore -dnsname $SitecoreFundamentalsRootCertName)) {
	Write-host -foregroundcolor Green "Deleting certificate " $SitecoreFundamentalsRootCertName
	Get-ChildItem -Path $CertificateRootStore -dnsname $SitecoreFundamentalsRootCertName | Remove-Item
}
else {
	Write-host -foregroundcolor Red "Certificate " $SitecoreFundamentalsRootCertName " does not exists."
}

if([bool](Get-ChildItem -Path $CertificatePersonalStore -dnsname $XConnectCertName)) {
	Write-host -foregroundcolor Green "Deleting certificate " $XConnectCertName
	Get-ChildItem -Path $CertificatePersonalStore -dnsname $XConnectCertName | Remove-Item
}
else {
	Write-host -foregroundcolor Red "Certificate " $XConnectCertName " does not exists."
}

if([bool](Get-ChildItem -Path $CertificatePersonalStore -dnsname $XConnectClientCertName)) {
	Write-host -foregroundcolor Green "Deleting certificate " $XConnectClientCertName
	Get-ChildItem -Path $CertificatePersonalStore -dnsname $XConnectClientCertName | Remove-Item
}
else {
	Write-host -foregroundcolor Red "Certificate " $XConnectClientCertName " does not exists."
}

if (Test-Path $CertPath) {      
	Remove-Item -path $CertPath\* -recurse 
	Remove-Item -path $CertPath 
	Write-host -foregroundcolor Green $CertPath " Deleted" 
	[System.Threading.Thread]::Sleep(1500) 
 
} else {  
	Write-host -foregroundcolor Red  $CertPath  " Does not exist" 
}

# Remove Solr Cores
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_core_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_fxm_master_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_fxm_web_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_marketing_asset_index_master")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_marketing_asset_index_web")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_marketingdefinitions_master")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_marketingdefinitions_web")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_suggested_test_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_testing_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_web_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_master_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_xdb")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_xdb_rebuild")

Write-Host -foregroundcolor Green "Finished Sitecore 9 instance removal..."