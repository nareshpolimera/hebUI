public without sharing class LogLevel {

    public static final LogLevel TRACE = new LogLevel(LoggingLevel.FINE, 0, 'TRACE');
    public static final LogLevel DEBUG = new LogLevel(LoggingLevel.DEBUG, 1, 'DEBUG');
    public static final LogLevel INFO = new LogLevel(LoggingLevel.INFO, 2, 'INFO');
    public static final LogLevel WARN = new LogLevel(LoggingLevel.WARN, 3, 'WARN');
    public static final LogLevel ERROR = new LogLevel(LoggingLevel.ERROR, 4, 'ERROR');
    public static final LogLevel FATAL = new LogLevel(LoggingLevel.ERROR, 5, 'FATAL');
    public static final LogLevel NONE = new LogLevel(LoggingLevel.NONE, 100, 'NONE');

    private final LoggingLevel systemLoggingLevel;
    private final Integer level;
    private final String name;
    
    public LogLevel(LoggingLevel systemLoggingLevel, Integer level, String name) {
        this.systemLoggingLevel = systemLoggingLevel;
        this.level = level;
        this.name = name;
    }

    public override String toString() {
        return name;
      }
}