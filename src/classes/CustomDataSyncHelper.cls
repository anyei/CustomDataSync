/*
 * created by 	: angel robles
 * created date : 1/20/2021
 * test class   : CustomDataSyncHelperTest 
 * */
public class CustomDataSyncHelper {
	static string targetCompositeUrl;
    static string targetObjectUrl;
    static string bulkApiEndpoint;
    static string bulkApiQueriesEndpoint;
    static string loginServiceEndpoint;
    static string bulkApiAsyncQueryEndpoint;
    public static map<string,map<string,string>> configMap;
    public static id boundid;
    
    //a single one for now
    public static Custom_Data_Sync_Target_Org__mdt targetOrg;
    static{
        configMap = new map<string,map<string,string>>{
            'source'=>new map<string,string>(),
            'target'=>new map<string,string>()
        };
        targetCompositeUrl = system.label.customDataSyncSalesforceCompositeEndPoint;
        bulkApiEndpoint = system.label.customDataSyncSalesforceBulkApiEndpoint; 
        loginServiceEndpoint='/services/oauth2/token';
        bulkApiQueriesEndpoint = '/services/data/v49.0/jobs/query';
        bulkApiAsyncQueryEndpoint = '/services/async/49.0/job';

    }
    
    public static void loadConfig(){
         if(targetOrg == null ) targetOrg = [select External_Id_Field__c ,SourceDomain__c,SourceJWT__c, JWT__c , Domain__c from Custom_Data_Sync_Target_Org__mdt limit 1];
        if(configMap != null){
            map<string,string> s = configMap.get('source');
            s.put('jwt', targetOrg.SourceJWT__c);
            s.put('domain', targetOrg.SourceDomain__c);
            configMap.put('source',s);
            
             map<string,string> t = configMap.get('target');
            t.put('jwt', targetOrg.JWT__c);
            t.put('domain', targetOrg.Domain__c);
            configMap.put('target',t);
        }
    }
    
    public static boolean login(string t){
        boolean result = false;
        map<string,string> c = configMap.get(t);
        if(string.isEmpty(c.get('token'))){
            string requestTokenData = 
              'grant_type=' + EncodingUtil.UrlEncode('urn:ietf:params:oauth:grant-type:jwt-bearer', 'UTF-8') +
                '&assertion='+EncodingUtil.UrlEncode(c.get('jwt'), 'UTF-8');
              
                string calloutResponse = callout(c.get('domain') + loginServiceEndpoint, 'POST', requestTokenData, new map<string,string>{
                    'Content-Type'=>'application/x-www-form-urlencoded'

                }, false, 200, t);
            
            if(calloutResponse != null){
                map<string,object> jsonResult =(map<string,object>) JSON.deserializeUntyped(calloutResponse);
                configMap.get(t).put('token',string.valueof(jsonResult.get('access_token')));
                configMap.get(t).put('instanceUrl',string.valueof(jsonResult.get('instance_url')));
                result = true;
            }
            
        }
        return result;
    }
    
    public static list<object> upsertWithComposite(List<object> records, string targetObject){
        boolean result = false;
        
        List<object> compositeRequestItems = new List<object>();
        
        for(object obj : records){
            map<string, object> record = (map<string,object>)obj;
            record.remove('Id');
            
            map<string, object> item = new map<string,object>{
                'attributes'=>new map<string, object>{'type'=>targetObject }
            };
                
            for(string k : record.keyset()){
                item.put(k, record.get(k));
            }
            compositeRequestItems.add(item);
        }
        /*for(object obj : records){
            map<string, object> record = (map<string,object>)obj;
            record.remove('Id');
            record.remove(targetOrg.External_Id_Field__c);
            compositeRequestItems.add(new map<string,object>{
                'method'=>'PATCH',
                 'url'  =>targetObjectUrl+targetObject+'/'+targetOrg.External_Id_Field__c+'/'+targetOrg.External_Id_Field__c,
                 'referenceId'=>string.valueof(dummyRefId),
                  'body'=> obj
            });
            dummyRefId++;
        }*/
        
        
        map<string, object> compositeRequestOuter = new map<string,object>{
            'allOrNone'=> false,
            'records'=>compositeRequestItems
        };
		            
        string convertedData = JSON.serialize(compositeRequestOuter);
        string jsonResponse = calloutWithLogin(targetCompositeUrl+targetObject+'/'+targetOrg.External_Id_Field__c, 'PATCH', convertedData, 'target');
        list<object> readableResponse =(list<object>) JSON.deserializeUntyped(jsonResponse);
        return readableResponse;
    }
    
