function Test-Servidor {
    param(
        [string]$prefixo,
		[string]$sufixo
    )

$srvServicos = @()
    for ($i = 1; $true; $i++) {
    $numero = "{0:D2}" -f $i  
    $servidor = "${prefixo}${numero}${sufixo}" 
	

    
    if (Test-Connection -ComputerName $servidor -Count 1 -Quiet) {
        $srvServicos += $servidor
        $contadorFalhas = 0
    } else {
        $contadorFalhas++
    }

    
    if ($contadorFalhas -ge 3) {
        break
    }
}
return $srvServicos
}
function Restart-Services{
    param(
        [array]$servicos,
        [string]$serverCliente
    )
    
    foreach ($servico in $servicos) {
            $reiniciarPrompt = "Encontrado:  $($servico.DisplayName) no servidor $serverCliente"
			Write-Host ""
			Write-Host $linha -ForegroundColor Green
            Write-Host $reiniciarPrompt -ForegroundColor Cyan
			Write-Host $linha -ForegroundColor Green
            $reiniciar = "S"

            if ($reiniciar.ToUpper() -eq "S") {
    $attempts = 3  # Defina o número máximo de tentativas
    $serviceStarted = $false
    
    do {
        try {
            Write-Host "Parando o serviço $($servico.DisplayName) no servidor $serverCliente..." -ForegroundColor Yellow
            Invoke-Command -ComputerName $serverCliente -ScriptBlock { Stop-Service -DisplayName $using:servico.DisplayName }
            Write-Host "$($servico.DisplayName) parado" -ForegroundColor Green 
            Start-Sleep -Seconds 5
            Write-Host "Iniciando o serviço $($servico.DisplayName) no servidor $serverCliente" -ForegroundColor Yellow
            
            $serviceStarted = $false

            Invoke-Command -ComputerName $serverCliente -ScriptBlock { Start-Service -DisplayName $using:servico.DisplayName } -ErrorAction SilentlyContinue
            Write-Host "Aguardando resposta de $($servico.DisplayName) ..." -ForegroundColor Cyan  
            Start-Sleep -Seconds 15

            # Verificar se o serviço foi iniciado com sucesso após 15 segundos
            $serviceStatus = (Get-Service -DisplayName $servico.DisplayName -ComputerName $serverCliente).Status
            if ($serviceStatus -eq 'Running') {
                $serviceStarted = $true
                Write-Host "Serviço $($servico.DisplayName) reiniciado com sucesso no servidor $serverCliente." -ForegroundColor Green
                $servicesRestarted += "$($servico.DisplayName.PadRight(98)) $($serverCliente.PadRight(30)) Sucesso"+"`n"
            } else {
                Write-Host "Não foi possível iniciar o serviço $($servico.DisplayName) no servidor $serverCliente." -ForegroundColor Yellow
                if ($attempts -gt 1) {
                    Write-Host "$($attempts - 1)ª tentativa em 15 segundos" -ForegroundColor Yellow
                    Start-Sleep -Seconds 15
                }
            }
            
            $attempts--
        } catch {
            Write-Host "Erro ao reiniciar o serviço $($servico.DisplayName) no servidor $serverCliente : $_" -ForegroundColor Red
            continue
        }
    } while (!$serviceStarted -and $attempts -gt 0)
    
    if (!$serviceStarted) {
        Write-Host "Serviço $($servico.DisplayName) ainda não foi iniciado no servidor $serverCliente." -ForegroundColor Red
        $servicesRestarted += "$($servico.DisplayName.PadRight(98)) $($serverCliente.PadRight(30)) Erro"+"`n"
    }
}

        }
		
		return $servicesRestarted
    
}
$linha = "-" * 100
$nomeServidorLocal = $env:COMPUTERNAME
Write-Host "Versão 9" -BackgroundColor Cyan -ForegroundColor Black
$pastaCliente = Read-Host "Digite o nome da pasta do cliente"
$serverCliente = Read-Host "Digite o nome do Servidor onde se encontra a pasta do cliente"

