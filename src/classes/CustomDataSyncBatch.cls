/*
 * created by: angel robles
 * created date : 1/22/2021
 * test class CustomDataSyncBatchTest
 * 
 */
public class CustomDataSyncBatch implements Database.Batchable<object>, Database.Stateful, Database.AllowsCallouts{
   public integer take {get;set;}
    public string customBatchJobId {get;set;}
    public string itype{get;set;}
    public list<object> upsertjobidstocheckstatus {get;set;}
    public list<string> completedJobIds {get;set;}
    public list<string> errorDetails {get;set;}
   public CustomDataSyncBatch(integer take, string itype, list<object> processes, string custombatchjobid){
        this.customBatchJobId = custombatchjobid == null ? generateCustomDataSyncJobRecod() : custombatchjobid;
        this.take = take;
       this.itype = itype;
       this.upsertjobidstocheckstatus = processes == null ? new list<object>() : processes;
       this.completedJobIds = new list<string>();
       errorDetails = new list<string>();
   }
   public Iterable<object> start(Database.BatchableContext info){
       if(this.itype != 'process') updateCustomDataSyncJobRecord('In Progress', info.getJobId());
       
       list<object> toprocess = new list<object>();
       if(this.upsertjobidstocheckstatus != null) toprocess.addAll(this.upsertjobidstocheckstatus.clone());
       
       this.upsertjobidstocheckstatus = new list<object>();
       return new CustomDataSyncBatchIterable(this.take,  itype, toprocess);
   }
   public void execute(Database.BatchableContext info, List<object> scope){
       CustomDataSyncHelper.loadConfig();
       if(this.itype == 'records'){
            string upsertjobid = CustomDataSyncHelper.createBulkApiUpsertRequestJob(system.label.customDataSyncTargetObject , string.valueof(scope[0]));
           string status = checkStatus(upsertjobid).tolowercase();
           if(status == 'jobcomplete')
                getResultsAndGenerateFiles(upsertjobid);
           else if(status == 'inprogress' || status == 'uploadcomplete')
                upsertjobidstocheckstatus.add(upsertjobid);
           
           
       }
       
       if(this.itype == 'process'){
            for(object upsertjobid : scope){
                string status = checkStatus(upsertjobid).tolowercase();
                if(status == 'jobcomplete')
                        getResultsAndGenerateFiles(upsertjobid);
                   else if(status == 'inprogress' || status == 'uploadcomplete')
                        upsertjobidstocheckstatus.add(upsertjobid);
             }
       }
      
   }
    public void getResultsAndGenerateFiles(object ujobid){
        string upsertjobid = string.valueof(ujobid);
        string successResults = '';
                    try{
                        successResults = CustomDataSyncHelper.bulkApiGetUpsertSuccessResults(upsertjobid);
                    }catch(exception err){
                        errorDetails.add(err.getMessage());
                    }
                    string failedResults = '';
                    try{
                        failedResults = CustomDataSyncHelper.bulkApiGetUpsertFailedResults(upsertjobid);
                    }catch(exception err){
                        errorDetails.add(err.getMessage());
                    }
                    List<ContentVersion> cversions = new List<ContentVersion>{
                        createContentVersion('successResults_'+upsertjobid+'.csv', blob.valueof(successResults)),
                        createContentVersion('failedResults_'+upsertjobid+'.csv', blob.valueof(failedResults))
                    };
                    insert cversions; 
                    
                    List<ContentDocumentLink> toLink = new List<ContentDocumentLink>();
                    for(ContentVersion contentVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cversions]){
                        toLink.add(createContentDocumentLink(contentVersion.ContentDocumentId, this.customBatchJobId));
                    }
                    insert toLink;
    }
     private ContentVersion createContentVersion(String name, blob body)
    {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S'; // S = Stored in Salesforce
        contentVersion.PathOnClient = name;
        contentVersion.Title = name;
        contentVersion.VersionData = body;
        return contentVersion;
    }
    private ContentDocumentLink createContentDocumentLink(Id contentDocumentId, Id parentId){
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentDocumentId;
        contentDocumentLink.LinkedEntityId = parentId;
        contentDocumentLink.ShareType = 'I';
        return contentDocumentLink;
    }
    public string checkStatus(object upsertjobid){
        string status = '';
        try{
              status = CustomDataSyncHelper.bulkApiCheckUpsertRequestStatus(string.valueof(upsertjobid));
          }catch(exception err){
                errorDetails.add(err.getMessage());
           }
          if(status.toLowerCase() == 'jobcomplete'){
               this.completedJobIds.add(string.valueof(upsertjobid));
          }
        return status;
    }
   public void finish(Database.BatchableContext info){
       system.debug(string.join(errorDetails, ' '));
       if(upsertjobidstocheckstatus.size() > 0){
           CustomDataSyncBatch batch = new CustomDataSyncBatch(this.take, 'process', upsertjobidstocheckstatus, this.customBatchJobId);
           update new Custom_Data_Sync_Batch_Execution__c(Detail__c=string.join(errorDetails, ' '), id=customBatchJobId);
           database.executeBatch(batch, 1);
       }else{
            update new Custom_Data_Sync_Batch_Execution__c(state__c='Complete', Finish_Time__c=DateTime.Now(), id=customBatchJobId);
       }
       
   }
    
    public string generateCustomDataSyncJobRecod(){
        Custom_Data_Sync_Batch_Execution__c  record = new Custom_Data_Sync_Batch_Execution__c (start_time__c=datetime.now(), state__c='Created' );
        insert record;
        return record.id;
    }
    public void updateCustomDataSyncJobRecord(string state, string apexjobid){
        update new Custom_Data_Sync_Batch_Execution__c(state__c=state, id=customBatchJobId, Apex_Job_Id__c  = apexjobid);
    }
    
}