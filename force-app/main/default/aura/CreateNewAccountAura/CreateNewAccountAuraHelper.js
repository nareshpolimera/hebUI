({
    closeTab: function(component) {
        var workspaceAPI;
        try {
            workspaceAPI = component.find("workspace");
        } catch (error) {
            console.log(error);
        }
        console.log('workspaceAPI: '+workspaceAPI);
        if (workspaceAPI) {
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                console.log('Sending close event');
                workspaceAPI.closeTab({ tabId: focusedTabId });
            })
            .catch(function(error) {
                console.log('Error closing tab:', error);
            });
        } else {
            console.error('Workspace API not found.');
        }
    }
})