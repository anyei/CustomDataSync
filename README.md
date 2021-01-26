# CustomDataSync
Salesforce custom solution to move data from one org to another.

### Install

##### Deploy to Salesforce Button

<a href="https://githubsfdeploy.herokuapp.com?owner=anyei&repo=CustomDataSync">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

##### Manual
Download/Clone this repo and use sfdx or the tool of your preference to deploy the src folder's content.
With sfdx is just one command, make sure you have authenticated and authorized:
```apex sfdx force:mdapi:deploy -d ./src -u usernameofyourorg```


###Configure

You need to make sure of the following:

##### Remote Site Settings entry

After you install, you must make sure the salesforce instance server where you want to push or send your data is included in your remote site settings entries:

1. Go to setup
2. Then in the left menu, click on "Security Controls" -> "Remote Site Settings" option 
3. If you dont have an entry of your target salesforce instance, click "New Remote Site" button 
4. Put a name name to that entry in the "Remote Site Name" field, could be something like "salesforce sandbox" or "salesforce prod"
5. In the "Remote Site URl" type in the correct url of the target salesforce instance, mine looks like "https://na17.salesforce.com" without quotes 
6. Finally make sure the "Active" checkbox is checked and save the record. 

##### Custom Labels

Several custom labels are used for a bit of flexibility, make sure they are according to your needs:

- customDataSyncTargetObject
    - The object we are working with as source data, current value is **Contact**
- customDataSyncSalesforceCompositeEndPoint
    - Salesforce's composite rest api endpoint, current value is **/services/data/v49.0/composite/sobjects/**
- customDataSyncSalesforceBulkApiEndpoint
    - Salesforce's bulk api rest endpoint, current value is **/services/data/v49.0/jobs/ingest/**
- customDataSyncFixedExternalId
    - The external id field which is used to perform upsert operations for the target object, current value is **Email**
- customDataSyncAdminProfileId
    - A full profile id value (18 chars). Only users with this profile will see the **Batch Sync Fields** tab in the UI. **UPDATE THE VALUE**