    public static string createBulkApiUpsertRequestJob(string targetObject, string csvContent){
        /*
         * {
                "object" : "Contact",
                "externalIdFieldName" : name of external id field
                "contentType" : "CSV",
                "operation" : "upsert"
            }
         */
        map<string, string> bulkApiCreationRequest = new map<string,string>{
            'object'=> targetObject,
            'externalIdFieldName'=>targetOrg.External_Id_Field__c,
            'contentType' =>'CSV',
            'operation' => 'upsert'
        };
        string bulkApiCreationRequestResult = calloutWithLogin(bulkApiEndpoint, 'POST', JSON.serialize(bulkApiCreationRequest), 'target');
        map<string, object> bulkApiCreationRequestJsonResult = (map<string,object>) JSON.deserializeUntyped(bulkApiCreationRequestResult);
        
        string bulkApiUploadCsvContentResult =callout(configMap.get('target').get('instanceUrl')+bulkApiEndpoint+string.valueof(bulkApiCreationRequestJsonResult.get('id'))+'/batches', 'PUT', csvContent, new map<string,string>{
             'Content-Type'=>'text/csv'
        }, true, 201, 'target');
        
        map<string, string> bulkApiUploadCompleteRequest = new map<string,string>{
            'state'=>'UploadComplete'
        };
        string bulkApiUploadCompleteResult = calloutWithLogin(bulkApiEndpoint+string.valueof(bulkApiCreationRequestJsonResult.get('id')), 'PATCH', JSON.serialize(bulkApiUploadCompleteRequest), 'target');
        return string.valueof(bulkApiCreationRequestJsonResult.get('id'));
    }
    public static string bulkApiCheckUpsertRequestStatus(string jobid){
        string bulkApiCheckStatusResponse= calloutWithLogin(bulkApiEndpoint+string.valueof(jobid), 'GET', null, 'target');
       map<string,object> bulkApiCheckStatusJsonResponse =(map<string,object>) JSON.deserializeUntyped(bulkApiCheckStatusResponse);
        return string.valueof(bulkApiCheckStatusJsonResponse.get('state'));
    }
    public static string bulkApiGetUpsertSuccessResults(string jobid){
        return calloutWithLogin(bulkApiEndpoint+string.valueof(jobid)+'/successfulResults', 'GET', null, 'target');
    }
    public static string bulkApiGetUpsertFailedResults(string jobid){
        return calloutWithLogin(bulkApiEndpoint+string.valueof(jobid)+'/failedResults', 'GET', null, 'target');
    }
    
    public static string createBulkApiQueryRequestJob(string targetObject){
        List<Custom_Data_Sync_Field_Preference__c> fields =  [select Id, Name from Custom_Data_Sync_Field_Preference__c where preference_scope__c='batch'];
        set<string> fieldsToSelect = new set<string>();
        for(Custom_Data_Sync_Field_Preference__c fr : fields) fieldsToSelect.add(fr.Name);
        
        fieldsToSelect.add(targetOrg.External_Id_Field__c);
        
        string q= 'select '+string.join(new list<string>(fieldsToSelect), ',')+' from '+targetObject;
    
        map<string,string> bulkApiCreateQueryRequest = new map<string,string>{
            'operation'=>'query',
            'query'=>q
        };
        string bulkApiCreateQueryResponse = calloutWithLogin(bulkApiQueriesEndpoint, 'POST', JSON.serialize(bulkApiCreateQueryRequest), 'source');
        map<string,object> bulkApiCreateQueryJsonResponse = (map<string,object>)JSON.deserializeUntyped(bulkApiCreateQueryResponse);
        return string.valueof(bulkApiCreateQueryJsonResponse.get('id'));
    }
    public static string bulkApiCheckQueryStatus(string jobid){
       string bulkApiCheckStatusResponse= calloutWithLogin(bulkApiQueriesEndpoint+'/'+jobid, 'GET', null, 'source');
       map<string,object> bulkApiCheckStatusJsonResponse =(map<string,object>) JSON.deserializeUntyped(bulkApiCheckStatusResponse);
       return string.valueof(bulkApiCheckStatusJsonResponse.get('state'));
    }
    public static string bulkApiGetQueryResults(string jobid){
        return callout(configMap.get('source').get('instanceUrl')+bulkApiQueriesEndpoint+'/'+jobid+'/results', 'GET',null, null, true, 200, 'source');
    }
    
