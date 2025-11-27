# PowerShell Script Renaming Plan

**Prefix:** `ta-` (Technical Anxiety)  
**Format:** `ta-[action]-[resource]-[detail].ps1`  
**Date:** January 15, 2025

## Naming Convention

### Pattern
```
ta-[verb]-[noun]-[modifier].ps1
```

### Common Verbs
- `get` - Retrieve/query information
- `set` - Configure/update settings
- `install` - Deploy/install components
- `remove` - Delete/uninstall components
- `enable` - Turn on features
- `configure` - Set up configuration
- `rotate` - Rotate credentials/keys
- `enforce` - Apply policies
- `check` - Validate/verify status
- `shutdown` - Stop resources
- `create` - Create new resources

### Examples
- `ta-get-backup-status.ps1` - Get backup status report
- `ta-install-monitoring-agent.ps1` - Install monitoring agents
- `ta-rotate-storage-keys.ps1` - Rotate storage account keys
- `ta-enforce-tags.ps1` - Enforce tag compliance

## Renaming Map

### Automation Scripts (Already Well-Named)

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `rotate-storage-keys.ps1` | `ta-rotate-storage-keys.ps1` | Add prefix only |
| `tag-enforcement.ps1` | `ta-enforce-tags.ps1` | Add prefix, simplify |
| `vm-health-check.ps1` | `ta-check-vm-health.ps1` | Add prefix, verb-first |
| `shutdown-dev-resources.ps1` | `ta-shutdown-dev-resources.ps1` | Add prefix only |

### Local Scripts - Core

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `Get-Tagging.ps1` | `ta-get-resource-tags.ps1` | Standardize, clarify |
| `Get-BackupStatus.ps1` | `ta-get-backup-status.ps1` | Standardize |
| `Get-AGW-ListenerURL.ps1` | `ta-get-appgateway-listeners.ps1` | Clarify, expand acronym |

### Local Scripts - Diagnostic Settings

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `Configure-AllDiagnostics.ps1` | `ta-configure-diagnostics-all.ps1` | Standardize |
| `Get-DiagnosticSettings.ps1` | `ta-get-diagnostic-settings.ps1` | Standardize |
| `Remove-DiagnosticSettingsAll.ps1` | `ta-remove-diagnostics-all.ps1` | Standardize, simplify |
| `Remove-DiagnosticSettingsName.ps1` | `ta-remove-diagnostics-byname.ps1` | Clarify |
| `Set-AllDiagnosticSettingsHub.ps1` | `ta-set-diagnostics-hub.ps1` | Simplify |
| `Set-AllDiagnosticSettingsLog.ps1` | `ta-set-diagnostics-loganalytics.ps1` | Clarify |
| `Set-MySQLDiagnosticSettingsLog.ps1` | `ta-set-diagnostics-mysql.ps1` | Simplify |
| `Set-SQLDiagnosticSettingsLog.ps1` | `ta-set-diagnostics-sql.ps1` | Simplify |

### Local Scripts - VM Extensions

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `Install-VmMonitoringExtension.ps1` | `ta-install-vm-monitoring.ps1` | Simplify |
| `Remove-VmMonitoringExtension.ps1` | `ta-remove-vm-monitoring.ps1` | Simplify |
| `Install-VmDependencyAgent.ps1` | `ta-install-vm-dependency.ps1` | Simplify |
| `Install-DiagExtensions.ps1` | `ta-install-vm-diagnostics.ps1` | Clarify |
| `Remove-DiagnosticExtensions.ps1` | `ta-remove-vm-diagnostics.ps1` | Clarify |

### Local Scripts - VM Backup

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `Enable-VmBackup.ps1` | `ta-enable-vm-backup.ps1` | Standardize |

### Local Scripts - VM Boot Diagnostics

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `Enable-BootDiagnostics.ps1` | `ta-enable-vm-bootdiag.ps1` | Standardize, clarify |

