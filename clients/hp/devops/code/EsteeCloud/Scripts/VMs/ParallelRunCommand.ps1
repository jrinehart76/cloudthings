param (
    [string[]]$SubscriptionNames,
    [string]$ResourceGroupName
)

# Functions for multi-line output parsing, because RunCommand
function Parse-StdOut($message) {
    $lines = $message.Split("\n")
    if($lines.Count -lt 1) {
        Write-Output "No multi-line output found."
        return
    }
    $output = ""
    $stdOutput = $false
    
    foreach($line in $lines){
        
        if($line -like "[stdout]*"){
            $stdOutput = true
        }
        if($line -like "[stderr]*"){
            # pass through
        }
        if($stdOutput -eq $true) {
            $output += $line
        }
    }

    return $output
}

function Parse-StdErr($message) {
    $lines = $message.Split("\n")
    if($lines.Count -lt 1) {
        Write-Output "No multi-line output found."
        return
    }
    $output = ""
    $stdErr = $false
    
    foreach($line in $lines){
        
        if($line -like "[stderr]*"){
            $stdErr = true
        }
        if($line -like "[stdout]*"){
            # pass through
        }
        if($stdErr -eq $true) {
            $output += $line
        }
    }

    return $output
}

$subscriptions = Get-AzSubscription | ? { $_.Name -in $SubscriptionNames }

$finishedSubs = 0

foreach($sub in $mySubs) {
    Write-Progress -Activity "Processing subscriptions" -Status "Processing for $($sub)" -PercentComplete ($finishedSubs/$subscriptions.Count) -id 1
    Select-AzSubscription $sub
    if($ResourceGroupName -eq $null -or $ResourceGroupName -eq ""){
        $vms = (Get-AzVM -Status | ? { $_.ResourceGroupName -notlike "MC_*" -and $_.PowerState -eq "VM running" })
    } else {
        $vms = (Get-AzVM -Status | ? { $_.ResourceGroupName -eq $ResourceGroupName -and $_.PowerState -eq "VM running" }) 
    }
    
    [System.Collections.ArrayList]$output = @()
    $jobs = @{}
    $vmCount = 0
    foreach($vm in $vms) {
        Write-Progress -Activity "Processing VMs" -PercentComplete ($vmCount / $vms.Count) -ParentId 1 -Status "Adding jobs" 
           if($vm.storageProfile.osDisk.osType -eq "Linux"){
                $task = ($vm | Invoke-AzVmRunCommand -CommandId RunShellScript -ScriptPath /Users/jgarverick/Downloads/update-cloudadmin.sh -AsJob)        
           } else {
                $task = ($vm | Invoke-AzVmRunCommand -CommandId RunPowerShellScript -ScriptPath /Users/jgarverick/Downloads/update-winboxes.ps1 -AsJob)        
           }
           $jobs.Add($vm.Name, $task) | Out-Null
           $vmCount += 1
    }
    Write-Progress -Activity "Processing VMs" -Completed
    $StillProcessing = $true
    Write-Output "Job submission complete for $($vmCount) VM(s)."
    while($StillProcessing) {
        [System.Collections.ArrayList]$queue = @()
        Write-Progress -Activity "Processing Jobs" -PercentComplete 0 -ParentId 1 -Status "Gathering job status"
        foreach($job in $jobs.Keys){
            $info = $jobs["$($job)"]
            $queuejob = (Get-Job -Id $info.Id)
            $queue += $queuejob
        }  
        $RunCount = $queue.Where({ $_.State -eq "Running"}).Count
        Write-Progress -Activity "Processing Jobs" -PercentComplete ($RunCount / $queue.Count) -ParentId 1 -Status "Monitoring job execution"
            #$queue | Select Id, State | ft -AutoSize
            $StillProcessing = !($RunCount -eq 0)
            Start-Sleep -s 5
    }

    Write-Progress -Activity "Processing Jobs" -Completed
    Write-Output "Gathering report output for $($sub)..."
    foreach($job in $jobs.Keys){
        $out = $jobs["$($job)"]
        $queuejob = (Get-Job -Id $out.Id | Select -Property @{N='JobId';E={$_.Id}}, @{N='VMName';E={$job}}, @{N='JobOutput';E={(Parse-StdOut $_.Output.Value[0].Message)}}, @{N='Errors';E={(Parse-StdErr $_.Output.Value[0].Message)}})
        $output += $queuejob
    }  
    
    "$($sub):$($vms.Count)" | Out-File -Path /Users/jgarverick/RunOutput.txt -Append
    $output | Out-File -Path ./RunOutput.txt -Append
    
    $finishedSubs += 1
}
Write-Progress -Activity "Processing subscriptions" -Completed
Write-Output "Process complete."
