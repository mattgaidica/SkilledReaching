function sessionTableOut = extractSpecificSessions(sessionTable,sessions_to_extract)
%
% INPUTS
%   sessionTable - table of information about each session in the skilled reaching
%       experiment
%   sessions_to_extract - structure with fields that match with sessionTable column
%       headers
%
% OUTPUTS
%   sessionTableOut - table of rows from sessionTable that match with experimentInfo


% divide sessionTable into blocks of similar sessions
sessionBlockLabels = identifySessionTransitions(sessionTable);
sessions_remaining = calcSessionsRemainingFromBlockLabels(sessionBlockLabels);

sessionFields = fieldnames(sessions_to_extract);
% sessionTableOut = sessionTable;

validRows = false(size(sessionTable,1),1);
for iSession = 1 : length(sessions_to_extract)
    
    session_validRows = true(size(sessionTable,1),1);
    
    for iField = 1 : length(sessionFields)
        temp_validRows = false(size(sessionTable,1),1);
        % if field value is irrelevant, don't pull out any rows
        if strcmpi(sessions_to_extract(iSession).(sessionFields{iField}),'any')
            continue;
        end
        switch sessionFields{iField}
            case 'sessions_remaining'
                temp_validRows(sessions_remaining == sessions_to_extract(iSession).sessions_remaining) = true;
            otherwise
                temp_validRows(sessionTable.(sessionFields{iField}) == sessions_to_extract(iSession).(sessionFields{iField})) = true;
        end
        session_validRows = session_validRows & temp_validRows;

    end
    
    validRows = validRows | session_validRows;
    
end

sessionTableOut = sessionTable(validRows,:);