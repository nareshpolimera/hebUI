public with sharing class LoggerDMLService {

    public static void saveLog(Logger toSave){
        saveLogs(new list<Logger>{toSave});
    }

    public static void saveLogs(List<Logger> toSave){

        if(toSave == null || toSave.isEmpty()){
            return;
        }

        List<Process_Log__c> logsToInsert = new List<Process_Log__c>();

        DateTime currentTime = DateTime.now();

        Schema.DescribeFieldResult dfr = Process_Log__c.Log_Message__c.getDescribe();

        for(Logger log : toSave){
            if(log.isNotEmpty){

                //check max log size
                String logMsg = log.printLogs();
                if(String.isEmpty(logMsg)){
                    continue;
                }

                Integer logParts = 1;
                Integer maxLength = dfr.getLength();
                Integer msgLength = logMsg.length();
                if(maxLength < msgLength){
                    //split log message into multiple parts
                    Decimal value = msgLength / maxLength;
                    logParts = (value.round(RoundingMode.HALF_UP)).intValue();
                }

                for(Integer i = 0; i < logParts; i++){
                    Process_Log__c newLog = new Process_Log__c();
                    newLog.Context__c = log.getContext();
                    newLog.CreatedDate__c = currentTime;
                    newLog.CreatedById__c = UserInfo.getUserId();
                    newLog.Request_Id__c = log.getTraceId('REQUEST_ID');
                    Integer endIndex = 0;
                    if( (i+1) == logParts){
                        //last part
                        endIndex = msgLength;
                    }
                    else{
                        endIndex = (i*maxLength) + maxLength;
                    }
                    newLog.Log_Message__c = logMsg.subString((i*maxLength),endIndex);
                    newLog.Log_Part__c = i;
                    logsToInsert.add(newLog);
                }
            }
        }

        if(!logsToInsert.isEmpty()){
            insert logsToInsert;
        }
    }
}