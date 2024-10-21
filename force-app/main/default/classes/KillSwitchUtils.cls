/**
* @File Name        : KillSwitchUtils
* @description      : Utils class to return if trigger should be running or not based on Kill Switch custom setting.
* @Modification Log :      
* -------------------------------------------------------------------------
* Ver    Date                  	Author        		   Modification     
1.0      12-July-2024       	Mrunal Bhosale         Initial Version
.......................**7070**........................
**/
public class KillSwitchUtils {
    /**************************************************************************************
* @author       Mrunal Bhosale
* @date         12/July/2024
* @description  Return false if trigger should not run
*
*******************************************************************************************/
    public static Boolean shouldTriggersRun() {
        HEB_Kill_Switch__c processSwitches = HEB_Kill_Switch__c.getInstance(UserInfo.getUserId());
        return !processSwitches.Deactivate_Triggers__c;
    }
}