if ($nomeServidorLocal -like "HO*") {
    $servidores = @()
	$integradores = @()
	Write-Host $linha -ForegroundColor Green
    Write-Host "                                                              ANTARES" -ForegroundColor Red
	Write-Host $linha -ForegroundColor Green
	Write-Host $linha -ForegroundColor Green
    Write-Host "Buscando Servidores de Integração G7" -ForegroundColor Cyan
	
	$integradores += Test-Servidor -prefixo "HOINT" -sufixo "SEN"
	$integradores += Test-Servidor -prefixo "HOINTETLH" -sufixo "SEN"
	$integradores += Test-Servidor -prefixo "HOINTETLP" -sufixo "SEN"

    $quantidadeINT = $integradores.Count
	Write-Host "Econtrado $quantidadeINT servidores" -ForegroundColor Cyan
	Write-Host $linha -ForegroundColor Green
	Write-Host $linha -ForegroundColor Green
    Write-Host "Buscando Servidores Balanceamento de Middleware" -ForegroundColor Cyan

	$servidores += Test-Servidor -prefixo "HOMDW" -sufixo "SEN"
	$servidores += Test-Servidor -prefixo "HOMDWD" -sufixo "SEN"
	$servidores += Test-Servidor -prefixo "HOMDWH" -sufixo "SEN"
    $quantidadeMDW = $servidores.Count
	Write-Host "Econtrado $quantidadeMDW servidores" -ForegroundColor Cyan
	Write-Host $linha -ForegroundColor Green
	
	$antares = $true
} elseif ($nomeServidorLocal -like "BM*") {
    $servidores = @()
	$integradores = @()
	Write-Host $linha -ForegroundColor Green
    Write-Host "                                                              BELLATRIX" -ForegroundColor Red
	Write-Host $linha -ForegroundColor Green
	Write-Host $linha -ForegroundColor Green
    Write-Host "Buscando Servidores de Integração G7" -ForegroundColor Cyan
	
	$integradores += Test-Servidor -prefixo "BMINT" -sufixo "SEN"
	$integradores += Test-Servidor -prefixo "BMINTETL" -sufixo "SEN"
    $quantidadeINT = $integradores.Count
	Write-Host "Econtrado $quantidadeINT servidores" -ForegroundColor Cyan
	Write-Host $linha -ForegroundColor Green
	Write-Host $linha -ForegroundColor Green
    Write-Host "Buscando Servidores Balanceamento de Middleware" -ForegroundColor Cyan
    
	$servidores += Test-Servidor -prefixo "BMMDW" -sufixo "SEN"
    $quantidadeMDW = $servidores.Count
	Write-Host "Econtrado $quantidadeMDW servidores" -ForegroundColor Cyan
	Write-Host $linha -ForegroundColor Green

}elseif ($nomeServidorLocal -like "VM*") {
    $servidores = @()
	$integradores = @()
	Write-Host $linha -ForegroundColor Green
    Write-Host "                                                              SIRIUS" -ForegroundColor Red
	Write-Host $linha -ForegroundColor Green
	Write-Host $linha -ForegroundColor Green
    Write-Host "Buscando Servidores de Integração G7" -ForegroundColor Cyan
	
	$integradores += Test-Servidor -prefixo "VMINTH" -sufixo "SEN"
	$integradores += Test-Servidor -prefixo "VMINTP" -sufixo "SEN"
    $quantidadeINT = $integradores.Count
	Write-Host "Econtrado $quantidadeINT servidores" -ForegroundColor Cyan
	Write-Host $linha -ForegroundColor Green
	Write-Host $linha -ForegroundColor Green
    Write-Host "Buscando Servidores Balanceamento de Middleware" -ForegroundColor Cyan
	
	$servidores += Test-Servidor -prefixo "VMMDW" -sufixo "SEN"
	$servidores += Test-Servidor -prefixo "VMMDWH" -sufixo "SEN"
    $quantidadeMDW = $servidores.Count
	Write-Host "Econtrado $quantidadeMDW servidores" -ForegroundColor Cyan
	Write-Host $linha -ForegroundColor Green
} else {
    Write-Host "Script só funciona nos ambientes Bellatrix, Antares e Sirius. Para outros ambientes falar com renan.vieira@senior.com.br" -ForegroundColor Red

    Write-Host "Deseja voltar à tela inicial? (S/N)" -ForegroundColor Cyan
    $opcao = Read-Host

    if ($opcao.ToUpper() -eq "S") {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        Set-Location -Path (Join-Path -Path $scriptDir -ChildPath "..")
        Start-Process -FilePath "atualiza.bat" -NoNewWindow
    }

    return 
}
$pastaClienteG7 = ($pastaCliente -split "_")[0]
$ultimaLetra = $pastaCliente[-1]
if ($ultimaLetra -eq "P" -or $ultimaLetra -eq "p"){
    $ambiente = "Prod"
} else {
    $ambiente = "Homolog"
}
$log = @()
$servicesRestarted = @()



			Write-Host $linha -ForegroundColor Green
            Write-Host "Gerando ID de Cliente" -ForegroundColor Cyan
			Write-Host $linha -ForegroundColor Green

