import sys, os
import csv
import ConfigParser
from hdbcli import dbapi
from getpass import getpass

def ConnectDB(DBInfo):
    if len(DBInfo) != 4:
        print 'Invalid number of parameters'
        exit()
    db = DBAccess()
    db.Connect(DBInfo[0], DBInfo[1], DBInfo[2],DBInfo[3])
    if db.GetConnection() == False:
        #print 'Can not connect to '+ DBInfo[0]+':'+DBInfo[1]
        return None
    else: 
        #print 'Connected to '+ DBInfo[0]+':'+DBInfo[1]
        return db
def Process(inifile):
    cf = ConfigParser.ConfigParser()
    # Please use HDBUSERSTORE for production usage. Avoid storing the password as plain text.
    if inifile == '':
	    inifile = '/your/path/db.ini'
    cf.read(inifile)
    sec_s = cf.sections()
    for sec in sec_s:
        #print sec
        sids = cf.get(sec, 'SID').split(',')
        nums = cf.get(sec, 'NUM').split(',')
        users = cf.get(sec, 'USER').split(',')
        passes = cf.get(sec, 'PASS').split(',')
        l = len(sids)
        memUsedTotal = 0
        memGALTotal = 0
        osMem = 0 
        osFree = 0
        output = []
        for i in range(0,len(sids)):
            DBInfo  =  ( sec.strip(), nums[i].strip(), users[i].strip(), passes[i].strip()) 
	    
            #print DBInfo
            db = ConnectDB(DBInfo)
            if db == None:
                output.append ("Fail to connect %s, %s, SID: %s"% (sids[i], sec.strip(), nums[i].strip()))
                continue
                #exit()
            #sql = 'select round(sum(TOTAL_MEMORY_USED_SIZE)/1024/1024/1024) as USED_GB from M_SERVICE_MEMORY'
            sql = 'select round(INSTANCE_TOTAL_MEMORY_USED_SIZE/1024/1024/1024) as USED_GB from M_HOST_RESOURCE_UTILIZATION'
            res = db.Execute(sql)
            if res != None:
                insMem = sids[i].strip()+' uses '+str(res[0][0])+' GB memory'
                #output.append(insMem)
                memUsedTotal += res[0][0]
                if osMem == 0:
                    sql_os = "select round(value/1024/1024/1024) as OS_MEMORY_GB from M_MEMORY where name in('SYSTEM_MEMORY_SIZE', 'SYSTEM_MEMORY_FREE_SIZE')"
                    res_os = db.Execute(sql_os)
                    if res_os != None:
                        osMem = res_os[0][0]
                        osFree = res_os[1][0]
                    else: print 'Check OS memory failed'

            else:
                print 'Execution fail'
	    # Fetch Global ALlocation Limit
	    sql = 'select round(ALLOCATION_LIMIT/1024/1024/1024) as GAL_GB from M_HOST_RESOURCE_UTILIZATION'
            res = db.Execute(sql)
            if res != None:
                insMem = insMem + ' GAL: '+str(res[0][0])+' GB memory'
                output.append(insMem)
                memGALTotal += res[0][0]
	    else:
                print 'Execution fail'
            db.Disconnect()

        print 'HOST:', sec.strip()
        print ("OS Total Memory/Free Memory: %d GB/%d GB"% (osMem, osFree))
        print 'TOtal used memeory:', memUsedTotal, ' GB; Total GAL: ', memGALTotal ,' GB'
        for ins in output:
            print '---', ins
        print '------------------------------------------------'

class DBAccess:
    def __init__ (self):
        self.isConnected = False
        self.hostname = ''
        self.port = 0
        self.username = ''
        self.password = ''
        self.conn = None
        self.curs = 0
    def Connect ( self, hostname, port, username, password ):
        self.hostname = hostname
	      #Use SINGLE DB by default
        self.port = 30015 + int(port)*100
        self.username = username
        self.password = password
        if self.isConnected:
            self.conn.close()
            self.isConnected = False

        try:
            self.conn = dbapi.connect(self.hostname, self.port, self.username, self.password)
        except:
	      #Try MDC mode 
	        self.port = 30013 + int(port)*100
	        #print self.port
	        try: 
            	self.conn = dbapi.connect(self.hostname, self.port, self.username, self.password)
	        except:
	    	    self.isConnected = False
            #print 'Connection failure'

        if self.conn:
            #print 'Connected to HANA'
            self.isConnected = True 
            self.curs = self.conn.cursor()
    def Disconnect(self):
        if self.isConnected == True:
            self.conn.close()
            self.isConnected = False
    def Execute(self, sql):
        if self.isConnected:
            self.curs.execute(sql)
            #print 'execute ' + sql
            return self.curs.fetchall()
        else:
            print 'Database not connected'
            return None
    def GetConnection (self):
        return self.isConnected

if __name__ == '__main__':
  if len(sys.argv) != 2:
	  print 'INI file not specified, reading /your/path/db.ini'
	  Process('')
  else :
	  Process(sys.argv[1])
