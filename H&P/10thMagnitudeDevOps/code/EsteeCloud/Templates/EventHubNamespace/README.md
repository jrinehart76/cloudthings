## Purpose

Creates:

* an EventHubs namespace (under the standard tier) and enables auto-inflate (this allows throughput units to increase as necessary)
* an EventHub


## Assumptions

Use this template if you need to deploy a new namespace with standard pricing tier when you need to pick a region.  Otherwise, for cost containment reasons, considering using the other template to create a new EventHub within an existing namespace.


