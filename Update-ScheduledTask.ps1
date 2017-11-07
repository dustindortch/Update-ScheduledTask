[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [ValidateScript({Get-ScheduledTask $_})]
    [String]$ScheduledTask
)

$XML = [xml](Get-ScheduledTask $ScheduledTask | Export-ScheduledTask)
$Namespace = "http://schemas.microsoft.com/windows/2004/02/mit/task"
$EventTriggers = $XML.Task.Triggers.EventTrigger
Write-Verbose "TYPE: $($EventTriggers.GetType())"
if (!$EventTriggers.ValueQueries) {
    $ValueQueriesNode = $XML.CreateElement("ValueQueries",$Namespace)
    $ValueQueries = $EventTriggers.AppendChild($ValueQueriesNode)
}
Write-Verbose "TYPE: $($ValueQueries.GetType())"
if (!$ValueQueries.Value)
{
    $ValueLogName = $XML.CreateElement("Value",$Namespace)
    $ValueLogName.SetAttribute('name','LogName')
    $ValueLogName.Set_InnerXML("Event/System/Channel")
    $ValueQueries.AppendChild($ValueLogName)
    $ValueIndex = $XML.CreateElement("Value",$Namespace)
    $ValueIndex.SetAttribute('name','Index')
    $ValueIndex.Set_InnerXML("Event/System/EventRecordID")
    $ValueQueries.AppendChild($ValueIndex)
}

$Exec = $XML.Task.Actions.Exec
Write-Verbose "TYPE: $($Exec.GetType())"
$Exec.Arguments = "-File $($Exec.Arguments) -LogName ""`$`(LogName`)"" -Index ""`$`(Index`)"""

Unregister-ScheduledTask $ScheduledTask -Confirm:$False
Register-ScheduledTask -Xml "$($XML.Get_OuterXML())" -TaskName "$($ScheduledTask)"

<#
Task/Triggers/EventTrigger
<ValueQueries>
    <Value name="LogName">Event/System/Channel</Value>
    <Value name="Index">Event/System/EventRecordID</Value>
</ValueQueries>

Task/Actions/Exec
<Arguments>-File .\Test-Trigger.ps1 -LogName "$(LogName)" -Index "$(Index)"</Arguments>
#>