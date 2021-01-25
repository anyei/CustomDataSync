/*
 * created by : angel robles
 * created date: 1/22/2021
 * test class CustomDataSyncBatchIteratorTests
 * 
 * */
public class CustomDataSyncBatchIterator implements Iterator<object> {
 
   private integer take;
   private string custombatchjobid;
   private string contentResponse;
   private integer currentIndex;
   private list<object> processes;
   string itype;
 
   public CustomDataSyncBatchIterator(integer take, string itype, list<object> processes){
       this.take = take;
       this.itype = itype;
       this.currentIndex = 0;
       this.processes = processes;
       
       if(itype == 'records'){
       		contentResponse = CustomDataSyncHelper.getCsvRecords(take);
       }
             
   }
   
 
   public boolean hasNext(){ 
       boolean result = false;
       if(itype == 'records') result = !string.isEmpty(contentResponse) && contentResponse != 'NO_RECORDS';
       if(itype == 'process'){
          result = this.currentIndex <= processes.size() -1;  
       } 
       return result;
   }    
 
   public object next(){
       if(hasNext()) {
           
           if(itype == 'records'){
               string toReturn = this.contentResponse;
               this.contentResponse = CustomDataSyncHelper.getCsvRecords(take);
               return toReturn;
           }
           if(itype == 'process'){
               integer toreturn = this.currentIndex;
               this.currentIndex ++;
               return this.processes[toreturn];
           }
          
       } else {
           throw new NoSuchElementException();
       }
       return null;
   } 
    /*
   void computeBoundId(){
       this.boundid='';
           //list<sobject> records = database.query('select id from '+ system.label.customDataSyncTargetObject +' order by id limit '+this.take);
           //this.boundid = records.size() > 0 ? string.valueof(records[records.size() - 1].get('id')) : '';
           //string lastboundid = this.boundid;
           //list<sobject> records = database.query('select id from '+ system.label.customDataSyncTargetObject +' where id > \''+ lastboundid +'\' order by id limit 1');
          // this.boundid = records.size() > 0 ? string.valueof(records[0].get('id')) : '';
       if(!string.isEmpty(contentResponse) && contentResponse != 'NO_RECORDS'){
            list<string> lines = contentResponse.split('\n');
            string lastline = lines[lines.size() -1];
            try{
               string biddirty = lastline.substring(0, 20);
               boundid = biddirty.remove('"');
           }catch(Exception err){
               system.assert(false, lastline);
            } 
       }
    }*/
}