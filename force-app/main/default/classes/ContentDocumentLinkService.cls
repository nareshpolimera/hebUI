/*
* @Class      ContentDocumentLinkService
* @brief      Class with especific-related methods to the ContentDocumentLink object.
*
* @revision   2024-05-14 Juan Carlos Contreras
*                Porting from legacy SF org.
*/
public class ContentDocumentLinkService {
  public void validateFilesOnUpload(List<ContentDocumentLink> records) {
    //service.assignNewCaseToQueue(records);
    Boolean RestrictPermissionFpoc = FeatureManagement.checkPermission(
      'FPOCs_L1'
    );
    Boolean Data_Analyst_Reporting = FeatureManagement.checkPermission(
      'Data_Analyst_Reporting'
    );
    if (!(RestrictPermissionFpoc || Data_Analyst_Reporting)) {
      return;
    }
    Id userId = userinfo.getuserid();
    list<string> caseIDList = new List<string>();
    map<id, ContentDocumentLink> errorrecords = new Map<id, ContentDocumentLink>();

    for (ContentDocumentLink cs : records) {
      string caseId = cs.LinkedEntityId;
      if (caseId.startsWithIgnoreCase('500')) {
        caseIDList.add(caseId);
        errorrecords.put(caseId, cs);
      }
      // cs.addError('You cannot upload the file');
    }
    list<case> casemap = [SELECT Id, ownerId FROM case WHERE id IN :caseIDList];
    for (case c : casemap) {
      if (
        Data_Analyst_Reporting &&
        !CaseService.insertingIDs.contains(c.id) &&
        !CaseService.updatingIDs.contains(c.id)
      ) {
        c.adderror(
          'You dont have permission to Upload a attachment for the case'
        );
      } else if (RestrictPermissionFpoc) {
        if (
          c.OwnerId != UserInfo.getUserId() &&
          !CaseService.insertingIDs.contains(c.id) &&
          !CaseService.updatingIDs.contains(c.id)
        ) {
          c.adderror(
            'You dont have permission to Upload a attachment for the case that you dont own'
          );
        }
      }
    }
  }
}