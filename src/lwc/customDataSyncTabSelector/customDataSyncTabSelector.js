import { LightningElement, track } from 'lwc';
import currentUserId from '@salesforce/user/Id';
import adminProfileId from '@salesforce/label/c.customDataSyncAdminProfileId';
import targetObject from '@salesforce/label/c.customDataSyncTargetObject'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


import fetchFields from '@salesforce/apex/CustomDataSyncController.fetchFieldsOfObject';
import fetchUserPreference from '@salesforce/apex/CustomDataSyncController.fetchUserPreference';
import fetchObjectRecords from '@salesforce/apex/CustomDataSyncController.fetchObjectRecords';
import saveSyncFields from '@salesforce/apex/CustomDataSyncController.saveSyncFields';
import syncDataAdHoc from '@salesforce/apex/CustomDataSyncController.syncDataAdHoc';
import getCurrentUserProfileId from '@salesforce/apex/CustomDataSyncController.getCurrentUserProfileId'

export default class CustomDataSyncTabSelector extends LightningElement {
    /*
        Track Fields
    */
    @track
    paginationParams={take:10, offset:0, lastrecordcount:0, shownext:false, showprevious:false};

    @track
    fieldsToShow=[];

    /*

        Regular Fields
    */
    searchedRecords=[];
    selectedSyncFields=[];
    selectedAdminSyncFields=[];
    columns=[];
    showRecordsUI;
    describedFields={};
    tableSearchByFieldOptions=[];
    currentProfileId;
    busy;
    currentRecordsPage=0;
    lastSyncResults=[];

    get isAdmin(){
        return adminProfileId == this.currentProfileId;
    }

    connectedCallback(){
        
        this.fetchSyncFields();
        this.fetchRegularUserPreference();
        this.fetchProfileAndAdminPreference();

    }

    fillSearchByFieldOptions(){
        this.tableSearchByFieldOptions = [];
        const listOfFilterByFields =['firstname','lastname'];

        for(var i=0;i<listOfFilterByFields.length; i++){
            var fieldName = listOfFilterByFields[i];
             var field = this.describedFields[fieldName];
            this.tableSearchByFieldOptions.push({label:field.label, value:field.apiName});
        }
        this.tableSearchByFieldOptions.push({label:'Account', value:'Account.Name'});
        this.tableSearchByFieldOptions.push({label:'Industry', value:'Account.Industry'});
    }

    getRowActions(row, doneCallback){
        const actions = [];
        if(row.statusIcon != undefined){
            actions.push({
                'label': 'Show Details',
                'iconName': 'utility:info',
                'name': 'show_errors'
            });
        }
        doneCallback(actions);
    }
    /*
        handler in response to the event when a field picker's value changes
    */
    stepChangeHandler(event){
        //only for regular users
        if(event.detail.step == 1){
            this.columns=[];
            this.showRecordsUI = event.detail.completed === true;

            for(var i=0;i<event.detail.value.length;i++){
                var selectedField = event.detail.value[i];
                
               if(selectedField in this.describedFields){
                    this.columns.push({label:this.describedFields[selectedField].label, fieldName:this.describedFields[selectedField].apiName});
               }
           }
           this.columns[this.columns.length - 1] = {...this.columns[this.columns.length - 1], 
            cellAttributes: { iconName: { fieldName: 'statusIcon' }, iconPosition: 'left' } 
            };
            const actions = [
                { label: 'Show details', name: 'show_details' },
            ];
            this.columns.push(
                { type: 'action', typeAttributes: { rowActions: this.getRowActions } },
            );
        }
        

       if(event.detail.completed === true){
            this.setBusy();

            //this is only for regular users
            if(event.detail.step==1){
                this.selectedSyncFields = [...event.detail.value];
            }

            //saving preference to the db
            saveSyncFields({userId : currentUserId, fields:[...event.detail.value], isAdmin:event.detail.isadmin})
            .then(result=>{
              if(event.detail.step==1) this.template.querySelector('lightning-tabset').activeTabValue = 'select-records'; 
              this.successMessage('Sync Fields','Operation completed successfully');
              this.busy=false;
            })
            .catch(error=>{
                console.log('error when saving');
                console.log(error);
                this.errorMessage('Error','Operation failed, please check with your administrator to see the operation logs.');
                this.busy=false;
            });
       }

       
    }


    /*

    Fetch data with or without searching terms
    */
    searchHandler(event){
        this.setBusy();

        if(event.detail.newsearch){
            this.paginationParams = {...this.paginationParams, offset:0, showprevious:false};
        }
            fetchObjectRecords({term:event.detail.term, selectfields:this.selectedSyncFields.join(','), filterfield:event.detail.filterby, targetobj:targetObject, take:this.paginationParams.take, offset:this.paginationParams.offset  })
            .then(result=>{
                console.log(result);
                this.searchedRecords = result;
                if(result){
                    this.paginationParams = { ...this.paginationParams, shownext:(result.length == this.paginationParams.take) };
                }
                this.computeInfoDetails(event.detail.selected);
                this.busy = false;
            })
            .catch(error=>{
                console.log('error when fetching records from object');
                console.log(error);
                this.errorMessage('Error','Error while fetching the data');

                this.busy = false;
            })
    }