    public static map<string,string> createBulkApiAsyncQueryRequestJob(string targetObject, integer take){
        map<string, string> result = new map<string,string>();
        List<Custom_Data_Sync_Field_Preference__c> fields =  [select Id, Name from Custom_Data_Sync_Field_Preference__c where preference_scope__c='batch'];
        set<string> fieldsToSelect = new set<string>();
        for(Custom_Data_Sync_Field_Preference__c fr : fields) fieldsToSelect.add(fr.Name);
        
        fieldsToSelect.add(targetOrg.External_Id_Field__c);
        
        string q= 'select '+string.join(new list<string>(fieldsToSelect), ',')+' from '+targetObject;
    
        map<string,string> bulkApiCreateQueryRequest = new map<string,string>{
            'operation'=>'query',
            'object'=>targetObject,
            'contentType'=>'CSV'
        };
        login('source');
        string bulkApiAsyncCreateQueryResponse = callout(configMap.get('source').get('instanceUrl')+ bulkApiAsyncQueryEndpoint, 'POST', JSON.serialize(bulkApiCreateQueryRequest), new map<string,string>{
            'Content-Type'=>'application/json',
            'X-SFDC-Session'=>configMap.get('source').get('token'),
             'Sforce-Enable-PKChunking'=> 'chunkSize='+take
        }, false, 201, 'source');
        map<string,object> bulkApiCreateQueryJsonResponse = (map<string,object>)JSON.deserializeUntyped(bulkApiAsyncCreateQueryResponse);
    	string jobid = string.valueof(bulkApiCreateQueryJsonResponse.get('id'));
        
        
        string bulkApiAsyncCreateBatchQueryResponse = callout(configMap.get('source').get('instanceUrl')+ bulkApiAsyncQueryEndpoint +'/'+jobid+'/batch', 'POST', q, new map<string,string>{
            'Content-Type'=>'text/csv',
            'X-SFDC-Session'=>configMap.get('source').get('token')
        }, false, 201, 'source');
        //map<string,object> bulkApiCreateBatchQueryJsonResponse = (map<string,object>)JSON.deserializeUntyped(bulkApiAsyncCreateBatchQueryResponse);
    	integer startIdIndex = bulkApiAsyncCreateBatchQueryResponse.indexOf('<id>');
        integer endIdIndex = bulkApiAsyncCreateBatchQueryResponse.indexOf('</id>');
        string batchiddirty = bulkApiAsyncCreateBatchQueryResponse.substring(startIdIndex, endIdIndex);
        string batchid = batchiddirty.replace('<id>', '').replace('</id>','');
        result.put(jobid, batchid);
        return result;
    }
    public static list<map<string,string>> bulkApiCheckAsyncQueryStatus(string jobid, string initialBatchId){
        login('source');
        Dom.Document bulkApiAsyncCheckQueryResponse = calloutXml(configMap.get('source').get('instanceUrl')+ bulkApiAsyncQueryEndpoint+'/'+jobid+'/batch', 'GET', null, new map<string,string>{
            'Content-Type'=>'application/json',
            'X-SFDC-Session'=>configMap.get('source').get('token')
        }, false, 200, 'source');
        
        //Retrieve the root element for this document.
        Dom.XMLNode batchXmlList = bulkApiAsyncCheckQueryResponse.getRootElement();
        List<map<string,string>> batchids = new List<map<string,string>>();
        // Alternatively, loop through the child elements.
        // This prints out all the elements of the address
        for(Dom.XMLNode child : batchXmlList.getChildElements()) {
            if(child.getName().tolowercase() == 'batchinfo'){
                batchids.add(new map<string, string>{
                    child.getChildElement('id', 'http://www.force.com/2009/06/asyncapi/dataload').getText()=>child.getChildElement('state', 'http://www.force.com/2009/06/asyncapi/dataload').getText()
                     });
            }
        }
        
        Dom.Document bulkApiAsyncCheckInitialBatchQueryResponse = calloutXml(configMap.get('source').get('instanceUrl')+ bulkApiAsyncQueryEndpoint+'/'+jobid+'/batch/'+initialBatchId, 'GET', null, new map<string,string>{
            'Content-Type'=>'application/json',
            'X-SFDC-Session'=>configMap.get('source').get('token')
        }, false, 200, 'source');
        
        //Retrieve the root element for this document.
        Dom.XMLNode batchXmlList2 = bulkApiAsyncCheckInitialBatchQueryResponse.getRootElement();
        //map<string,object> bulkApiAsyncCheckQueryJsonResponse = (map<string,object>)JSON.deserializeUntyped(bulkApiAsyncCheckQueryResponse);
        batchids.add(new map<string, string>{
                    batchXmlList2.getChildElement('id', 'http://www.force.com/2009/06/asyncapi/dataload').getText()=>batchXmlList2.getChildElement('state', 'http://www.force.com/2009/06/asyncapi/dataload').getText()
                     });
        return batchids;
    }
    public static map<string,string> bulkApiGetAsyncQueryResultIds(string jobid, list<string> batchids){
        map<string,string> result = new map<string,string>();
        login('source');
        for(string batchid : batchids){
             DOM.Document bulkApiAsyncGetQueryResponse = calloutXml(configMap.get('source').get('instanceUrl')+ bulkApiAsyncQueryEndpoint+'/'+jobid+'/batch/'+batchid+'/result', 'GET', null, new map<string,string>{
                    'Content-Type'=>'application/json',
                    'X-SFDC-Session'=>configMap.get('source').get('token')
                }, false, 200, 'source');
            
            Dom.XMLNode resultXmlList = bulkApiAsyncGetQueryResponse.getRootElement();
            // Alternatively, loop through the child elements.
            // This prints out all the elements of the address
            for(Dom.XMLNode child : resultXmlList.getChildElements()) {
                if(child.getName().tolowercase() == 'result'){
                    result.put(batchid, child.gettext());
                }
            }
            
        }
        return result;
    }
    public static string bulkApiGetAsyncQueryResult(string jobid, string batchid, string resultid){
          return  callout(configMap.get('source').get('instanceUrl')+ bulkApiAsyncQueryEndpoint+'/'+jobid+'/batch/'+batchid+'/result/'+resultid, 'GET', null, new map<string,string>{
                    'Content-Type'=>'application/json',
                    'X-SFDC-Session'=>configMap.get('source').get('token')
                }, false, 200, 'source');
    }
    public static string getCsvRecords(integer take){
        string csvFormattedRecords = '';
        list<string> rows = new list<string>();
        list<string> fieldHeaderList = new list<string>();
		set<string> fieldsToSelect = new set<string>();
        boolean externalidfound = false;
        
        CustomDataSyncHelper.loadConfig();
        
        List<Custom_Data_Sync_Field_Preference__c> fields =  [select Id, Name from Custom_Data_Sync_Field_Preference__c where preference_scope__c='batch'];
        
        for(Custom_Data_Sync_Field_Preference__c fr : fields) { 
            fieldHeaderList.add('"' + fr.Name + '"');
            fieldsToSelect.add(fr.Name); 
            if(fr.Name.tolowercase() ==CustomDataSyncHelper.targetOrg.External_Id_Field__c.tolowercase() ) externalidfound =true; 
        }
        
        if(!externalidfound){ 
            fields.add( new Custom_Data_Sync_Field_Preference__c(name=CustomDataSyncHelper.targetOrg.External_Id_Field__c.tolowercase()));
        	fieldsToSelect.add(CustomDataSyncHelper.targetOrg.External_Id_Field__c.tolowercase());
            fieldHeaderList.add('"' + CustomDataSyncHelper.targetOrg.External_Id_Field__c.tolowercase() + '"');

        }
        
        string header = string.join(fieldHeaderList, ',') + '\n';
        
        Custom_Data_Sync_Field_Preference__c lastRecordField = fields[fields.size() - 1];

        
        sobject lastRecord = null;
        for(sobject record : database.query('select '+string.join(new list<string>(fieldsToSelect), ',')+' from '+system.label.customDataSyncTargetObject + (string.isempty(boundId) != true ? ' where id > \''+boundid+'\'' : '') +' order by id limit '+ take)){
            string dataRow = '';
            for(Custom_Data_Sync_Field_Preference__c field : fields){
                string value = string.valueof(record.get(field.Name));
                dataRow += '"' + (string.IsBlank(value) ? '' : value) + (lastRecordField.name != field.name ? '",' : '"');
            }
            rows.add(dataRow);
            lastRecord = record;
        } 
        csvFormattedRecords = rows.size() <= 0 ? 'NO_RECORDS' : header + string.join(rows, '\n');
        if(lastRecord != null) boundid = lastRecord.id;
		return csvFormattedRecords;
         //PageReference csvGenerator = new PageReference('/apex/CustomDataSyncCsvGenerator');
        //csvGenerator.getParameters().put('take', string.valueof(take));
        //csvGenerator.getParameters().put('bid', custombatchjobid);
        //return csvGenerator.getContent().toString();
    }
    
