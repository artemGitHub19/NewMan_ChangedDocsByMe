/**
 * Created by wildrey on 24.03.2020.
 */

trigger LeadTrigger on Lead (before insert, before update, after update) {

    if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
        //Process Builder - Campaign Member Lead
        LeadTriggerHandler.updateLeadProcessBuilder(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate ) { // created by Artem 02.03.2021       
        // converting Lead 
        LeadTriggerHandler.setFirstPrimaryContactOnOpportunity(Trigger.old, Trigger.newMap);
    }
}