$session = New-PSSession -ComputerName $serverCliente

# Execute o comando no servidor remoto usando a sessão PSSession
$servicosLocal = Invoke-Command -Session $session -ScriptBlock {
    Get-Service | Where-Object { $_.DisplayName -like "*$using:pastaCliente*" -and $_.DisplayName -like "*middleware*" }
}
Remove-PSSession $session
$idCliente = 0

foreach ($servicos in $servicosLocal) {
    $numeros = [regex]::Matches($servicos.DisplayName, '\d+')
    foreach ($match in $numeros) {
        $numero = [Int64]$match.Value
        if ($numero -gt $idCliente) {
            $idCliente = $numero
        }
    }
}
			Write-Host $linha -ForegroundColor Green
            Write-Host "ID de Cliente: $idCliente" -ForegroundColor Cyan
			Write-Host $linha -ForegroundColor Green
if ($idCliente -ne 0){
    $servicosPorId = Invoke-Command -ComputerName $serverCliente -ScriptBlock {
        param($idCliente)
        Get-Service | Where-Object { $_.DisplayName -like "*$idCliente*" }
    } -ArgumentList $idCliente
} else {
    Write-Host "Nenhum Cliente encontrado em $serverCliente" -ForegroundColor Red

    Write-Host "Deseja voltar à tela inicial? (S/N)" -ForegroundColor Cyan
    $opcao = Read-Host

    if ($opcao.ToUpper() -eq "S") {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        Set-Location -Path (Join-Path -Path $scriptDir -ChildPath "..")
        Start-Process -FilePath "atualiza.bat" -NoNewWindow
    }

    return 
}

$caminhoLocal = "\\$serverCliente\d$\$pastaCliente\AppManager.exe"
$dataModificacaoLocal = $null

try {
    $dataModificacaoLocal = (Get-Item $caminhoLocal).LastWriteTime
} catch {
    # n faz nada
}

$feito = "Não"
$g7 = "Não"
			Write-Host ""
			Write-Host $linha -ForegroundColor Green
            Write-Host "Produrando por Integrador G7 para $pastaClienteG7" -ForegroundColor Cyan
			Write-Host $linha -ForegroundColor Green
foreach ($integrador in $integradores) {
    $caminhoRemoto = "\\$integrador\D$\G7_Integrador\*$pastaClienteG7*\AppManager.exe"
    try {
        # Verifique se o diretório e o arquivo existem no servidor atual
        if (Test-Path $caminhoRemoto -PathType Leaf) {
            $dataModificacaoRemoto = (Get-Item $caminhoRemoto).LastWriteTime
            if ($dataModificacaoRemoto.Date -eq $dataModificacaoLocal.Date) {
               	
				Write-Host "AppManager em $integrador atualizado" -ForegroundColor Black -BackgroundColor Green
				
				$g7 = "Sim"
				$feito = "Sim"
            } else {
				Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Yellow -BackgroundColor Red
				Write-Host "Integrador G7 em $integrador Não atualizado                  " -ForegroundColor Yellow -BackgroundColor Red
				Write-Host "Atualize e precione 'S' para continuar                    " -ForegroundColor Yellow -BackgroundColor Red
				Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Yellow -BackgroundColor Red
				$g7 = "Sim"
				$selecao = Read-Host "Deseja continuar?(S/N)"
					if ($selecao.ToUpper() -eq "S"){
						$dataModificacaoRemoto = (Get-Item $caminhoRemoto).LastWriteTime
						if ($dataModificacaoRemoto.Date -eq $dataModificacaoLocal.Date){
							Write-Host "Integrador G7 em $integrador atualizado                      " -ForegroundColor Black -BackgroundColor Cyan
							$feito = "Sim"
							continue
						}else{
							Write-Host "Integrador G7 em $integrador ainda não atualizado continuando Script   " -ForegroundColor Yellow -BackgroundColor Red
							continue
							}
						
					}else{
						$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
						Set-Location -Path (Join-Path -Path $scriptDir -ChildPath "..")
						Start-Process -FilePath "atualiza.bat" -NoNewWindow
					}

					
					}
				
            }
            
        
    } catch {
        # Suprima o erro se o caminho não existir
    }
	
}
if ($nenhumCaminhoEncontrado) {
    $g7 = "Não"
	
}
   Write-Host ""
    Write-Host $linha -ForegroundColor Green
    Write-Host "Procurando Serviços de $pastaClienteG7" -ForegroundColor Cyan
    Write-Host $linha -ForegroundColor Green
