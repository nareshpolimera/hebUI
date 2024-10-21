public class SharingService {

    public Type sharingType;
    public String sObjectTypeName;
    public String accessLevelFieldName;
    public String parentIdFieldName;


    public SharingService( Schema.sObjectType sObjectType )
    {
        Schema.DescribeSObjectResult sObjectResult = sObjectType.getDescribe();
        sObjectTypeName = sObjectResult.getName();
        Boolean isCustom = sObjectTypeName.endsWith( '__c' );

        String sObjectName = sObjectTypeName.removeEnd( '__c' );
        if ( sObjectName.contains( '__' ) ) sObjectName = sObjectName.substringAfter( '__' );

        String sharingTypeName = (isCustom ? sObjectTypeName.removeEnd( 'c' ) : sObjectTypeName) + 'Share';

        this.sharingType = Type.forName( sharingTypeName );
        this.parentIdFieldName = (isCustom ? 'Parent' : sObjectTypeName) + 'Id';
        this.accessLevelFieldName = (isCustom ? '' : sObjectTypeName) + 'AccessLevel';
    }

    public sObject createShareRecord( String accessLevel, Id recordIdToShare ,Id userOrGroup )
    {
        sObject sharingRecord = (sObject) sharingType.newInstance();
        sharingRecord.put( parentIdFieldName, recordIdToShare);
        sharingRecord.put( accessLevelFieldName, accessLevel );
        sharingRecord.put( 'RowCause', 'Manual' );
        sharingRecord.put('UserOrGroupId', userOrGroup );
        return sharingRecord;
    }

}