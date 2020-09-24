[[_TOC_]]

# Collection of azure functions

- **iCollectFunction** it is a TimeTrigger function app. it collects logs from storage account (`$logs` folder ) every 2 mins and sends it to Custom LA workspace instance. The json formate used is as per latest `storage logs schema 2.0`.
- **iCountFunction** it is a TimeTrigger function app, it checks for number of files in a path. and sends the count with folder name. as a custom log to a Custom LA workspace. 
- **iALertFunction** it is a HttpTrigger Function app, it waits for a Sev4 alert. and as a part of sample action. It deletes one file from the specifed folder to reduce alert back to normal.