if ($servicosPorId) {
    $servicosCSM = $servicosPorId | Where-Object { $_.DisplayName -like "*CSM*" }
    $servicesRestarted += Restart-Services -servicos $servicosCSM -serverCliente $serverCliente

    $servicosRestantes = $servicosPorId | Where-Object { $_.DisplayName -notlike "*CSM*" }
    $servicesRestarted += Restart-Services -servicos $servicosRestantes -serverCliente $serverCliente
}
Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Black -BackgroundColor Green
Write-Host "Inicio de verificação em servidores remotos de Middleware" -ForegroundColor Black -BackgroundColor Green
Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Black -BackgroundColor Green
$servicosMDW = @()
foreach ($servidor in $servidores) {
    $servicosRemotos = Get-Service -ComputerName $servidor | Where-Object { $_.DisplayName -like "*$pastaCliente*" }
    $servicosMDW += $servicosRemotos  
		if($servicosRemotos){
			$servicesRestarted += Restart-Services -servicos $servicosMDW -serverCliente $servidor
		}

    
}
if ($g7.ToUpper() -eq "SIM"){
Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Black -BackgroundColor Green
Write-Host "Inicio de verificação de integrador G7                    " -ForegroundColor Black -BackgroundColor Green
Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Black -BackgroundColor Green
$servicosETL = @()
foreach ($integrador in $integradores) {
    $servicosRemotosETL = Get-Service -ComputerName $integrador | Where-Object { $_.DisplayName -like "*$idCliente*" }
	$servicosETL += $servicosRemotosETL
		if($servicosRemotosETL){
    $servicesRestarted += Restart-services -servicos $servicosETL -serverCliente $integrador
		}
    
}

}
$remoteServiceLclStatus = @()
$remoteServiceStatus = @()
$remoteServiceIntStatus = @()
    try {
        $servicosRemotosLcl = Get-Service -ComputerName $serverCliente | Where-Object { $_.DisplayName -like "*$idCliente*" }
        foreach ($servicoRemotoLcl in $servicosRemotosLcl) {
            $statusRemotoLcl = $servicoRemotoLcl.Status
            $remoteServiceLclStatus += [PSCustomObject]@{
                Serviço   = "$($servicoRemotoLcl.DisplayName)".PadRight(98)
                Iniciado  = if ($statusRemotoLcl -eq 'Running') { "Sim" } else { "Não" }
            }
        }
    } catch {
        $logEntryRemotoLcl = "Erro ao verificar o status dos serviços em $servidor : $_"
        $log += $logEntryRemotoLcl
    }
