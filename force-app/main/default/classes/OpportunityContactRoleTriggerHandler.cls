/*
 * Created by Artem on 03 March 2010
 * 
 */

public class OpportunityContactRoleTriggerHandler {

    public static void setContactIdOnOpportunity(List<OpportunityContactRole> opportunityContactRoles){
            
        List<Id> opportunitiesIds = new List<Id>();
        
        Map<Id, Id> opportunityIdContactId = new Map<Id, Id>();
        
        for(OpportunityContactRole oppContRole : opportunityContactRoles){
            opportunityIdContactId.put(oppContRole.OpportunityId, oppContRole.ContactId);  
            opportunitiesIds.add(oppContRole.OpportunityId);
        }
        
        List<Opportunity> opportunities = [
            SELECT Id ,Outreach_First_Primary_Contact__c
            FROM Opportunity
            WHERE Id IN :opportunitiesIds
        ];
          
        if(opportunities.size() != 0){
            
            for(Opportunity opp : opportunities){
                opp.Outreach_First_Primary_Contact__c = opportunityIdContactId.get(opp.Id);
            }              
            update opportunities;           
        } 
    }
}