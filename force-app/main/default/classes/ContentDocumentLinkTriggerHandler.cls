public class ContentDocumentLinkTriggerHandler {
  public void beforeInsert(List<ContentDocumentLink> records) {
    new ContentDocumentLinkTriggerDomain().beforeInsert(records);
  }
}