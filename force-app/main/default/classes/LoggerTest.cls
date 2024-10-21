@isTest
public with sharing class LoggerTest {

    @isTest 
    static void test_Log() {

        test.startTest();

        Logger theLog = new Logger('Test Context');
        theLog.info('A test to log');
        theLog.info('A test to log with parameters {0}',new Object[]{'value'});
        theLog.debug('A test to log');
        theLog.debug('A test to log with parameters {0}',new Object[]{'value'});
        theLog.warn('A test to log');
        theLog.warn('A test to log with parameters {0}',new Object[]{'value'});
        theLog.error('A test to log');
        theLog.error('A test to log', new DmlException('Test Error'));
        theLog.error('A test to log with parameters {0}',new Object[]{'value'});
        theLog.fatal('A test to log');
        theLog.fatal('A test to log', new DmlException('Test Error'));
        theLog.fatal('A test to log with parameters {0}',new Object[]{'value'});

        test.stopTest();

        Assert.isTrue(theLog.isNotEmpty);
        Assert.areEqual('Test Context',theLog.getContext());
        Assert.isTrue(!theLog.getMessages().isEmpty());
        Assert.areNotEqual('',theLog.printLogs());
        Assert.areNotEqual('',theLog.getTraceId('REQUEST_ID'));
    }
}