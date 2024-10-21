public class DataMaskingUtils {
    public static final String AFFIRMATIVE = 'Yes';
    public static final String NEGATIVE = 'No';
  
    // Build a local cache so that we don't request this multiple times.
    private static Map<Schema.SObjectType, Map<String, Id>> rtypesCache;
    private static Map<Schema.SObjectType, Map<Id, String>> rtypesNameMapCache;
  
    public static DataMaskingUtils.Name getNameMasked(DataMaskingUtils.Name ln) {
      // NO change on firstname
      DataMaskingUtils.Name lname = new DataMaskingUtils.name();
      lname.firstname = ln.firstname;
  
      if (String.isNotBlank(ln.middlename)) {
        lname.middlename = 'xx';
      }
      if (String.isNotBlank(ln.lastname)) {
        lname.lastname = ln.lastname.left(2);
      } else {
        lname.lastname = 'LastName';
      }
  
      return lname;
    }
  
    public static String getEmailMasked() {
      //345345dummy@b2345.heb.ca.invalid
  
      String preStr = String.valueof(Math.random());
      preStr = preStr.right(preStr.length() - 10);
      System.debug('pre String = ' + preStr);
  
      List<String> alphabet = new List<String>{
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
        'i',
        'j',
        'k',
        'l',
        'm',
        'n',
        'o',
        'p',
        'q',
        'r',
        's',
        't',
        'u',
        'v',
        'w',
        'x',
        'y',
        'z'
      };
      Integer listSize = alphabet.size() - 1;
      Integer randomNumber = Integer.valueof((Math.random() * listSize));
      String randomAlphabet = alphabet[randomNumber];
      System.debug('randomAlphabet is ' + randomAlphabet);
  
      Integer randomNumber1 = Integer.valueof((Math.random() * listSize));
      String randomAlphabet1 = alphabet[randomNumber1];
      System.debug('randomAlphabet1 is ' + randomAlphabet1);
  
      Integer randomNbr = Integer.valueof((Math.random() * 1000));
      String rNbr = String.valueof(randomNbr);
  
      String newEmail =
        randomAlphabet +
        preStr +
        randomAlphabet1 +
        rNbr +
        '@uat.heb.ca';
      System.debug(' Masked Email address ' + newEmail);
      return newEmail;
    }
  
    public static String getAddressMasked() {
      //345345 Road /Ave / Street / Blvd
  
      String roadNbr = String.valueof(Math.random());
      roadNbr = roadNbr.right(8);
  
      List<String> roadName = new List<String>{
        'Frost Passage',
        'Amber Boulevard',
        'Brook Street',
        'Serenity Way',
        'Chestnut Street',
        'Bay Passage',
        'Theater Lane',
        'Earl Lane',
        'Silver Way',
        'Monument Street',
        'Moonlight Route',
        'Tower Avenue',
        'Walnut Avenue',
        'Lowland Way',
        'Polygon Avenue',
        'Knight Passage',
        'Azure Boulevard',
        'Plaza Boulevard',
        'Medieval Street',
        'Crescent Street',
        'Flint Avenue',
        'Ivory Boulevard',
        'Bath Row',
        'Coral Boulevard',
        'New Castle Avenue',
        'Museum Route',
        'Orchid Lane',
        'Medieval Passage',
        'Bay Passage',
        'Sycamore Route',
        'River Lane',
        'Route du Delta',
        'Rue du Chevalier',
        'Rue Innovation',
        'Chemin de Diamant',
        'Chemin de Romarin',
        'Rue du Noyer',
        'Rue de la Trinité',
        'Rue du Congrès',
        'Route de Perspective',
        'Voie du Fond',
        'Rue de la Plaine',
        'Route du Canal',
        'Chemin de Cailloux',
        'Voie des Séquoias',
        'Paradise Avenue',
        'Railway Street',
        'Starlight Avenue',
        'Smith Avenue',
        'Judge Row',
        'Globe Avenue',
        'East Lane',
        'Petal Avenue',
        'Shade Street',
        'Stone Way',
        'Kings Lane',
        'Prince Lane',
        'Love Avenue'
      };
  
      Integer listSize = roadname.size() - 1;
      Integer randomNumber = Integer.valueof((Math.random() * listSize));
      String randomRoadName = roadName[randomNumber];
      System.debug('Road Name = ' + randomRoadName);
  
      String newAddress = roadNbr + ' ' + randomRoadName;
      return newAddress;
    }
  
    public static String getPhoneMasked(String phonenbr) {
      //416-1234-567
      String np = phonenbr.replaceAll('(?!^\\+)[^\\d]', '');
      np = np.replace('+1', '');
      np = np.replace('+', '');
      np = np.removeStart('1');
  
      String pNbr = String.valueof(Math.random());
      pNbr = pNbr.right(7);
  
      String newPhone = np.left(3) + pNbr;
      System.debug('Old Phone Nbr  = ' + phonenbr);
      System.debug('New Phone Nbr  = ' + newPhone);
  
      return newPhone;
    }
  
    public static String getPhoneExtensionMasked() {
      String pNbr = String.valueof(Math.random());
      pNbr = pNbr.right(6);
  
      return pNbr;
    }
  
    public static Date getDOBMasked(Date dob) {
      Integer randomNbr = Integer.valueof((Math.random() * 100));
      Date newDate = dob.addDays(randomNbr);
  
      if (newDate.year() != dob.year()) {
        newDate = dob.addDays(-randomNbr);
      }
  
      return newDate;
    }
  
    public static Integer getCreditScoreMasked() {
      Integer randomNbr = Integer.valueof((Math.random() * 1000));
      if (randomNbr > 899) {
        randomNbr = randomNbr - 125;
      }
  
      return randomNbr;
    }
  
    public static void sendMSG(
      String bname,
      AsyncApexJob job,
      Integer recordsProcessed
    ) {
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
  
      // Assign the addresses for the To and CC lists to the mail object.
      //Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
      //efa.setFileName('Salesforce Data Masking Batch for ' + bname + ' Info '+String.valueOf(System.today())+'.csv');
  
      // CSV generation
      //String emailAttachmentText = 'Error Messages';
  
      /*
          for ( String err : errorLogs )
          {
              emailAttachmentText = emailAttachmentText + '\n'
                                  + err;
          }
          
          Blob b = Blob.valueOf(emailAttachmentText);
          efa.setBody(b);
  
          List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
          fileAttachments.add(efa);
          */
      String[] toAddresses = new List<String>{ 'rwang@heb.ca' };
  
      //mail.setFileAttachments(fileAttachments);
      mail.setToAddresses(toAddresses);
      String subjectline =
        'Salesforce Data Masking Batch for ' +
        bname +
        ' Info ' +
        String.valueOf(System.today());
      mail.setSubject('Daily Batch Job Status: ' + job.Status);
      mail.setPlainTextBody(
        'The batch Apex job processed ' +
        recordsProcessed +
        '    Addinitonal job info : ' +
        job.TotalJobItems +
        ' batches with ' +
        job.NumberOfErrors +
        ' failures. ExtendedStatus: ' +
        job.ExtendedStatus
      );
  
      if (!Test.isRunningTest()) {
        try {
          Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
          System.debug(
            LoggingLevel.ERROR,
            '**Error in sendEmail**' + e.getStackTraceString()
          );
        }
      }
    }
  
    public class Name {
      public String firstname;
      public String middlename;
      public String lastname;
    }
    /*
       final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < 5) {
             Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
             randStr += chars.substring(idx, idx+1);
        }
        system.debug('Value----'+randStr); 
      */
  }