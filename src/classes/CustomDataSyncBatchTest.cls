/*
 * created by : angel robles
 * created date : 1/25/2021
 */ 

@istest
public class CustomDataSyncBatchTest {
    
    @testsetup
    static void setup(){
        
        List<Custom_Data_Sync_Field_Preference__c> configFields = new List<Custom_Data_Sync_Field_Preference__c>{
          new Custom_Data_Sync_Field_Preference__c(Name = 'FirstName',User__c=UserInfo.getUserId(), preference_scope__c = 'User'),
          new Custom_Data_Sync_Field_Preference__c(Name = 'Email',User__c=UserInfo.getUserId(), preference_scope__c = 'User')  

        };
        insert configFields;
        
        insert new Contact(FirstName = 'angel', LastName='robles', email='angelmercedes@hotmail.com');
    }
    
    @istest
    public static void executeRecordsTest(){
        CustomDataSyncHelperTest.GenerateMockConfig();
        
        CustomDataSyncBatch b= new CustomDataSyncBatch(100, 'records',null, null);
        test.starttest();
        database.executeBatch(b, 1);
        test.stoptest();
        
        Custom_Data_Sync_Batch_Execution__c batchExecution = [select state__c from Custom_Data_Sync_Batch_Execution__c limit 1];
        
        system.assert(batchExecution.state__c== 'Complete');
    }
    
    @istest
    public static void executeProcessTest(){
        CustomDataSyncHelperTest.GenerateMockConfig();
        
         Custom_Data_Sync_Batch_Execution__c  executionRecord = new Custom_Data_Sync_Batch_Execution__c (start_time__c=datetime.now(), state__c='Created' );
        insert executionRecord;
        
        
        CustomDataSyncBatch b= new CustomDataSyncBatch(100, 'process',new list<object>{'superfakeid'}, executionRecord.id);
        test.starttest();
        database.executeBatch(b, 1);
        test.stoptest();
        
        Custom_Data_Sync_Batch_Execution__c batchExecution = [select state__c from Custom_Data_Sync_Batch_Execution__c  where id =:executionRecord.id];
        
        system.assert(batchExecution.state__c== 'Complete');
    }
    
    @istest
    public static void executeRecordsInProgressTest(){
        CustomDataSyncHelperTest.GenerateMockConfig();
        CustomDataSyncHelperTest.returnInProgressStatus = true;
         Custom_Data_Sync_Batch_Execution__c  executionRecord = new Custom_Data_Sync_Batch_Execution__c (start_time__c=datetime.now(), state__c='In Progress' );
        insert executionRecord;
        
        
        CustomDataSyncBatch b= new CustomDataSyncBatch(100, 'records',new list<object>{'superfakeid'}, executionRecord.id);
        test.starttest();
        database.executeBatch(b, 1);
        test.stoptest();
        
        Custom_Data_Sync_Batch_Execution__c batchExecution = [select state__c from Custom_Data_Sync_Batch_Execution__c  where id =:executionRecord.id];
        
        system.assert(batchExecution.state__c == 'In Progress');
    }
    
    @istest
    public static void executeProcessInProgressTest(){
        CustomDataSyncHelperTest.GenerateMockConfig();
        CustomDataSyncHelperTest.returnInProgressStatus = true;
         Custom_Data_Sync_Batch_Execution__c  executionRecord = new Custom_Data_Sync_Batch_Execution__c (start_time__c=datetime.now(), state__c='In Progress' );
        insert executionRecord;
        
        
        CustomDataSyncBatch b= new CustomDataSyncBatch(100, 'process',new list<object>{'superfakeid'}, executionRecord.id);
        test.starttest();
        database.executeBatch(b, 1);
        test.stoptest();
        
        Custom_Data_Sync_Batch_Execution__c batchExecution = [select state__c from Custom_Data_Sync_Batch_Execution__c  where id =:executionRecord.id];
        
        system.assert(batchExecution.state__c == 'In Progress');
    }
    
     @istest
    public static void CustomDataSyncBatchSchedulerTest(){
        CustomDataSyncHelperTest.GenerateMockConfig();
        boolean result = false;
        test.starttest();
        system.schedule('test schedule for me', '0 0 22 * * ? *', new CustomDataSyncBatchScheduler(10000));
        result = true;
        test.stoptest();
        
        
        system.assert(result);
    }
    
    
    

}