foreach ($servidor in $servidores) {
    try {
        $servicosRemotos = Get-Service -ComputerName $servidor | Where-Object { $_.DisplayName -like "*$pastaCliente*" }
        foreach ($servicoRemoto in $servicosRemotos) {
            $statusRemoto = $servicoRemoto.Status
            $remoteServiceStatus += [PSCustomObject]@{
                Serviço   = "$($servicoRemoto.DisplayName)".PadRight(98)
                Iniciado  = if ($statusRemoto -eq 'Running') { "Sim".PadRight(30)+"$servidor" } else { "Não".PadRight(30)+"$servidor" }
				
            }
        }
    } catch {
        $logEntryRemoto = "Erro ao verificar o status dos serviços em $servidor : $_"
        $log += $logEntryRemoto
    }
}
foreach ($integrador in $integradores) {
    try {
        $servicosRemotosInt = Get-Service -ComputerName $integrador | Where-Object { $_.DisplayName -like "*$idCliente*" }
        foreach ($servicoRemotoInt in $servicosRemotosInt) {
            $statusRemotoInt = $servicoRemotoInt.Status
            $remoteServiceIntStatus += [PSCustomObject]@{
                Serviço   = "$($servicoRemotoInt.DisplayName)".PadRight(98)
                Iniciado  = if ($statusRemotoInt -eq 'Running') { "Sim" } else { "Não" }
            }
        }
    } catch {
        $logEntryRemotoInt = "Erro ao verificar o status dos serviços em $servidor : $_"
        $log += $logEntryRemotoInt
    }
}
$log += "Versão 8"
$log += "Relatorio de Execução:"
$log += "Cliente: $pastaCliente"
$log += "Data/Hora: $(Get-Date -Format 'dd-MM-yyyy HH:mm:ss')"
$log += "Servidor de execução: $nomeServidorLocal"
$log += "Servidor cliente: $serverCliente"
$log += "Integrador G7: $g7"
if ($g7 -eq "Sim"){
	$log += "Atualizado: $feito"
}else{}
$log += ""
$log += "Serviços no servidor $serverCliente :"
$log += "Serviço                                                                                           Iniciado"
$log += "------------------------------------                                                              ---------"
foreach ($entry in $remoteServiceLclStatus) {
    $logEntryRemotoLcl = "$($entry.Serviço) $($entry.Iniciado)"
    $log += $logEntryRemotoLcl
}
if ($g7 -eq "Sim"){
$log += ""
$log += "Integrador G7:"
$log += "Serviço                                                                                           Iniciado"
$log += "------------------------------------                                                              ---------"

foreach ($entry in $remoteServiceIntStatus) {
    $logEntryRemotoInt = "$($entry.Serviço) $($entry.Iniciado)"
    $log += $logEntryRemotoInt
}
}
$log += ""
$log += "Servidores remotos onde foram encontrados middlewares:"
$log += "Serviço                                                                                           Iniciado                       Servidor"
$log += "------------------------------------                                                              ---------                      ---------"

foreach ($entry in $remoteServiceStatus) {
    $logEntryRemoto = "$($entry.Serviço) $($entry.Iniciado)"
    $log += $logEntryRemoto
}
if ($servicesRestarted.Count -gt 0) {
    $log += ""
	$log += ""
	$log += "Serviços reiniciados:"
	$log += "Serviço                                                                                           Servidor                       Status"
	$log += "------------------------------------                                                              ---------                      --------"
    foreach ($service in $servicesRestarted) {
        $log += $service
    }
}
$log += ""
$log += "------------------------------------------------------------------------------------------------------------------------------------------------"
$log += "                                                   ABAIXO DESSA LINHA NÃO É NECESSARIO COLAR NO TICKET"
$log += "------------------------------------------------------------------------------------------------------------------------------------------------"
$log +="                                                   SERVIDORES DE BALANCEAMENTO DE MIDDLEWARE ENCONTRADOS"

foreach($srv in $servidores){
$log += $srv    
}
$log +="total: $quantidadeMDW"
$log += "------------------------------------------------------------------------------------------------------------------------------------------------"
$log +="                                                           SERVIDORES DE INTEGRADOR G7 ENCONTRADOS"

foreach($srvINT in $integradores){
$log += $srvINT   
}
$log +="total: $quantidadeINT"

$logFilePath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop\log_$pastaCliente.txt")
$log | Out-File -FilePath $logFilePath

Write-Host "Log gerado e salvo em $logFilePath" -ForegroundColor Green
Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Black -BackgroundColor Yellow
Write-Host "Não esqueça de colar o print deste log no final do ticket" -ForegroundColor Black -BackgroundColor Yellow
Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Black -BackgroundColor Yellow
Write-Host "Deseja voltar à tela inicial? (S/N)" -ForegroundColor Cyan
$opcao = Read-Host

if ($opcao.ToUpper() -eq "S") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Set-Location -Path (Join-Path -Path $scriptDir -ChildPath "..")
    Start-Process -FilePath "atualiza.bat" -NoNewWindow
}