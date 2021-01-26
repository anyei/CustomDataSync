/*
 * created by : angel robles
 * test class : CustomDataSyncControllerTest
 */ 
public with sharing class CustomDataSyncController {
    @AuraEnabled
    public static map<string, ObjectDescribeResult > fetchFieldsOfObject(string objectToDescribe) {
        Map<String, ObjectDescribeResult> result = new map<string, ObjectDescribeResult>();
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new List<string>{objectToDescribe});
        for(Schema.DescribeSobjectResult res : results) {
            
            ObjectDescribeResult describedObject = new ObjectDescribeResult();
            describedObject.apiName = res.getName();
            describedObject.label = res.getLabel();
            describedObject.isAccessible = res.isAccessible();
            describedObject.isCreateable = res.isCreateable();
            describedObject.isUpdateable = res.isUpdateable();
            describedObject.isDeletable = res.isDeletable();
            describedObject.fields = new map<string, FieldDescribeResult>();
            
            Map<String, Schema.SObjectField> fieldMap =  res.fields.getMap();
            
            for(string field_name : fieldMap.keySet()){                
                
                if(fieldMap.containsKey(field_name)){
                    Schema.DescribeFieldResult fieldResult = fieldMap.get(field_name).getDescribe();
                    Schema.DisplayType fType = fieldResult.getType();
                    List<Schema.SObjectType> targetObjectLookup = fieldResult.getReferenceTo();
                    FieldDescribeResult fd = new FieldDescribeResult();
                    fd.isAccessible = fieldResult.isAccessible();
                    fd.isUpdateable = fieldResult.isUpdateable();
                    fd.isCalculated = fieldResult.isCalculated();
                    fd.isAutoNumber = fieldResult.isAutoNumber();
                    fd.isRequired = fieldResult.isNillable();
                    fd.isDependant = fieldResult.isDependentPicklist();
                    fd.inlineHelpText = fieldResult.getInlineHelpText();
                    fd.apiName = fieldResult.getName();
                    fd.label = fieldResult.getLabel();
                    fd.data_type = ftype.name().tolowercase();
                    describedObject.fields.put(field_name, fd);
                    
                }  
            }
            
            result.put(describedObject.apiName, describedObject);
        }
        
        return result;
    } 
    
    @AuraEnabled 
    public static List<string> fetchUserPreference(string userId, boolean isAdmin){
        List<string> result = new List<string>();
        for( Custom_Data_Sync_Field_Preference__c record : (isAdmin != null && isAdmin ? [select Name from Custom_Data_Sync_Field_Preference__c where Preference_Scope__c = 'Batch' ] : [select Name from Custom_Data_Sync_Field_Preference__c  where User__c=:userId] ) ){
            result.Add(record.Name);
        }
        return result;
    }
    
    @AuraEnabled
    public static void saveSyncFields(string userId, List<string> fields, boolean isAdmin){
        
        //just clean everything from the current user
        delete (isAdmin != null && isAdmin ? [select id from Custom_Data_Sync_Field_Preference__c  where Preference_Scope__c='Batch'] : [select id from Custom_Data_Sync_Field_Preference__c  where User__c=:userId] ) ;
        
        //now generate the list of selected fields
        List< Custom_Data_Sync_Field_Preference__c > toInsert = new List< Custom_Data_Sync_Field_Preference__c >();
        for(string field : fields) toInsert.Add(new Custom_Data_Sync_Field_Preference__c (Preference_Scope__c=(isAdmin != null && isAdmin ? 'Batch' : 'User'), User__c=(isAdmin != null && isAdmin ? null : userId), Name=field));
        insert toInsert;
    }
    
    @AuraEnabled 
    public static list<object> syncDataAdHoc(string userId, List<map<string,object>> data){
        CustomDataSyncHelper.loadConfig();
        return CustomDataSyncHelper.upsertWithComposite(data, system.label.customDataSyncTargetObject);
    }
    
    @AuraEnabled
    public static List<sobject> fetchObjectRecords(string term, string selectfields, string filterfield, string targetobj, integer take, integer offset){
        string likeTerm = '%' + term +'%';
        if(!selectFields.contains(','+system.label.customDataSyncFixedExternalId ) && !selectFields.contains(system.label.customDataSyncFixedExternalId+',') )
            selectFields += ','+system.label.customDataSyncFixedExternalId;
        string q= 'select id,'+selectfields + ' from '+targetobj +
            (!string.isEmpty(filterfield) && !string.isEmpty(term) ? ' where ' + filterfield + ' like :likeTerm' : '') +
            ' limit ' + take + ' offset ' + offset;
        return database.query(q);
    }
    
    @AuraEnabled
    public static string getCurrentUserProfileId(string userId){
        return [select ProfileId from User where Id=:userId limit 1].ProfileId;
    }
    
    public class FieldDescribeResult{
        @auraEnabled public string data_type {get;set;}
        @auraEnabled public boolean isAccessible {get;set;}
        @auraEnabled public boolean isCalculated {get;set;}
        @auraEnabled public boolean isUpdateable {get;set;}
        @auraEnabled public boolean isAutoNumber {get;set;}
        @auraEnabled public boolean isRequired {get;set;}
        @auraEnabled public boolean isDependant {get;set;}
        @auraEnabled public string inlineHelpText {get;set;}
        @auraEnabled public string label {get;set;}
        @auraEnabled public string apiName {get;set;}
    }
    public class ObjectDescribeResult {
        @auraEnabled public string apiName {get;set;}
        @auraEnabled public string label {get;set;}
        @auraEnabled public boolean isAccessible {get;set;}
        @auraEnabled public boolean isCreateable {get;set;}
        @auraEnabled public boolean isDeletable {get;set;}
        @auraEnabled public boolean isUpdateable {get;set;}
        @auraEnabled public map<string, FieldDescribeResult> fields {get;set;}
    }
    



}