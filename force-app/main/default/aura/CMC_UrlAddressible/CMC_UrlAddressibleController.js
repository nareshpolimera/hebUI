({
    onPageReferenceChange: function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        var id = myPageRef.state.c__id;
        cmp.set("v.id", id);
    },
    handleFilterChange: function(component, event) {
        try {
            
            var CloseClicked = event.getParam('focusedTabInfo');
            component.set('v.message', 'Close Clicked');
            
            console.log('workspaceAPI.getFocusedTabInfo()',CloseClicked);
            var workspaceAPI = component.find("workspace");
            workspaceAPI.getTabURL({CloseClicked}).then(function(response) {
                                    var focusedTabId = response.tabId;
                                    workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log(error);
        });}
    catch (e) {
    console.log('12312312',e);
}
 },
 })