import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const maxAlowedRowsToSelect = 20;
export default class CustomDataSyncRecordsPicker extends LightningElement {
    
    /*
        Api and Track Fields
    */
    @api
    columns;

    @api
    options;

    @api
    records;

    @api
    shownext;

    @api
    showprevious;

    @api
    currentrecordpage=0;

    @track
    selectedRows={};

    /*
        Getters
    */

    get allSelectedRecordsForTable(){
        return [...this.allSelectedRows];
    }

    /*
        Fields
    */
    searchTerm;
    ddvalue="FirstName";
    maxRows=maxAlowedRowsToSelect;
    busy=false;
    showValidationMessage=false;
    allSelectedRows=[];
    

    handleDropDownChange(event) {
        this.ddvalue = event.detail.value;
        alert(this.ddvalue);
    }
    searchChangeHandler(event){
        this.searchTerm = event.target.value;
    }
    searchActionHandler(bypass){
        if(bypass || this.searchTerm.length > 3 ){
            const searchEvent = new CustomEvent('search',{
                detail:{ term:this.searchTerm, filterby:this.ddvalue, newsearch:true, selected:this.computeSelectedData() }
            });

            this.dispatchEvent(searchEvent);
            this.cleanUpSelectedRows();
        }
    }
    connectedCallback(){
       this.searchActionHandler(true);
       this.calculateAllSelectedRows();

    }
    previousActionHandler(){
        const searchEvent = new CustomEvent('previous',{
            detail:{ term:this.searchTerm, filterby:this.ddvalue, paginationaction:'previous',selected:this.computeSelectedData() }
        });
        this.dispatchEvent(searchEvent);
        this.computeValidation();
    }
    nextActionHandler(){
        const searchEvent = new CustomEvent('next',{
            detail:{ term:this.searchTerm, filterby:this.ddvalue, paginationaction:'next',selected:this.computeSelectedData() }
        });
        this.dispatchEvent(searchEvent);
        this.computeValidation();
    }
    selectedRowsChangeHandler(event){
        var selectedRecordsForPage = [];

        for(var i=0;i<event.detail.selectedRows.length;i++)
        {
            selectedRecordsForPage.push( {...event.detail.selectedRows[i]} );
        }

        if(selectedRecordsForPage.length <= 0)
            delete this.selectedRows[this.currentrecordpage];
        else
            this.selectedRows[this.currentrecordpage] = selectedRecordsForPage;

        this.calculateAllSelectedRows();

    }
    syncData(){
        if(this.computeValidation()) return;

       if(Object.keys(this.selectedRows).length > 0){
        
        const syncEvent = new CustomEvent('syncaction', {
            detail:{selected:this.computeSelectedData()}
        });
        this.dispatchEvent(syncEvent);
       }
    }
    computeSelectedData(){
        var selected = [];
        for(var prop in this.selectedRows){
            var apageSelectedRows = this.selectedRows[prop];
            for(var i =0;i<apageSelectedRows.length;i++){

                selected.push({...apageSelectedRows[i]});
            }
        }
        return selected;
    }
    handleRowAction(event){
        if(event.detail.action.name == 'show_errors'){
            this.showInfoMessage('Sync Details', (event.detail.row.statusMessage.length > 0? event.detail.row.statusMessage[0] : ''));
        }
    }
    calculateAllSelectedRows(){
        var selected = [];
        for(var prop in this.selectedRows){
            var apageSelectedRows = this.selectedRows[prop];
            for(var i =0;i<apageSelectedRows.length;i++){
                selected.push(apageSelectedRows[i].Id);
            }
        }
        this.allSelectedRows = selected;
        this.computeValidation();
    }
    computeValidation(){
        const result = this.allSelectedRows.length > this.maxRows;
        if(result){
            this.showWarningMessage('Validation error',`Too many rows selected ${this.allSelectedRows.length} max allowed ${this.maxRows}.`);
        }
        return result;
    }
    cleanUpSelectedRows(){
        this.allSelectedRows = [];
        this.selectedRows={};
    }
    showWarningMessage(title, message){
        this.showToastMessage(title, message, 'warning');
    }
    showInfoMessage(title, message){
        this.showToastMessage(title, message, 'info');
    }
    showToastMessage(title, message, type){
        const warningMessageEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: type,
            mode: 'dismissable'
        });
        this.dispatchEvent(warningMessageEvent)
    }

}