### Local Scripts - Storage Protection

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `Create-FSBackup.ps1` | `ta-create-fileshare-backup.ps1` | Expand acronym |
| `Create-FSSnapshots.ps1` | `ta-create-fileshare-snapshot.ps1` | Expand acronym |
| `Find-FileShares.ps1` | `ta-get-fileshares.ps1` | Standardize verb |

### Local Scripts - Deployment

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `Install-ActionsEvents.ps1` | `ta-install-alert-actions.ps1` | Clarify |
| `Install-AllAlerts.ps1` | `ta-install-alerts-all.ps1` | Standardize |
| `Install-MetricAlerts.ps1` | `ta-install-alerts-metrics.ps1` | Clarify |
| `Remove-AlertsActionsApps.ps1` | `ta-remove-alerts-all.ps1` | Simplify |

### Local Scripts - Service Principals

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `Get-AppExpirations.ps1` | `ta-get-serviceprincipal-expiry.ps1` | Clarify |

### On-Demand Scripts

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `Get-BackupStatus.ps1` | `ta-get-backup-status-ondemand.ps1` | Distinguish from local |
| `Get-PaaSExtensionStatus.ps1` | `ta-get-paas-extensions.ps1` | Simplify |
| `Get-UpdateManagementList.ps1` | `ta-get-update-compliance.ps1` | Clarify purpose |
| `Get-VMExtensionStatus.ps1` | `ta-get-vm-extensions.ps1` | Simplify |

### ARM Template - Automation Scripts

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `xm_Configure_DiagnosticSettings.ps1` | `ta-configure-diagnostics-runbook.ps1` | Remove prefix, clarify |
| `xm_Create_FileShareSnapshot.ps1` | `ta-create-fileshare-snapshot-runbook.ps1` | Remove prefix |
| `xm_Enable_Backups.ps1` | `ta-enable-backup-runbook.ps1` | Remove prefix |
| `xm_Enable_BootDiagnostics.ps1` | `ta-enable-bootdiag-runbook.ps1` | Remove prefix |
| `xm_Enable_DiagnosticSettings.ps1` | `ta-enable-diagnostics-runbook.ps1` | Remove prefix |
| `xm_Install_DependencyExtension.ps1` | `ta-install-dependency-runbook.ps1` | Remove prefix |
| `xm_Install_DiagnosticsExtension.ps1` | `ta-install-diagnostics-runbook.ps1` | Remove prefix |
| `xm_Install_LogAnalyticsAgent.ps1` | `ta-install-loganalytics-runbook.ps1` | Remove prefix |
| `xm_Install_MonitoringAgent.ps1` | `ta-install-monitoring-runbook.ps1` | Remove prefix |
| `xm_Install_MonitoringAgent_v2.ps1` | `ta-install-monitoring-v2-runbook.ps1` | Remove prefix |
| `xm_Remove_MonitoringAgent_v2.ps1` | `ta-remove-monitoring-v2-runbook.ps1` | Remove prefix |
| `remote_exec_example.ps1` | `ta-example-remote-execution.ps1` | Standardize |

