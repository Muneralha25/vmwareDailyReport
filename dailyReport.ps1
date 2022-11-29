Import-module VMware.VimAutomation.Core

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | Out-Null



$rootPasswordPRD = get-VICredentialStoreItem -Host 'vcenter-nameblablabla' -User 'administrator@vsphere.local' 


Connect-VIServer -Server 'vcenter-nameblablabla' -User 'administrator@vsphere.local' -Password $rootPasswordPRD.Password -WarningAction SilentlyContinue;



$Date = get-date 
$Datefile = ( get-date ).ToString(‘yyyyMMdd’) 
# Variable to change 
#$CreateCSV= "yes" 
#$GridView = "yes" 
$HTML = "yes" 
$DisplayHTMLOnScreen = "no"
$EmailHTML = "yes"
$SendEmail = "no"
$EmailFrom = "OCVS-INFRA_Daily_Report@emailCompany"
$EmailTo = 'seuemail'
$EmailSubject = "OCVS INFRA Daily Report - Company -$Datefile" 
$EmailSMTP = "SMTP Relay" 
$FileHTML = New-Item -Force -ItemType file "C:\RVTOOLS_REPORTS\OCVS-INFRA-REPORTS\OCVS-INFRA-REPORT_$datefile.html"


#$FileCSV = New-Item -Force -ItemType file "D:\temo\VMInfo_$datefile.csv"

#Add Text to the HTML file 
Function Create-HTMLTable 
{ 
param([array]$Array) 
$arrHTML = $Array | ConvertTo-Html 
$arrHTML[-1] = $arrHTML[-1].ToString().Replace(‘</body></html>’,"") 
Return $arrHTML[5..2000] 
}

$output = @() 
$output += ‘<html><head></head><body>’ 
$output +=  
‘<style>table{border-style:solid;border-width:1px;font-size:8pt;background-color:#ccc;width:100%;}th{text-align:left;}td{background-color:#fff;width:20%;border-style:so 
lid;border-width:1px;}body{font-family:verdana;font-size:12pt;}h1{font-size:12pt;}h2{font-size:10pt;}</style>’ 
$output += ‘<center><H3>OCVS INFRA Daily Report - Renner </H3></center>’ 
$output += ‘<p style="text-align:right;"></p>’, $Date
$output += ‘<br>‘
$output += ‘<br>‘
$output += ‘<br>‘


#Gathering VM settings 


$ReportHost = get-vmhost * | where-object { $_.ConnectionState -notlike "*Connected*"} | select name, Parent
$ReportSnaphost = Get-VM | Get-Snapshot | select VM, Name, Created | sort Created
$ReportDatastoreFree = Get-Datastore | ? type -eq 'vsan' | select  DatastoreBrowserPath, CapacityGB, FreeSpaceGB, @{N="Free %";E={[math]::Round(($_.FreeSpaceGB)/($_.CapacityGB)*100,2)}}
$ReportDRS =  get-cluster | select Name, HAEnabled, DRSEnabled, uid
$ReportVMsoff = get-vm |Where-object {$_.powerstate -eq "poweredoff" } | select Name | Sort name

$countpoweroff = 0
$countpoweroff = (get-vm |Where-object {($_.powerstate -eq "poweredoff")}).Count

$countHostESXiUp = (get-vmhost | ? {($_.ConnectionState -eq "Connected" -and $_.Name -notlike "10*")}).count
$vCsession = $global:DefaultVIServers |select Name, isConnected, version, Build




if ($HTML -eq "yes") { 
$output += ‘<p>’ 
$output += ‘<H1><center>0.Status vCenters Connectivity (up)</center></H1>’ 
$output += ‘<p>’ 
$output += Create-HTMLTable $VCsession
$output += ‘</p>’ 
$output += ‘</body></html>’ 
$output | Out-File $FileHTML }

    

    
       
    
if (!$ReportHost) 
    {
        if ($HTML -eq "yes") { 
$output += ‘<p>’ 
$output += ‘<H1><center>1.Hosts Disconnected or Maintenance State</center></H1>'
$output += ‘<p>’ 
$output += ‘<p>’ 
$output += '<mark>OK !! All Hosts Connected --></mark>' 
$output +=  $countHostESXiUp 
 
$output += ‘</p>’ 
$output += Create-HTMLTable
$output += ‘</body></html>’ 
$output | Out-File $FileHTML }

    }
        
    
    else
    {
    

if ($HTML -eq "yes") { 
$output += ‘<p>’ 
$output += ‘<H1><center>1.Hosts Disconnected or Maintenance State</center></H1>’ 
$output += ‘<p>’ 
$output += Create-HTMLTable $ReportHost
$output += ‘</p>’ 
$output += ‘</body></html>’ 
$output | Out-File $FileHTML }

    }

if ($DisplayHTMLOnScreen -eq "yes") { 
ii $FileHTML}


if ($HTML -eq "yes") { 
$output += ‘<p>’ 
$output += ‘<H1><center>2.Snapshots Active </center></H1>’ 
$output += ‘<p>’ 
$output += Create-HTMLTable $reportSnaphost 
$output += ‘</p>’ 
$output += ‘</body></html>’ 
$output | Out-File $FileHTML }

if ($DisplayHTMLOnScreen -eq "yes") { 
ii $FileHTML}


if ($HTML -eq "yes") { 
$output += ‘<p>’ 
$output += ‘<H1><center>3. Cluster Feature --> DRS & HA Status Enabled</center></H1>’ 
$output += ‘<p>’ 
$output += Create-HTMLTable $ReportDRS 
$output += ‘</p>’ 
$output += ‘</body></html>’ 
$output | Out-File $FileHTML }


if ($HTML -eq "yes") { 
$output += ‘<p>’ 
$output += ‘<H1><center>4. FreeSpace vSAN</center></H1>’ 
$output += ‘<p>’ 
$output += Create-HTMLTable $ReportDatastoreFree
$output += ‘</p>’ 
$output += ‘</body></html>’ 
$output | Out-File $FileHTML }




if ($HTML -eq "yes") { 
$output += ‘<p>’ 
$output += ‘<H1><center>5. VMs Powered Off List </center></H1>’ 
$output += ‘<p>’ 
$output += Create-HTMLTable $ReportVMsoff 
$output += ‘</p>’ 
$output += ‘</body></html>’ 
$output | Out-File $FileHTML }

if ($HTML -eq "yes") { 
$output += ‘<p>’ 
$output += ‘VMs Powered Off’,$countpoweroff
$output += ‘<p>’
$output += ‘</body></html>’ 
$output | Out-File $FileHTML }

if ($DisplayHTMLOnScreen -eq "yes") { 
ii $FileHTML}

if ($SendEmail -eq "yes") { 

Send-MailMessage –From $EmailFrom –To $EmailTo –Subject $EmailSubject -Body "$FileHTML" -BodyAsHtml –SmtpServer $EmailSMTP }
#Send-MailMessage –From $EmailFrom –To $EmailTo –Subject $EmailSubject -Body "$FileHTML" -BodyAsHtml –SmtpServer $EmailSMTP -Attachments $FileHTML }


#Disconnect session from VC 
Disconnect-VIServer -Server * -Confirm:$false -Force
#>
