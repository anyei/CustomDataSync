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
```sfdx force:mdapi:deploy -d ./src -u usernameofyourorg```


### Configure


##### Profiles

Make sure the apex classes are enabled to your profiles:

- CustomDataSyncController
- CustomDataSyncHelper

You need to make sure of the following:

##### Remote Site Settings entry

After you install, you must make sure the salesforce instance server where you want to push or send your data is included in your remote site settings entries:

1. Go to setup
2. Then in the left menu, click on "Security Controls" -> "Remote Site Settings" option 
3. If you dont have an entry of your target salesforce instance, click "New Remote Site" button 
4. Put a name name to that entry in the "Remote Site Name" field, could be something like "salesforce sandbox" or "salesforce prod"
5. In the "Remote Site URl" type in the correct url of the target salesforce instance (either https://login.salesforce.com or https://test.salesforce.com) without quotes, as well as specific target org domain, example https://resilient-otter-po5poq-dev-ed.my.salesforce.com.
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
    
##### Custom Metadata Type

A record for **Custom Data Sync Target Org** custom metadata type is required with the following information, the rest of the fields can have irrelevant values:

- JWT
    - A Java Web Token (JWT), this is a token generated in order to authenticate against the target org you wish to push data to. Please look at the section **How to generate a JWT** to learn more about it.
- Domain
    - A salesforce base domain for the target org (either https://login.salesforce.com or https://test.salesforce.com).
- External Id Field
    - The external id field which is used to perform upsert operations for the target object, the value must be the same as the custom label **customDataSyncFixedExternalId**
  

##### Add LWC to the UI

Add the lwc **customDataSyncTabSelector** to the page you desired to see the tool running.
 
##### Schedule it
 
 In order to allow it to run every now and then automatically, make sure to schedule the using the cron fits your need, the following is to schedule the job every day at 8pm.
 ```system.schedule('Custom Data Sync batch', '0 0 20 * * ? *', new CustomDataSyncBatchScheduler(10000));```
 
 
 ### How to generate a JWT 
 ### Taken from https://gist.github.com/booleangate/30d345ecf0617db0ea19c54c7a44d06f
 
 
 ##### Salesforce OAuth 2.0 JWT Bearer Token Flow Walk-Through

This document will walk you through how to create or configure a Salesforce application for use with JWT authentication.  These configuration steps and the example code works as of Salesforce API version 42.0.


##### Prerequisites

Create an RSA x509 private key/certification pair

```
openssl req -x509 -sha256 -nodes -days 36500 -newkey rsa:2048 -keyout salesforce.key -out salesforce.crt
```

The private key (.key) will be used to sign the JWT claim generated by your code.  The certificate (.crt) will be uploaded to Salesforce to validate your signed JWT assertions.

##### Salesforce Application creation

1. Login to salesforce.
1. Go to setup area (gear in the nav in the top right)
1. In the side nav, go to _Apps_ > _App Manager_
   1. Click _New Connect App_
   1. In the _Basic Information_ section, populate the required fields.  The values are for book keeping only and are not part of using the API.
   1. In the _API (Enable OAuth Settings)_ section:
      1. Check _Enable OAuth Settings_
      1. _Callback URL_ is unused in the JWT flow but a value is required nonetheless.  Use "http://localhost/" or some other dummy host.
      1. Check _Use digital signatures_.  Upload the _salesforce.crt_ that was generated earlier.
      1. For _Selected OAuth Scopes_, add _Access and manage your data (api)_ and _Perform requests on your behalf at any time (refresh_token, offline_access)_
   1. Click _Save_.  If there are any errors, you have to re-upload _salesforce.crt_.
1. On the resulting app page, click _Manage_.
   1. Click _Edit Policies_.
   1. In the _OAuth policies_ section, change _Permitted Users_ to _Admin approved users are pre-authorized_.
   1. Click _Save_.
1. Back on the app page again, in the _Profiles_ section, click _Manage Profiles_.
   1. On the _Application Profile Assignment_ page, assign the user profiles that will have access to this app.


##### OAuth Access Configuration

To use the API, the RSA private key and the _Consumer Key_ (aka client ID) from the Salesforce application are needed.

1. The private key is the key that was generated in the _Prequisite_ section above.
1. To get the Salesforce application _Consumer Key_, do the following
   1. Login to salesforce.
   1. Go to setup area (gear in the nav in the top right)
   1. In the side nav, go to _Apps_ > _App Manager_
   1. In the list, find the application that you created in the _App Creation_ section above
   1. From the drop down in the application's row, click _View_
   1. The _Consumer Key_ is in the _API (Enable OAuth Settings)_ section.
   
##### Run jwtGenerator.py script

Install dependencies, running with python3's pip:
```pip3 install pyJWT cryptography requests```

Open the file jwtGenerator.py which you can find in this repository and update the following variables:

- IS_SANDBOX
    - If the org for which you are producing the jwt is a sandbox or not
- KEY_FILE
    - The private key of your pair of certificates
- ISSUER
    - The client id of your connected app
- SUBJECT
    - The user name of a salesforce user.
    
You can also play with the EXPTIME value if you wish. This is a time in seconds of the token expiration.

Running the script produces a file **jwt.txt** in the same location as your script which content is the token we want to use.

To run the script just do:
``` python3 jwtGenerator.py```

##### Parting Tips
- To see successful OAuth logins, see the _Session Management_ page.
- Help: https://salesforce.stackexchange.com/questions/207685
- For more info including a poorly done Java example, see https://help.salesforce.com/articleView?id=remoteaccess_oauth_jwt_flow.htm&type=5