### ARM Template - Platform Tools - Alerts

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `install-alerts-agent.ps1` | `ta-install-alerts-agent.ps1` | Add prefix |
| `install-alerts-aksdisk.ps1` | `ta-install-alerts-aks-disk.ps1` | Add prefix |
| `install-alerts-aksperf.ps1` | `ta-install-alerts-aks-perf.ps1` | Add prefix |
| `install-alerts-akspodcustom.ps1` | `ta-install-alerts-aks-pod-custom.ps1` | Add prefix |
| `install-alerts-akspoddefault.ps1` | `ta-install-alerts-aks-pod-default.ps1` | Add prefix |
| `install-alerts-akspodtargeted.ps1` | `ta-install-alerts-aks-pod-targeted.ps1` | Add prefix |
| `install-alerts-appgw.ps1` | `ta-install-alerts-appgateway.ps1` | Add prefix, expand |
| `install-alerts-appsvc-custom.ps1` | `ta-install-alerts-appservice-custom.ps1` | Add prefix, expand |
| `install-alerts-appsvc-sev1.ps1` | `ta-install-alerts-appservice-sev1.ps1` | Add prefix, expand |
| `install-alerts-appsvc.ps1` | `ta-install-alerts-appservice.ps1` | Add prefix, expand |
| `install-alerts-azbackup.ps1` | `ta-install-alerts-backup.ps1` | Add prefix, simplify |
| `install-alerts-azfilestg.ps1` | `ta-install-alerts-fileshare.ps1` | Add prefix, clarify |
| `install-alerts-datausage.ps1` | `ta-install-alerts-data-usage.ps1` | Add prefix |
| `install-alerts-ddosattack.ps1` | `ta-install-alerts-ddos.ps1` | Add prefix, simplify |
| `install-alerts-failedeventmanager.ps1` | `ta-install-alerts-eventmanager.ps1` | Add prefix, simplify |
| `install-alerts-failedincidentmanager.ps1` | `ta-install-alerts-incidentmanager.ps1` | Add prefix, simplify |
| `install-alerts-highsecurity.ps1` | `ta-install-alerts-security-high.ps1` | Add prefix, reorder |
| `install-alerts-linux.ps1` | `ta-install-alerts-linux.ps1` | Add prefix |
| `install-alerts-mysql.ps1` | `ta-install-alerts-mysql.ps1` | Add prefix |
| `install-alerts-oracle.ps1` | `ta-install-alerts-oracle.ps1` | Add prefix |
| `install-alerts-postgresql.ps1` | `ta-install-alerts-postgresql.ps1` | Add prefix |
| `install-alerts-resources.ps1` | `ta-install-alerts-resources.ps1` | Add prefix |
| `install-alerts-security.ps1` | `ta-install-alerts-security.ps1` | Add prefix |
| `install-alerts-snapshotrunbook.ps1` | `ta-install-alerts-snapshot.ps1` | Add prefix, simplify |
| `install-alerts-sql.ps1` | `ta-install-alerts-sql.ps1` | Add prefix |
| `install-alerts-windows.ps1` | `ta-install-alerts-windows.ps1` | Add prefix |

### ARM Template - Platform Tools - Infrastructure

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `install-platform-actiongroups.ps1` | `ta-install-platform-actiongroups.ps1` | Add prefix |
| `install-platform-automationacct.ps1` | `ta-install-platform-automation.ps1` | Add prefix, simplify |
| `install-platform-dbmarm.ps1` | `ta-install-platform-dbm-arm.ps1` | Add prefix |
| `install-platform-dbmconnections.ps1` | `ta-install-platform-dbm-connections.ps1` | Add prefix |
| `install-platform-dbmforms.ps1` | `ta-install-platform-dbm-forms.ps1` | Add prefix |
| `install-platform-diagnosticsstorage.ps1` | `ta-install-platform-diagnostics-storage.ps1` | Add prefix |
| `install-platform-eventmanager.ps1` | `ta-install-platform-eventmanager.ps1` | Add prefix |
| `install-platform-incidentmanager.ps1` | `ta-install-platform-incidentmanager.ps1` | Add prefix |
| `install-platform-loganalytics.ps1` | `ta-install-platform-loganalytics.ps1` | Add prefix |
| `install-platform-patchingdashboard.ps1` | `ta-install-platform-patching-dashboard.ps1` | Add prefix |
| `install-platform-recoveryvault.ps1` | `ta-install-platform-recoveryvault.ps1` | Add prefix |
| `install-platform-tech2dashboard.ps1` | `ta-install-platform-tech2-dashboard.ps1` | Add prefix |
| `install-platform-tech6dashboard.ps1` | `ta-install-platform-tech6-dashboard.ps1` | Add prefix |

### ARM Template - Resources

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `base64_helper.ps1` | `ta-helper-base64.ps1` | Standardize |
| `deploy.ps1` (DNS) | `ta-deploy-dns-servers.ps1` | Clarify |
| `deploy.ps1` (PaloAlto DMZ) | `ta-deploy-paloalto-dmz.ps1` | Clarify |
| `deploy.ps1` (PaloAlto EastWest) | `ta-deploy-paloalto-eastwest.ps1` | Clarify |

