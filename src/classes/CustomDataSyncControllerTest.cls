/*
 * created by : angel robles
 * created date : 1/25/2021
 */ 
@istest
public class CustomDataSyncControllerTest {

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
    public static void fetchFieldsOfObjectTest(){
        map<string, CustomDataSyncController.ObjectDescribeResult > results = null;
        test.starttest();
        results = CustomDataSyncController.fetchFieldsOfObject('Contact');
        test.stoptest();
        
        system.assert(results.get('Contact').fields.containsKey('firstname'));
    }
    
    @istest
    public static void fetchUserPreferenceTest(){
        set<string> results = null;
        test.starttest();
        results = new set<string>(CustomDataSyncController.fetchUserPreference(UserInfo.getUserId(), false));
        test.stoptest();
        
        system.assert(results.contains('FirstName') && results.contains('Email'));
    }
    
    @istest
    public static void saveSyncFieldsTest(){
        boolean result = false;
        test.starttest();
        CustomDataSyncController.saveSyncFields(UserInfo.getUserId(), new List<string>{'LastName'}, false);
        result = true;
        test.stoptest();
        
        system.assert(result);
    }
    
    @istest
    public static void syncDataAdHocTest(){
        CustomDataSyncHelperTest.GenerateMockConfig();
        list<object> result = null;
        test.starttest();
        result = CustomDataSyncController.syncDataAdHoc(UserInfo.getUserId(), new list<map<string,object>>{
            new map<string,object> {'FirstName'=>'something'}
        });
        test.stoptest();
        
        system.assert(string.valueof(result[0]) == 'just a fake response');
        
    }
    
    @istest
    public static void fetchObjectRecordsTest(){
        list<sobject> results = null;
        test.starttest();
        results = CustomDataSyncController.fetchObjectRecords('ang', 'FirstName,Email', 'FirstName', 'Contact', 100, 0);
        test.stoptest();
        
        system.assert(results.size() == 1 && string.valueof(results[0].get('FirstName')) == 'angel');
    }
    
    @istest
    public static void getCurrentUserProfileIdTest(){
        string currentprofileid = [select profileid from user where id=:UserInfo.getUserId() limit 1].ProfileId;
        string result = '';
        test.starttest();
        result = CustomDataSyncController.getCurrentUserProfileId(UserInfo.getUserId());
        test.stoptest();
        
        system.assert(result == currentprofileid);
    }
}