    /*

    Pagination handler,
    executed as handler of the onnext and onprevious events coming from the table
    
    */
    paginationHandler(event){
        if(event.detail.paginationaction == 'next')
        {
            var newoffset = this.paginationParams.offset+this.paginationParams.take;
            this.paginationParams = { ...this.paginationParams, offset:newoffset, showprevious:true };
            this.currentRecordsPage += 1;
        }

        if(event.detail.paginationaction == 'previous' && this.paginationParams.offset > 0){
            var newoffset = this.paginationParams.offset-this.paginationParams.take;
            newoffset = newoffset < 0 ? 0 : newoffset;
            
            this.paginationParams = { ...this.paginationParams, offset:newoffset, showprevious:(newoffset > 0), shownext:true };
            this.currentRecordsPage -= 1;
        }   

        this.searchHandler(event);
    }

    syncDataActionHandler(event){
        this.setBusy();
        var tosend = event.detail.selected.map( (r)=>{
            delete r.statusIcon;
            delete r.statusMessage;
            return r;
        });

        syncDataAdHoc({userId:currentUserId, data:tosend})
        .then(result=>{
            this.lastSyncResults = result;
            this.computeInfoDetails(event.detail.selected);
            this.successMessage('Sync Success','Operation completed successfully');
            this.busy = false;
        })
        .catch(error=>{
            console.log(error);
            this.errorMessage('Error','Operation failed, please check with your administrator to see the operation logs.');
            this.busy = false;
        });
    }

    computeInfoDetails(eventSelectedData){
        if(this.lastSyncResults.length <= 0) return;
        var searchedRecordsWithStatus = [];
            for(var i=0;i<this.searchedRecords.length;i++){
                var r = this.searchedRecords[i];
                let foundIndx;
                const matchedSelected = eventSelectedData.find( (sr, indx) => {
                    foundIndx = indx;
                    return sr.Id == r.Id;
                });
                if(matchedSelected != undefined){
                    r ={ ...r, 
                            statusMessage:(this.lastSyncResults[foundIndx].success != true ? this.lastSyncResults[foundIndx].errors.map( (item)=>{
                                var itemDetail = [item.statusCode, item.message].join(' ');
                                return itemDetail;
                        }) :['Sync Success']), 
                        statusIcon: (this.lastSyncResults[foundIndx].success ? 'utility:success' : 'utility:error')
                    };
                    console.log('m');
                    console.log(r);
                }
                searchedRecordsWithStatus.push(r);
            }
            this.searchedRecords = searchedRecordsWithStatus;
    }

    /*
    FETCH HELPERS
    */
    fetchSyncFields(){
        this.setBusy();

        this.fieldsToShow=[];
       //fetching fields description to show a nice list in the ui
        fetchFields( {objectToDescribe:targetObject})
        .then(result=>{
           if(result){
            this.describedFields = result[targetObject].fields;

               for(var fieldName in result[targetObject].fields){
                   var field = result[targetObject].fields[fieldName];
                   if(field.isAccessible && field.isUpdateable){
                       this.fieldsToShow.push({label:field.label, value:fieldName});
                   }
               }
               this.busy=false;
               this.fillSearchByFieldOptions();
           }
        })
        .catch(error=>{
            console.log('error is ');
            console.log(error);
            this.errorMessage('Error','Error while fetching fields description.');
            this.busy=false;

        });
    }

    fetchRegularUserPreference(){
        this.setBusy();

        //fetching user preference
        fetchUserPreference({userId:currentUserId})
        .then(result=>{
             this.selectedSyncFields = result;
             this.busy=false;
        })
        .catch(error=>{
            console.log('error while fetching user preference');
            console.log(error);
            this.errorMessage('Error','Error while fetching user preferences.');

            this.busy = false;
        });
       
    }

    fetchProfileAndAdminPreference(){
        this.setBusy();

        //fetching the current profile id
        getCurrentUserProfileId( {userId:currentUserId})
        .then(result=>{
             this.currentProfileId = result;

               //fetching admin preference
               //has to be done after the parameteres to compute isAdmin are ready
               //thus the reason its inside this callback for getCurrentUserProfileId
             if(this.isAdmin){
                 fetchUserPreference({isAdmin:this.isAdmin})
                 .then(result=>{
                     this.selectedAdminSyncFields = result;
                     this.busy = false;
                 })
                 .catch(error=>{
                     console.log('error while fetching user preference');
                     console.log(error);
                     this.errorMessage('Error','Error while fetching admin preferences.');

                     this.busy=false;
                 });
             }


        })
        .catch(error=>{
             console.log('error while fetching profile id');
             console.log(error);
             this.errorMessage('Error','Error while fetching profiles info.');

        });
    }

    setBusy(){
        if(!this.busy) this.busy =true;
    }

    successMessage(title, message){
       this.toastMessage(title, message, 'success');
    }
    errorMessage(title, message){
        this.toastMessage(title, message, 'error');
    }
    toastMessage(title, message, type){
        const messageEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type,
            mode: 'dismissable'
        });
        this.dispatchEvent(messageEvent);
    }
    
}