from pyzabbix  import ZabbixAPI
import argparse
parser=argparse.ArgumentParser(description="Import throgh here")
parser.add_argument('loc',help='Please provide the valid location during run.No location validation has been implemented')
args=parser.parse_args()
zapi = ZabbixAPI(url='http://192.168.56.101/zabbix/', user='Admin', password='zabbix')
print("Yes Connected")
file=open(args.loc,"r")
cont=file.read()
results=zapi.do_request('configuration.import',{"format":"xml","rules":{
"templates":{"createMissing":True,"updateExisting":True},
"applications":{"createMissing": True},
"items":{"createMissing": True,"updateExisting": True},
"triggers":{"createMissing": True,"updateExisting": True},
"graphs":{"createMissing": True,"updateExisting": True},
},
"source":cont})
results["result"]=='True' 
print("successfully imported and here is the information of api results",results)
print("its for second branch..i am learning git again clearly.")
printf("its really cool")


