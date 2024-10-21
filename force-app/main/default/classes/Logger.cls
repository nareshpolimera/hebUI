public without sharing class Logger {

    private final List<String> logMessages;
    private final String context;

    public boolean isNotEmpty{
        get{
            return this.logMessages != null && !this.logMessages.isEmpty();
        }
    }    

    public String getContext(){
        return this.context;
    }

    public List<String> getMessages(){
        return this.logMessages;
    }

    public Logger(String context) {
        this(context, new List<String>());
    }

    public Logger(String context, List<String> logMessages) {
        this.context = context;
        this.logMessages = logMessages;
    }

    public String printLogs() {
        return String.join(logMessages, '\n');
    }

    public void debug(String message) {
        debug(message, null);
    }

    public void debug(String message, Object[] args) {
        logMessage(LogLevel.DEBUG, message, args, null);
    }

    public void info(String message){
        info(message, null);
    }

    public void info(String message, Object[] args) {
        logMessage(LogLevel.INFO, message, args, null);
    }

    public void warn(String message){
        warn(message, null);
    }

    public void warn(String message, Object[] args) {
        logMessage(LogLevel.WARN, message, args, null);
    }

    public void error(String message){
        error(message, null, null);
    }

    public void error(String message, Exception ex){
        error(message, null, ex);
    }

    public void error(String message, Object[] args) {
        error(message, args, null);
    }

    public void error(String message, Object[] args, Exception ex) {
        logMessage(LogLevel.ERROR, message, args, ex);
    }

    public void fatal(String message){
        fatal(message, null, null);
    }

    public void fatal(String message, Exception ex){
        fatal(message, null, ex);
    }

    public void fatal(String message, Object[] args) {
        fatal(message, args, null);
    }

    public void fatal(String message, Object[] args, Exception ex) {
        logMessage(LogLevel.FATAL, message, args, ex);
    }

    public string getTraceId(String type){
        switch on type {
            when 'REQUEST_ID' {
                return Request.getCurrent().getRequestId();
            }
            when else {
                return UserInfo.getUserId() + '|' + Request.getCurrent().getRequestId();
            }
        }
    }

    private void logMessage(LogLevel logLevel, String message, Object[] args, Exception ex) {

        String messageToLog = DateTime.now().format('yyyy-MM-dd\'T\'HH:mm:ss') + ' | ' + logLevel.toString();
        
        messageToLog = args == null 
            ? messageToLog + ' | ' + message
            : messageToLog + ' | ' + String.format(message, args);

        if (ex != null) {
            messageToLog = messageToLog + '\nMessage: ' + ex.getMessage() + '\nStracktrace: ' + ex.getStackTraceString();
        }

        logMessages.add(messageToLog);

    }
}