### ARM Template - Update Manager

| Current Name | New Name | Reason |
|-------------|----------|--------|
| `Get-WindowsUMData.ps1` | `ta-get-update-data-windows.ps1` | Standardize, expand |
| `configure-updateManagementWorker.ps1` | `ta-configure-update-worker.ps1` | Standardize, simplify |
| `configure-updatemanagementdb.ps1` | `ta-configure-update-database.ps1` | Standardize, expand |
| `install-updatemanagementdb.ps1` | `ta-install-update-database.ps1` | Standardize, simplify |
| `install-updatemanagementrunbooks.ps1` | `ta-install-update-runbooks.ps1` | Standardize, simplify |
| `install-updatemanagementsql.ps1` | `ta-install-update-sql.ps1` | Standardize, simplify |
| `install-updatemanagementworker.ps1` | `ta-install-update-worker.ps1` | Standardize, simplify |
| `xm_Get-UpdateManagementData.ps1` | `ta-get-update-data-runbook.ps1` | Remove prefix, standardize |

## Implementation Strategy

### Phase 1: Core Scripts (High Priority)
Rename the most frequently used scripts first:
1. Automation scripts (4 scripts)
2. Core local scripts (3 scripts)
3. VM extension scripts (5 scripts)
4. Diagnostic settings scripts (8 scripts)

### Phase 2: Platform Tools (Medium Priority)
Rename platform deployment scripts:
1. Alert installation scripts (26 scripts)
2. Infrastructure installation scripts (13 scripts)

### Phase 3: Specialized Scripts (Lower Priority)
Rename specialized and less frequently used scripts:
1. Update manager scripts (8 scripts)
2. Resource deployment scripts (4 scripts)
3. On-demand scripts (4 scripts)
4. Storage protection scripts (3 scripts)

## Git Commands for Renaming

```bash
# Rename with git to preserve history
git mv old-name.ps1 new-name.ps1

# Or for batch renaming
for file in *.ps1; do
    git mv "$file" "ta-${file}"
done
```

## Post-Rename Tasks

1. **Update Documentation**
   - Update README files
   - Update runbook documentation
   - Update any deployment guides

2. **Update References**
   - Search for script references in:
     - ARM templates
     - Azure Automation runbooks
     - CI/CD pipelines
     - Documentation files
     - Other PowerShell scripts

3. **Update Imports/Calls**
   - Update any scripts that call renamed scripts
   - Update automation account runbook references
   - Update scheduled tasks

4. **Test Execution**
   - Verify renamed scripts still execute
   - Test any dependent scripts
   - Verify automation runbooks

## Benefits of Standardization

1. **Branding**
   - Clear ownership (Technical Anxiety)
   - Professional appearance
   - Consistent identity

2. **Organization**
   - Easy to identify TA scripts
   - Alphabetical grouping
   - Clear naming pattern

3. **Discoverability**
   - Verb-first naming makes purpose clear
   - Consistent structure aids searching
   - Easier to find related scripts

4. **Professionalism**
   - Enterprise-grade naming
   - Consistent with industry standards
   - Clear, descriptive names

## Naming Guidelines for Future Scripts

When creating new scripts, follow this pattern:

```
ta-[verb]-[resource]-[modifier].ps1
```

**Examples:**
- `ta-get-vm-status.ps1` - Get VM status
- `ta-install-aks-monitoring.ps1` - Install AKS monitoring
- `ta-rotate-sql-passwords.ps1` - Rotate SQL passwords
- `ta-enforce-network-policies.ps1` - Enforce network policies
- `ta-check-security-compliance.ps1` - Check security compliance

**Avoid:**
- Underscores (use hyphens)
- Abbreviations unless very common (VM, SQL, AKS are OK)
- Version numbers in filename (use git tags instead)
- Generic names like "script.ps1" or "helper.ps1"

---

**Total Scripts to Rename:** 97  
**Estimated Time:** 2-3 hours (including testing)  
**Risk Level:** Low (git mv preserves history)
