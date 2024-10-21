/*
Custom Apex Mode Configuration For Sortable Data Grid
Developer : Khouloud Alaa 
Contact : kalaa@deloitte.fr
*/

global class sdgDataProviderApex implements sortablegrid.sdgIDataProvider {

    global boolean isUserSelectable;
    global string sdg_mdt;
    global string objectQuery;
    global List<sortablegrid.SDGField> fields = new List<sortablegrid.SDGField>();
    global List<sortablegrid.SDGAction> actions = new List<sortablegrid.SDGAction>();
    public  class sdgInvalidEngineRequestException extends sdgException {}
   
    global static Boolean isUserSelectable()
    {
        return true;
    }

    global static sortablegrid.SDGResult getData(sortablegrid.SDG coreSDG,  sortablegrid.SDGRequest request)
    {
        sortablegrid.SDGResult result = new sortablegrid.SDGResult();

        try{
            List<String> UserWhereClauses = new List<String>();    
            Map<String, sortablegrid.SDGField> mFields = GetSelectFieldsMap(coreSDG);
            integer internalpageid = integer.valueOf(request.PageID);
            decimal internalPageSize = integer.valueOf(request.PageSize);
            internalpageid = internalpageid-1;
            
            Map<String, SortableDataGridColumns__mdt> orgFieldProperties = SortableDataGridColumns__mdt.getAll();
            String queryfields='ID';
            if(orgFieldProperties!=null){
                for(String keySetString : orgFieldProperties.keySet()){
                    queryfields+=',';
                    queryfields+=orgFieldProperties.get(keySetString).ColumnApiName__c;
                }
            }
            
            if(request.filters !=null)
                UserWhereClauses = AddFilters(request, mfields);
            
            String sCoreWhereClause = '';
            Id OpportunityId = [SELECT Id,OpportunityId FROM ResidentialLoanApplication WHERE Id =:request.ParentRecordID  Limit 1].OpportunityId;
            
            String query = 'select '+queryfields;
            query += ' from Quote ';
            query += ' where Opportunity__c ' + ' = \'' + OpportunityId + '\'';
            query += ' AND Active_Quote__c != true ';    
        
            if (UserWhereClauses.size()>0)
                    sCoreWhereClause = ' AND ' + String.join( UserWhereClauses, ' AND ');
            
            query += sCoreWhereClause;
            query += ' order by Name DESC';

            integer offset = integer.valueOf( internalPageSize * internalpageid);        
            String sPagination = ' limit ' + internalPageSize + ' offset  ' + offset;
            query += sPagination;
            
            result.data = database.Query(query);
            result.FullQueryCount = Integer.valueof(database.Query('select count(id) result from quote where Opportunity__c ' + ' = \'' + OpportunityId + '\'  AND Active_Quote__c != true')[0].get('result'));
            result.pagecount = (integer) math.ceil(result.FullQueryCount/internalPageSize);
            result.isError = false;
            result.ErrorMessage = '';

        }catch (Exception ex){
            throw new sdgInvalidEngineRequestException(ex);
        }

        return result;
    }

    global static sortablegrid.SDG LoadSDG(String SDGTag, String ParentRecordId)
    {
        sortablegrid.SDG CoreSDG = new sortablegrid.SDG( 'sdgDataProviderApexExample' );
        CoreSDG.SDGActions = GetActions();
        CoreSDG.SDGFields = GetFields();

        return CoreSDG;
    }

    global static List<sortablegrid.SDGAction> GetActions()
    {
        List<sortablegrid.SDGAction> actions = new List<sortablegrid.SDGAction>();
        return actions;
    }

    private static List<sortablegrid.SDGField> GetFields()
    {
        List<sortablegrid.SDGField> fields = new List<sortablegrid.SDGField>();
        List<SortableDataGridColumns__mdt> orgFieldProperties = [select ColumnID__c,ColumnName__c,ColumnApiName__c,Column_Field_Type__c,ColumnStyle__c,CanSortColumn__c,
                                                                 CanFilterColumn__c,isHTMLFormatted__c,ColumnOrder__c
                                                                from SortableDataGridColumns__mdt
                                                                order by ColumnOrder__c];
        if(orgFieldProperties!=null){
            for(SortableDataGridColumns__mdt mdt : orgFieldProperties){
                fields.add(new sortablegrid.SDGField(mdt.ColumnID__c,mdt.ColumnName__c,mdt.ColumnApiName__c,mdt.Column_Field_Type__c,
                mdt.ColumnStyle__c,mdt.CanSortColumn__c,mdt.CanFilterColumn__c,mdt.isHTMLFormatted__c,
                null,mdt.ColumnOrder__c.intValue()));
            }
        }
        
        return fields;
    }
    
    private static List<String> AddFilters(sortablegrid.SDGRequest request, Map<String, sortablegrid.SDGField> mfields)
    {
        List<String> UserWhereClauses = new List<String>();

        for (sortablegrid.SDGFilter filter : request.filters)
        {
            if (string.isblank(filter.filteroperator))
                filter.filteroperator = '=';

            sortablegrid.SDGField databasefield = mfields.get(filter.SDGFieldID);
            if (databasefield.canFilter)
            {
                String clause = sortablegrid.sdgQueryBuilder.BuildFilterClause( databasefield.ColumnName, databasefield.FieldType, filter.filterOperator, filter.filterValue);
                if (!String.isBlank(clause))
                     UserWhereClauses.add(clause);
            }
        }

        return UserWhereClauses;
    }
    
    private static map<String, sortablegrid.SDGField> GetSelectFieldsMap(sortablegrid.sdg sdgObject)
    {
        Map<String, sortablegrid.SDGField> results = new Map<String, sortablegrid.SDGField>();
        //Get all the fields for the select clause
        for (sortablegrid.SDGField field : sdgObject.SDGFields)
        {
            results.put(field.id,field);
        }
        return results;
    }
    
    public virtual class sdgException extends Exception {}
}