    public static string calloutWithLogin(string endpoint, string method, string body, string t){
        login(t);
        return callout(configMap.get(t).get('instanceUrl')+endpoint, method, body, new map<string,string>{
             'Content-Type'=>'application/json'
        }, false, 200, t);
    }
    public static string callout(string endpoint, string method, string body, map<string,string> headers, boolean doLogin, integer expectedStatusCode, string t){
        if(doLogin) login(t);
        string result = null;
        httpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);        
        if(!string.isblank(body)) req.setBody(body);
        if(string.isblank(method)) method = 'GET';
        req.setMethod(method);
        req.setHeader('Authorization','Bearer '+configMap.get(t).get('token'));
        if(headers != null){
            for(string k : headers.keyset()){
                req.setHeader(k, headers.get(k));
            }
        }
        Http client = new Http();
        httpResponse resp = null;
        resp = client.send(req);
        
        if(resp != null) result = resp.getBody();
        if( resp != null && resp.getStatusCode() != expectedStatusCode) throw new CustomDataSyncHelperException(string.valueof(resp.getStatusCode())+' '+endpoint+ ' ' + ' ' +result);
        
        return result;
        
    }
    public static Dom.Document calloutXml(string endpoint, string method, string body, map<string,string> headers, boolean doLogin, integer expectedStatusCode, string t){
        if(doLogin) login(t);
        Dom.Document result = null;
        httpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);        
        if(!string.isblank(body)) req.setBody(body);
        if(string.isblank(method)) method = 'GET';
        req.setMethod(method);
        req.setHeader('Authorization','Bearer '+configMap.get(t).get('token'));
        if(headers != null){
            for(string k : headers.keyset()){
                req.setHeader(k, headers.get(k));
            }
        }
        Http client = new Http();
        httpResponse resp = null;
        resp = client.send(req);
        
        if(resp != null) result = resp.getBodyDocument();
        if( resp != null && resp.getStatusCode() != expectedStatusCode) throw new CustomDataSyncHelperException(string.valueof(resp.getStatusCode())+' '+endpoint+ ' ' + ' ' +result);
        
        return result;
        
    }
    public class CustomDataSyncHelperException extends Exception{}
}