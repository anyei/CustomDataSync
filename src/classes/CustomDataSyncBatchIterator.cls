/*
 * created by : angel robles
 * created date: 1/22/2021
 * test class : CustomDataSyncBatchTest
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
}