({
	doInit: function(component, event, helper) {
		component.set('v.showSpinner', true);

		if (!component.get('v.ownerId')) {
			component.set('v.showSpinner', false);
			component.set('v.showReport', false);
			return;
		}

        const action = component.get('c.getReport');
        
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        
        action.setParams({
            userId: component.get('v.ownerId'),
            currentDate: today
        });

		action.setCallback(this, function(response) {
			if (response.getState() === 'SUCCESS') {
			
				let responseMap = response.getReturnValue();
				let reports = [];

				for (var userId in responseMap){
					reports.push(responseMap[userId]);
                } 

				component.set('v.reports', reports);
				component.set('v.showReport', true);
			}

			component.set('v.showSpinner', false);
		});

		$A.enqueueAction(action);
	}
});