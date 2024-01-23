module SolrProxy
{
    authentication required;

    funcdef insert_records(string collection_name, string records) returns (int success, string status_message);
    funcdef update_records(string collection_name, string records) returns (int success, string status_message);
};
