import { LightningElement, api, track } from 'lwc';

export default class CustomDataSyncFieldsPicker extends LightningElement {
    @api
    options;

    @api
    value;

    @api
    isadmin;

    @api
    step;

    optionList;
   
    connectedCallback(){
        this.optionList = this.options;
    }
    searchChangeHandler(e){
        if(e.target.value){
            var lower = e.target.value.toLowerCase();
            this.optionList = this.options.filter( option => option.label.toLowerCase().includes(lower) );

        }else{
            this.optionList = this.options;
        }

        
    }

    selectedFieldsChange(e){
        this.value = e.detail.value;
    }

    saveSelectionAndContinue(e){
        var checkboxGroup = this.template.querySelector('lightning-checkbox-group');
        let stepChangeEvent;
        if(!checkboxGroup.checkValidity()) {
              // Shows the error immediately without user interaction 
              checkboxGroup.reportValidity(); 
              stepChangeEvent = new CustomEvent('customdatasyncstepchange', {
                detail:{step:this.step, completed:false, value:[...this.value], isadmin:this.isadmin} 
               });

           }else{
             stepChangeEvent= new CustomEvent('customdatasyncstepchange', {
                detail:{step:this.step, completed:true, value:[...this.value], isadmin:this.isadmin} 
               });
           }
           this.dispatchEvent(stepChangeEvent);
           
    }


}