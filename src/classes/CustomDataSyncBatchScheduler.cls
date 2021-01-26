/*
 * created by : angel robles
 * created date : 1/25/2021
 * test class : CustomDataSyncBatchTest
 */ 
global class CustomDataSyncBatchScheduler implements Schedulable {
    public integer take {get;set;}
   
    global CustomDataSyncBatchScheduler(integer take){
        this.take = take;
    }
   global void execute(SchedulableContext sc) {
      database.executebatch(new CustomDataSyncBatch(this.take, 'records', null, null ), 1);
   }
}