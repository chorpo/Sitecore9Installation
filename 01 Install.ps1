Import-Module SitecoreFundamentals

Import-Module SitecoreInstallFramework

#define parameters 
$prefix = "sc9u2" 
$PSScriptRoot = "C:\resourcefiles\"
$XConnectCollectionService = "$prefix.xconnect" 
$sitecoreSiteName = "$prefix.sc" 
$SolrUrl = "https://localhost:8984/solr" 
$SolrRoot = "C:\Solr\solr-6.6.2\" 
$SolrService = "Solr" 
$SqlServer = ".\" 
$SqlAdminUser = "sa" 
$SqlAdminPassword= "S1t3c0r3" 

#$solrParams = @{     
#    Path = "$PSScriptRoot\sitecore-solr.json"     
#    SolrUrl = $SolrUrl     
#    SolrRoot = $SolrRoot     
#    SolrService = $SolrService     
#    CorePrefix = $prefix 
#} 

#Install-SitecoreConfiguration @solrParams 
 
#install client certificate for xconnect 
$certParams = @{     
    Path = "$PSScriptRoot\xconnect-createcert.json"     
    CertificateName = "$prefix.xconnect_client" 
    } 
    
Install-SitecoreConfiguration @certParams -Verbose 
 
#install solr cores for xdb 
$solrParams = 
@{     
    Path = "$PSScriptRoot\xconnect-solr.json"     
    SolrUrl = $SolrUrl     
    SolrRoot = $SolrRoot     
    SolrService = $SolrService     
    CorePrefix = $prefix 
} 
Install-SitecoreConfiguration @solrParams -Verbose 
 
#deploy xconnect instance 
$xconnectParams = @{     
    Path = "$PSScriptRoot\xconnect-xp0.json"     
    Package = "$PSScriptRoot\Sitecore * (OnPrem)_xp0xconnect.scwdp.zip"     
    LicenseFile = "$PSScriptRoot\license.xml"     
    Sitename = $XConnectCollectionService     
    XConnectCert = $certParams.CertificateName     
    SqlDbPrefix = $prefix  
    SqlServer = $SqlServer  
    SqlAdminUser = $SqlAdminUser     
    SqlAdminPassword = $SqlAdminPassword     
    SolrCorePrefix = $prefix     
    SolrURL = $SolrUrl      
    } 

Install-SitecoreConfiguration @xconnectParams -Verbose 
 
#install solr cores for sitecore $solrParams = 
$solrParams = @{     
    Path = "$PSScriptRoot\sitecore-solr.json"     
    SolrUrl = $SolrUrl     
    SolrRoot = $SolrRoot     
    SolrService = $SolrService     
    CorePrefix = $prefix 
} 

Install-SitecoreConfiguration @solrParams 
 
#install sitecore instance 
$xconnectHostName = "$prefix.xconnect" 
$sitecoreParams = 
@{     
    Path = "$PSScriptRoot\sitecore-XP0.json"     
    Package = "$PSScriptRoot\Sitecore * (OnPrem)_single.scwdp.zip"  
    LicenseFile = "$PSScriptRoot\license.xml"     
    SqlDbPrefix = $prefix  
    SqlServer = $SqlServer  
    SqlAdminUser = $SqlAdminUser     
    SqlAdminPassword = $SqlAdminPassword     
    SolrCorePrefix = $prefix  
    SolrUrl = $SolrUrl     
    XConnectCert = $certParams.CertificateName     
    Sitename = $sitecoreSiteName    
    XConnectCollectionService = "https://$XConnectCollectionService"    
} 
Install-SitecoreConfiguration @sitecoreParams 