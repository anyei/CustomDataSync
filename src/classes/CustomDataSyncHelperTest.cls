/*
 * created by 	: angel robles
 * created date : 1/20/2021
 * test class   : CustomDataSyncHelperTest 
 * */
@istest
public class CustomDataSyncHelperTest implements HttpCalloutMock  {
	public static boolean returnInProgressStatus = false;
    public HTTPResponse respond(HTTPRequest req){

        HttpResponse res = new HttpResponse();

        res.setHeader('Content-Type', 'application/json');

        res.setStatusCode(200);

        string endp = req.getEndpoint();

        Map<string,object>  rawDataToReturn = new Map<string,object>();
        
        //login
        if(endp.contains(CustomDataSyncHelper.loginServiceEndpoint)){
            rawDataToReturn.put('access_token','testtokenfakestuff');
            rawDataToReturn.put('instanceUrl','https://wolf-by-night-fake.com');
            res.setBody(JSON.serialize(rawDataToReturn));
        }
        
        string upsertendpoint = CustomDataSyncHelper.targetCompositeUrl+'Contact'+'/'+'Email';
        if(endp.contains(upsertendpoint)){
            res.setBody(JSON.serialize(new list<string>{'just a fake response'}));
        }
        
        if(endp.contains(CustomDataSyncHelper.bulkApiEndpoint) && req.getMethod() == 'POST'){
            rawDataToReturn.put('id','superfakeid');
            res.setBody(JSON.serialize(rawDataToReturn));
        }
        
        if(endp.contains('/superfakeid/batches') && req.getMethod() == 'PUT'){
            rawDataToReturn.put('nothing','specific');
            res.setBody(JSON.serialize(rawDataToReturn));
            res.setStatusCode(201);        
        }
        
        string checkstatusendpoint  = CustomDataSyncHelper.bulkApiEndpoint+'superfakeid';
        if(endp.contains(checkstatusendpoint) && req.getMethod() == 'GET'){
            rawDataToReturn.put('state',(returnInProgressStatus ? 'inprogress' : 'jobcomplete') );
            res.setBody(JSON.serialize(rawDataToReturn));
        }
        
        
        
        string intentionalbrake  = CustomDataSyncHelper.bulkApiEndpoint+'superfake2id';
        if(endp.contains(intentionalbrake) && req.getMethod() == 'GET'){
            res.setStatusCode(400);
        }
        
        string getresultsendpoint = CustomDataSyncHelper.bulkApiEndpoint+'superfakeid/successfulResults';
        if(endp.contains(getresultsendpoint) && req.getMethod() == 'GET'){
            
            res.setHeader('Content-Type','text/csv');
            res.setBody(fakeCsvData());
        }
        
        string getfailedresultsendpoint = CustomDataSyncHelper.bulkApiEndpoint+'superfakeid/failedResults';
        if(endp.contains(getfailedresultsendpoint) && req.getMethod() == 'GET'){
            
            res.setHeader('Content-Type','text/csv');
            res.setBody(fakeCsvDataFailed());
        }
        
        return res;

    }
    
    @testsetup static void setup(){
        List<Custom_Data_Sync_Field_Preference__c> configFields = new List<Custom_Data_Sync_Field_Preference__c>{
          new Custom_Data_Sync_Field_Preference__c(Name = 'FirstName', preference_scope__c = 'batch'),
          new Custom_Data_Sync_Field_Preference__c(Name = 'Email', preference_scope__c = 'batch')  

        };
        insert configFields;
        
        insert new Contact(FirstName = 'angel', LastName='robles', email='angelmercedes@hotmail.com');
    }
    
    @istest
    public static void loadConfigTest(){
        GenerateMockConfig();
        
        test.starttest();
        CustomDataSyncHelper.loadConfig();
        test.stoptest();
        
        system.assert(CustomDataSyncHelper.configMap.get('target').get('jwt') == 'fakejwttarget');
        
    }
    
    @istest
    public static void loginTest(){
        GenerateMockConfig();
        
         boolean result = false;
        test.starttest();
        result = CustomDataSyncHelper.login('target');
        test.stoptest();
        
        system.assert(result);
        
        
        
    }
    
