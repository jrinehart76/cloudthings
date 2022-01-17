@ECHO OFF
REM Placeholder for running kubectl based on input
REM Args expected are as follows:
REM %1 -> CLUSTERTYPE (ACS,AKS)
REM %2 -> DNSPREFIX (dns prefix for the cluster, also serves as the AKS cluster name)
REM %3 -> K8SENV (environment, such as DEV or PROD)
REM %4 -> USE_SRE (configure spinnaker namespace and quota)
REM %5 -> K8SRG (Name of the resource group in which to find the cluster)

IF "%1" EQU "-h" GOTO :PRINT_HELP 
IF "%1" EQU "/h" GOTO :PRINT_HELP
IF "%1" EQU "--h" GOTO :PRINT_HELP
IF [%1] EQU [] GOTO :PRINT_HELP

SET CLUSTERTYPE=%1
SET DNSPREFIX=%2
SET K8SENV=%3
SET USE_SRE=%4
SET K8SRG=%5
SET APP=%APPID%

WHERE az >nul 2>nul
IF NOT ERRORLEVEL 0 (
	echo "Azure CLI not found!"
	exit /b 9009
) else (
	ECHO Found Azure CLI in path.
)
REM Insatll kubectl from the Azure CLI
where kubectl >nul 2>nul
IF NOT ERRORLEVEL 0 (
	ECHO Could not find kubectl.  Installing.
	az aks install-cli
) else (
	ECHO Found kubectl in path.
)

IF "%AGENT_RELEASEDIRECTORY%" EQU "" SET AGENT_RELEASEDIRECTORY=%~dp0
IF "%USE_SRE%" EQU "" SET USE_SRE=TRUE
IF "%K8SENV%" EQU "" SET K8SENV=DEV
IF "%APP%" EQU "" SET APP=MYAPP

IF "%CLUSTERTYPE%" EQU "ACS" GOTO :ACSENGINE
IF "%CLUSTERTYPE%" EQU "AKS" GOTO :AKS

ECHO Could not determine cluster type.  Now exiting.
EXIT /b 1

:AKS
ECHO Starting AKS Configuration
az aks get-credentials -n %DNSPREFIX% -g %K8SRG% --admin
GOTO :MAIN

:ACSENGINE
ECHO Starting ACS Engine Configuration
SET "ACSCFG=%AGENT_RELEASEDIRECTORY%kubeconfig.%APP%.%K8SENV%.config"
IF EXISTS "%ACSCFG%" (
	kubectl apply -f %~dp0\OMSDaemonset.yaml --kubeconfig=%ACSCFG%
) ELSE 
	ECHO Cannot find file specified at %ACSCFG%!
	EXIT /b 9009
)
GOTO :MAIN

:PRINT_HELP
ECHO This program configures ACS or AKS clusters with namespaces, quotas and optionally log analytics.
ECHO List of arguments expected:
ECHO ARG 1		CLUSTERTYPE (ACS,AKS)
ECHO ARG 2		DNSPREFIX (dns prefix for the cluster, also serves as the AKS cluster name)
ECHO ARG 3		K8SENV (environment, such as DEV or PROD)
ECHO ARG 4		USE_SRE (configure spinnaker namespace and quota--TRUE or FALSE) 
ECHO ARG 5		K8SRG (Name of the resource group in which to find the cluster)
exit

:MAIN
ECHO Processing cluster commands...
kubectl cluster-info
kubectl apply -f %~dp0\cluster-admin.yaml
kubectl apply -f %~dp0\DashboardRBAC.yaml
kubectl apply -f %~dp0\app.yaml
IF "%USE_SRE%" EQU "TRUE" kubectl apply -f %~dp0\sre.yaml
exit
