/**
 * Created by wildrey on 24.03.2020.
 */

public with sharing class LeadTriggerHandler {

    public static void updateLeadProcessBuilder(List<Lead> newLeads){

        List<Id> accListIds = new List<Id>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();

        for (Lead item: newLeads){
            if (item.LeanData__Routing_Status__c == 'routed - round-robin' || item.LeanData__Routing_Status__c == 'routed - update') {
                accListIds.add(item.LD_Matched_Account_Name__c);
                leadMap.put(item.LD_Matched_Account_Name__c, item);

            }else if (item.engagio__Matched_Account_Name__c != null
                    && item.engagio__Matched_Account__r.Software_Score__c  >= 4) {
                item.Target_Account__c = true;
            }
        }
        if (!accListIds.isEmpty()) {

            List<Account> listAccountsToUpdate = [SELECT Id, BDR_Owner__c FROM Account WHERE Id IN: accListIds];
            if (!listAccountsToUpdate.isEmpty()) {
                for (Account ac: listAccountsToUpdate){
                    ac.BDR_Owner__c = leadMap.get(ac.Id).LD_BDR_Owner__c;
                }
                update listAccountsToUpdate;
            }
        }
    }
    
    public static void setFirstPrimaryContactOnOpportunity(List<SObject> oldSobjects, Map<Id, SObject> idNewSObject){  // created 02.03.2021 (Artem)
        List<Lead> oldLeads =(List<Lead>) oldSobjects;
        
        Map<Id, Lead> idNewLead = new Map<Id, Lead>();  
        for(Id leadId : idNewSObject.keySet()){
            idNewLead.put(leadId,(Lead)idNewSObject.get(leadId));
        }
        
        List<Lead> convertedLeads = new List<Lead>();
        
        for(Lead lead : oldLeads){            
            if(lead.isConverted == false && idNewLead.get(lead.Id).isConverted == true){               
                convertedLeads.add(lead);
            }
        }  
        
        if(convertedLeads.size() != 0){
            
            Map<Id, Id> opportunityIdContactId = new Map<Id, Id>();
            List<Id> opportunitiesIds = new List<Id>();
            
            Lead newLead;
            for(Lead lead : convertedLeads){   
                newLead = idNewLead.get(lead.Id);               
                if(newLead.ConvertedOpportunityId != null && newLead.ConvertedContactId != null){                   
                    opportunitiesIds.add(newLead.ConvertedOpportunityId);
                    opportunityIdContactId.put(newLead.ConvertedOpportunityId, newLead.ConvertedContactId);                   
                }            
            }            
                        
            if(opportunitiesIds.size() != 0){
                List<Opportunity> convertedOpportunities = [
                    SELECT Id, Outreach_First_Primary_Contact__c  
                    FROM Opportunity
                    WHERE Id IN :opportunitiesIds
                ]; 
                
                if(convertedOpportunities.size() != 0){
                    for(Opportunity opp : convertedOpportunities){
                        opp.Outreach_First_Primary_Contact__c = opportunityIdContactId.get(opp.Id);
                    }
                    update convertedOpportunities;
                }                
            }           
              
        }      
    }
}