    @istest
    public static void upsertWithCompositeTest(){
        GenerateMockConfig();
        list<object> result = new list<object>();
        
        test.starttest();
        result = CustomDataSyncHelper.upsertWithComposite(new list<object>{
            new map<string,object> {'FirstName'=>'something'}
        }, 'Contact');
        test.stoptest();
        
        system.assert(string.valueof(result[0]) == 'just a fake response');
        
    }
    
    @istest
    public static void createBulkApiUpsertRequestJobTest(){
        GenerateMockConfig();
        
        string jobid = '';
        test.starttest();
        jobid = CustomDataSyncHelper.createBulkApiUpsertRequestJob('any', '[{"fake":"data"}]');
        test.stoptest();
        
        system.assert(jobid == 'superfakeid');
    }
    
    @istest
    public static void bulkApiCheckUpsertRequestStatusTest(){
        GenerateMockConfig();
        
        string jobid = 'superfakeid';
        string result = '';
        test.starttest();
        result = CustomDataSyncHelper.bulkApiCheckUpsertRequestStatus(jobid);
        test.stoptest();
        
        system.assert(result == 'jobcomplete');
        
    }
    
    @istest
    public static void bulkApiCheckUpsertRequestStatusFailedTest(){
        GenerateMockConfig();
        
        string jobid = 'superfake2id';
        string result = '';
        test.starttest();
        try{
        	result = CustomDataSyncHelper.bulkApiCheckUpsertRequestStatus(jobid);
        }catch(CustomDataSyncHelper.CustomDataSyncHelperException err){
            result = 'failedgood';
        }
        test.stoptest();
        
        system.assert(result == 'failedgood');
        
    }
    
    @istest
    public static void bulkApiGetUpsertSuccessResultsTest(){
        GenerateMockConfig();
        string result = '';
        test.starttest();
        result = CustomDataSyncHelper.bulkApiGetUpsertSuccessResults('superfakeid');
        test.stoptest();
        
        system.assert(result == fakeCsvData());
    }
    
    @istest
    public static void bulkApiGetUpsertFailedResultsTest(){
        GenerateMockConfig();
        string result = '';
        test.starttest();
        result = CustomDataSyncHelper.bulkApiGetUpsertFailedResults('superfakeid');
        test.stoptest();
        
        system.assert(result == fakeCsvDataFailed());
    }
    
    @istest
    public static void getCsvRecordsTest(){
        GenerateMockConfig();
        
		string results = '';
		test.starttest();
		results = CustomDataSyncHelper.getCsvRecords(100);
		test.stoptest(); 
        
        system.assert(results == contactCSVFormat());
    }
    
    public static void GenerateMockConfig(){
        CustomDataSyncHelperTest mockHttpHandler = new CustomDataSyncHelperTest();
        Test.setMock(HttpCalloutMock.class, mockHttpHandler);
        
        CustomDataSyncHelper.targetOrg = new Custom_Data_Sync_Target_Org__mdt(
            External_Id_Field__c = 'Email',
            SourceDomain__c = 'https://login.salesforce.com',
            SourceJWT__c='fakejwt', 
            JWT__c='fakejwttarget', 
            Domain__c = 'https://login.salesforce.com'
        );
        
        map<string,string> s = CustomDataSyncHelper.configMap.get('source');
        s.put('jwt', 'testjwtfakesource');
        s.put('domain', 'https://login.salesforce.com');
        CustomDataSyncHelper.configMap.put('source',s);
            
         map<string,string> t = CustomDataSyncHelper.configMap.get('target');
         t.put('jwt', 'testjwtfakesource');
         t.put('domain', 'https://login.salesforce.com');
         CustomDataSyncHelper.configMap.put('target',t);
    }
    
    static string fakeCsvData(){
        string csvheader = '"some","fake","csv","header"\n';
        string csvdata = '"somedata","fakedata","csvdata","nopdata"\n';
            csvdata += '"somedata","fakedata","csvdata","nopdata"';
        return csvheader+csvdata;
    }
    
    static string fakeCsvDataFailed(){
        string csvheader = '"some","fake","csv","header"\n';
        string csvdata = '"somedataE","fakedata","csvdata","nopdata"\n';
            csvdata += '"somedataE","fakedata","csvdata","nopdata"';
        return csvheader+csvdata;
    }
    
    static string contactCSVFormat(){
        string csvheader = '"firstname","Email"\n';
        string csvdata = '"angel","angelmercedes@hotmail.com"';
        return csvheader+csvdata;
    }
}