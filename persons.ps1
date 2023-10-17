$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"


$config = ConvertFrom-Json $configuration
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

if($config.IncludeStatuses.length -gt 0) {
    $statusIncluded = $config.IncludeStatuses -split ','
}

if($config.ExcludeShifts.length -gt 0) {
    $shiftsExcluded = $config.ExcludeShifts -split ','
}


$headers = [System.Collections.Generic.Dictionary[[String],[String]]]::new()
$headers.Add("Authorization", "ApplicationKey $($config.ApplicationKey)")


function Get-ObjectProperties 
{
    param ($Object, $Depth = 0, $MaxDepth = 10)
    $OutObject = @{};

    foreach($prop in $Object.PSObject.properties)
    {
        if ($prop.TypeNameOfValue -eq "System.Management.Automation.PSCustomObject" -or $prop.TypeNameOfValue -eq "System.Object" -and $Depth -lt $MaxDepth)
        {
            $OutObject[$prop.Name] = Get-ObjectProperties -Object $prop.Value -Depth ($Depth + 1);
        }
        elseif ($prop.TypeNameOfValue -eq "System.Object[]") 
        {
            $OutObject[$prop.Name] = [System.Collections.ArrayList]@()
            foreach($item in $prop.Value)
            {
                $OutObject[$prop.Name].Add($item)
            }
        }
        else
        {
            $OutObject[$prop.Name] = "$($prop.Value)"
        }
    }
    return $OutObject;
}

#Shift Data
$total = 0;
$i = 0;
$shiftData = [System.Collections.Generic.List[PSCustomObject]]::new()
while($true) {
    $parameters = @{
        '$top' = [int]$config.PageSize
        '$skip' = $i
        '$count' = 'true'
    }
    #Write-Verbose -Verbose "$($i):$($total)"
    $response = Invoke-RestMethod "$($config.BaseURI)/ds/campusnexus/Shifts" -Method 'GET' -Headers $headers -Body $parameters
    $total = $response.'@odata.count'
    foreach($item in $response.value) {
        $i++
        $shiftData.Add($item)
    }

    Write-Verbose -Verbose "Shifts -- $($i):$($total)"
    if($i -ge $total) { break }

}

#Withdrawal Data
$total = 0;
$i = 0;
$withdrawalData = [System.Collections.Generic.List[PSCustomObject]]::new()
while($true) {
    $parameters = @{
        '$top' = [int]$config.PageSize
        '$skip' = $i
        '$count' = 'true'
        '$select' = 'EnrollmentDate,EnrollmentNumber,GraduationDate,Id,NsldsWithdrawalDate,ProgramVersionName,SchoolStatusChangeDate'
        '$expand' = 'Student($select=StudentNumber,FullName,Id),SchoolStatus($select=Code,Name,Id)'
        '$filter' = "SchoolStatus/Code eq 'WITHAD' or SchoolStatus/Code eq 'SUSPD' or SchoolStatus/Code eq 'SUSP' or SchoolStatus/Code eq 'LOAP' or SchoolStatus/Code eq 'DROP'"
    }
    #Write-Verbose -Verbose "$($i):$($total)"
    $response = Invoke-RestMethod "$($config.BaseURI)/ds/odata/StudentEnrollmentPeriods" -Method 'GET' -Headers $headers -Body $parameters
    $total = $response.'@odata.count'
    foreach($item in $response.value) {
        $i++
        $withdrawalData.Add($item)
    }

    Write-Verbose -Verbose "Withdrawals -- $($i):$($total)"
    if($i -ge $total) { break }

}

#Demographic Data
$total = 0;
$i = 0;
$results = [System.Collections.Generic.List[PSCustomObject]]::new()
while($true) {
    $parameters = @{
        '$top' = [int]$config.PageSize
        '$skip' = $i
        '$count' = 'true'
        '$select' = $config.StudentFields
    }
    #Write-Verbose -Verbose "$($i):$($total)"
    $response = Invoke-RestMethod "$($config.BaseURI)/ds/campusnexus/Students" -Method 'GET' -Headers $headers -Body $parameters
    $total = $response.'@odata.count'
    foreach($item in $response.value) {
        $i++
        $results.Add($item)
    }

    Write-Verbose -Verbose "Students -- $($i):$($total)"
    if($i -ge $total) { break }

}

