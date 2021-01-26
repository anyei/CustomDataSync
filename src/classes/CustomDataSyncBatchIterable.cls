/*
 * created date : 1/23/2021
 * create by : angel robles
 * test class : CustomDataSyncBatchTest
 * 
 */ 
public class CustomDataSyncBatchIterable implements Iterable<object> {
    integer take;
    string itype;
    list<object> processes;
    public CustomDataSyncBatchIterable(integer take, string itype, list<object> processes){
        this.take =take;
        this.itype = itype;
        this.processes = processes;
    }
   public Iterator<object> iterator(){
      return new CustomDataSyncBatchIterator(this.take, this.itype, this.processes);
   }
}