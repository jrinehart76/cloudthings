# Deprecated Machine Learning Templates

## MLWorkbench.json

**Status:** DEPRECATED

This template uses `Microsoft.MachineLearningModelManagement/accounts` which was part of Azure Machine Learning Workbench, deprecated in 2018.

**Replacement:** Use Azure Machine Learning workspace (`Microsoft.MachineLearningServices/workspaces`)

**Migration Guide:** https://docs.microsoft.com/azure/machine-learning/overview-what-happened-to-workbench

## Modern Alternative

For current Azure Machine Learning deployments, use:
- Resource Type: `Microsoft.MachineLearningServices/workspaces`
- API Version: `2023-04-01` or later
- Includes: Compute, datastores, and model management

The `MLWorkspace.json` template in the parent directory uses the older classic ML workspace which is also being phased out in favor of Azure ML Services workspaces.
