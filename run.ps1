function Run($configPath) {
    try {
        #1. Read config
        $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json

        #[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
        
        #2. Check ssh connection
        $hostName = ssh -T $config.DestinationWS.SshPath "hostname";
        if ($hostName -eq $config.DestinationWS.HostName) {
            foreach ($project in $config.SourceWS.Projects) {
                if($project.Project.Enable -ne $true){ continue }          
                           
                Write-Host $project.Project.Name "in progress" -ForegroundColor Green 
                
                #3. Archive project in source workspace
                #3.1. Chech if archive already exists
                $archiveFullPath = $config.SourceWS.UpdatePath + $project.Project.Name + ".zip"
                If(Test-path $archiveFullPath) { Remove-item $archiveFullPath }
                
                #3.2. Archive
                $projectPath = Join-Path -Path $config.SourceWS.Path -ChildPath $project.Project.Name
                Compress-Archive -Path $projectPath -DestinationPath $archiveFullPath
                Write-Host "Project's archive was ready" -ForegroundColor Green 
                
                #4. Stop project's linux service
                $stopResult = ManageLinuxService -actionType "stop"

                #5. Check if project's linux service stopped
                $isActiveResult = ManageLinuxService -actionType "is-active"

                if($isActiveResult -like "inactive*")
                {
                    Write-Host "Service" $project.Project.ServiceName "was turned off" -ForegroundColor Green 
                    
                    #6. Backup project in destination workspace
                    $compressCommand = "tar -zcf " + $config.DestinationWS.BackupPath + $project.Project.Name + ".tar.gz " + $config.DestinationWS.Path + $project.Project.Name
                    $compressResult = ssh -T $config.DestinationWS.SshPath $compressCommand
                    Write-Host "Project in destination workspace was backuped" -ForegroundColor Green 
        
                    #7. Copy archived project from source workspace to destination workspace
                    $destinationUpdateFolder = $config.DestinationWS.SshPath + ":" + $config.DestinationWS.UpdatePath
                    scp $archiveFullPath $destinationUpdateFolder
                    Write-Host "Project's archive was copied from source to destination workspace" -ForegroundColor Green 

                    #8. Unzip with replace copied archive to destination project folder 
                    $extractCommand = "unzip -o " + $config.DestinationWS.UpdatePath + $project.Project.Name + ".zip" + " -d " + $config.DestinationWS.Path 
                    $extractResult = ssh -T $config.DestinationWS.SshPath $extractCommand
                    Write-Host "Project's archive was unzipped" -ForegroundColor Green

                    #9. Run project's linux service
                    $startResult = ManageLinuxService -actionType "start"

                    #10. Check project's linux service status
                    $isActiveResult = ManageLinuxService -actionType "is-active"

                    if($isActiveResult -like "active*"){
                        Write-Host "Service" $project.Project.ServiceName "was turned on" -ForegroundColor Green 
                        Write-Host "Project" $project.Project.Name "was updated" -ForegroundColor Green 
                    }
                }
            }
        }
        else { Write-Host "No SSH connetion" -ForegroundColor Red }
    }
    catch {
        Write-Error  $_ -ForegroundColor Red
    }
        
    Write-Host "Done!" -ForegroundColor Green
    Read-Host -Prompt "Press Enter to exit"
}

function ManageLinuxService{
    Param ([string]$actionType)

    $command = switch($actionType){
        "is-active" { "systemctl is-active " +  $project.Project.ServiceName }
        "stop" { "systemctl stop " + $project.Project.ServiceName }
        "start" {"systemctl start " + $project.Project.ServiceName }
    }

    $commandeExec = ssh -T $config.DestinationWS.SshPath $command
    return $commandeExec
}

Run $args[0]
