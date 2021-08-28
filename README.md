# New-OUCollection
Recursivley create OU based device collections in ConfigMgr

## Setup

Modify the Settings.json for your ConfigMgr site. The console location should be the root path of where you'd like these collections to end up. Sub folders will also be created starting at this path.

## OU Collections

Provide the SearchBase of where to start making collections from. The CanonicalRoot should match your SearchBase. AreaID will become your prefix for all the collections that get created. You may want to modify how I am formatting the names of collections. Below you can find an example of how the current formatting works. 

### Example

```
Assume AreaID = Finance

SUB OU's of Finance -- Accounting, Budget, Payroll

Accounting has a SUB OU of Audit & Compliance

Collections Created:

Finance-Accounting
Finance-Accounting - Audit & Compliance
Finance-Budget
Finance-Payroll

Console Paths Created: 

Finance 
Finance > Accounting
Finance > Budget
Finance > Payroll

```
