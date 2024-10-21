public class ContentDocumentLinkTriggerDomain {
  private ContentDocumentLinkService service = new ContentDocumentLinkService();
  public void beforeInsert(List<ContentDocumentLink> records) {
    service.validateFilesOnUpload(records);
  }
}