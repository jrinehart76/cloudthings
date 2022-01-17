## Purpose

This template creates a Standard Stream Analytics Job. [For more information](https://docs.microsoft.com/en-us/azure/stream-analytics/stream-analytics-create-a-job). 

Specifics:

* no inputs or outputs are defined.  This is usually done as part of the application code.  


## Assumptions

* we assume 5 sec "out of order event latency" and set to "adjust"
* we are set to retry on error.  In some cases it may be better to "Drop", but for the template we err on the side of caution.  


