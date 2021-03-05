/*
 * Created by Artem on 03 March 2010
 * 
 */

trigger OpportunityContactRoleTrigger on OpportunityContactRole (before insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        OpportunityContactRoleTriggerHandler.setContactIdOnOpportunity(Trigger.New); 
    }
}