#Grad Status
$total = 0;
$i = 0;
$gradResults = [System.Collections.Generic.List[PSCustomObject]]::new()
while($true) {
    $parameters = @{
        '$top' = [int]$config.PageSize
        '$skip' = $i
        '$count' = 'true'
        '$select' = 'EnrollmentDate,EnrollmentNumber,GraduationDate,Id,NsldsWithdrawalDate,ProgramVersionName,SchoolStatusChangeDate'
        '$expand' = 'Student($select=StudentNumber,FullName,Id),SchoolStatus($select=Code,Name,Id)'
        '$filter' = "SchoolStatus/Code eq 'GRAD'"
    }
    #Write-Verbose -Verbose "$($i):$($total)"
    $response = Invoke-RestMethod "$($config.BaseURI)/ds/odata/StudentEnrollmentPeriods" -Method 'GET' -Headers $headers -Body $parameters
    $total = $response.'@odata.count'
    foreach($item in $response.value) {
        $i++
        $gradResults.Add($item)
    }

    Write-Verbose -Verbose "Graduation Data -- $($i):$($total)"
    if($i -ge $total) { break }

}
 
$gradResultsHT = $gradResults | Select-Object *, @{Name='Key';Expression={$_.Student.StudentNumber}} | Group-Object Key -AsHashTable -AsString
$withdrawalResultsHT = $withdrawalData | Select-Object *, @{Name='Key';Expression={$_.Student.StudentNumber}} | Group-Object Key -AsHashTable -AsString
$shiftDataHT = $shiftData | Select-Object *, @{Name='Key';Expression={$_.ID}} | Group-Object Key -AsHashTable -AsString

foreach($result in $results) {
    if($null -ne $statusIncluded) {
        if($statusIncluded -notcontains $result.SchoolStatusId) { continue; }
    }

    if($null -ne $shiftsExcluded) {
        if( $shiftsExcluded -contains $result.ShiftId) { continue; }
    }
    
    $person = @{};
        
    $person.ExternalId = $result.StudentNumber;
    $person.DisplayName = "$($result.FirstName) $($result.LastName) ($($person.ExternalId))";
        
    foreach($prop in $result.PSObject.properties)
    {
        $person[$prop.Name] = "$($prop.Value)";
    }

    $person["ShiftCode"] = $shiftDataHT[[string]$result.ShiftId].Code;
    $person["ShiftDescription"] = $shiftDataHT[[string]$result.ShiftId].Description;
    $person["ShiftActive"] = $shiftDataHT[[string]$result.ShiftId].Active;

    $person.Contracts = [System.Collections.ArrayList]@();
    
    #Non-Graduates
    if($gradResultsHT[$result.StudentNumber].count -lt 1 -and $withdrawalResultsHT[$result.StudentNumber].count -lt 1) {
        $contract = @{
                        ExternalID = "$($result.StudentNumber).$($result.SchoolStatusId)"
                        SchoolStatusId = $result.SchoolStatusId
                        Type = "CurrentEnrollment"
                        SequenceOrder = 0 
        }
        [void]$person.Contracts.Add($contract);
    }
    
     #Graduates
    foreach($item in $gradResultsHT[$result.StudentNumber]) {
            $contract = @{
                    ExternalID = "$($result.StudentNumber).Grad.$($item.EnrollmentNumber)"
                    SchoolStatusId = $item.SchoolStatus.Id
                    SEP_EnrollmentDate = $item.EnrollmentDate
                    SEP_EnrollmentNumber = $item.EnrollmentNumber
                    SEP_ProgramVersionName = $item.ProgramVersionName
                    SEP_GraduationDate = $item.GraduationDate
                    SEP_SchoolStatusCode = $item.SchoolStatus.Code
                    SEP_ChangeDate = $item.SchoolStatusChangeDate
                    SEP_NsldsWithdrawalDate = ''
                    Type = "Graduation"
                    SequenceOrder = 2
            }
            [void]$person.Contracts.Add($contract);
            

    }

    #Withdrawals
    foreach($item in $withdrawalResultsHT[$result.StudentNumber]) {
            $contract = @{
                    ExternalID = "$($result.StudentNumber).Grad.$($item.EnrollmentNumber)"
                    SchoolStatusId = $item.SchoolStatus.Id
                    SEP_EnrollmentDate = $item.EnrollmentDate
                    SEP_EnrollmentNumber = $item.EnrollmentNumber
                    SEP_ProgramVersionName = $item.ProgramVersionName
                    SEP_GraduationDate = $item.GraduationDate
                    SEP_SchoolStatusCode = $item.SchoolStatus.Code
                    SEP_ChangeDate = $item.SchoolStatusChangeDate
                    SEP_NsldsWithdrawalDate = $item.NsldsWithdrawalDate
                    Type = $item.SchoolStatus.Name
                    SequenceOrder = 1
            }
            [void]$person.Contracts.Add($contract);
            

    }
    
    Write-Output ($person | ConvertTo-Json -Depth 10);
}
