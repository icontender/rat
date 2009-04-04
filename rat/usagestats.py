#!/opt/race/bin/python
# Author: Corey Osman
# Date: 3-19-2009

import time
import os


class usagestats (object):
    '''
    This class is for collecting stats about everything that happens.  For right now we can
    just throw all the stats into a dict on a file.  Later we will want to move this into a DB
    '''
    daily = []
    weekly = []
    monthly = []
    yearly = []
   # statsfile = "rattstats.py"
    statsfile = "rattstats.py"
    def __init__(self):
        self._readstats() 
    def _readstats(self):
        '''
        Lets open the statsfile and read the stats into the respected dictionaries
        daily, weekly, monthly
        '''
        f = None
        ignore_exec_globals = {}
        filedata = {}
        if os.path.exists(self.statsfile):
            f = open(self.statsfile)
            
        else:
            print "Can't find file: %s creating file now" % (self.statsfile)
            return True
        try:
             exec f in ignore_exec_globals, filedata
        finally:
             f.close()
        
        if filedata.has_key('daily'):
            self.daily = filedata['daily']
        if filedata.has_key('weekly'):
            self.weekly = filedata['weekly']
        if filedata.has_key('monthly'):
            self.monthly = filedata['monthly']
        if filedata.has_key('yearly'):
            self.yearly = filedata['yearly']
          
        return True

    def _getdate(self, type):
        # types of dates (today, week, month, year)
        date = None
        if type.lower() == 'day' or type.lower() == 'daily':
            #03/19
            date = time.strftime("%m/%d", time.localtime())
        elif type.lower() == 'week':
            #11
            date = time.strftime("%U", time.localtime())
        elif type.lower() == 'month':
            #03/2009
            date = time.strftime("%m/%Y", time.localtime())
        elif type.lower() == 'year':
            #2009
            date = time.strftime("%Y", time.localtime())

        return date
        
    def getstats(self, type='daily', users='all'):
        '''
        Read the stats from memory, if type is specified specific 
        stats will be returned
        '''
        if type == 'daily':
            return self.daily
        elif type == 'weekly':
            return self.weekly
        elif type == 'monthly':
            return self.monthly
        elif type == 'yearly':
            return self.yearly
        

    def updatestats(self, statobj):
        self.purgestats()
        self._totals(statobj, self.daily, 'day')
        self._writestats()
        
    
    

    def _writestats(self):
        '''    
        This method takes no arguments and writes the lists currently in memory to file.  In the future it should 
        write to a DB
        '''
        try:
            try:
                f = open(self.statsfile, 'w')
                f.write('daily = %s\n\n' % (self.daily))
                f.write('weekly = %s\n\n' % (self.weekly))
                f.write('monthly = %s\n\n' % (self.monthly))
                f.write('yearly = %s\n\n' % (self.yearly))
            except:
                print "Could not open rattstats file"
        finally:
            f.close
        
        return
    def _totals(self, statobj, stats, type):
        # type is either daily, weekly, monthly, yearly
        # stats represents the stats object which where read in from the file (self.weekly ...)
        found = False
        date = self._getdate(type)
        
        for s in stats:
            # user already exists, update count, no need for date
            if s.has_key('Name') and s['Name'] == statobj.user:
                        
                s['Linux'] += statobj.linux
                s['Windows'] += statobj.windows
                s['Solaris'] += statobj.solaris
                found = True
                break
                        
        if not found:
            # user does not exist
            stats.append({'Name':statobj.user, 'Windows':statobj.windows, 'Solaris':statobj.solaris,
                          'Linux':statobj.linux, type:date})
        return 
    def purgestats(self):
        '''
        The method takes no arguments and purges all the old records in each list.  The records that are
        old will get put into the next list type (day->week, week->month, month->year).  The records will be 
        added and the dates will change accordingly per the type of list.
        The method does not return anything
        '''
        type = 'day'
        date = self._getdate('day')
        for s in self.daily[:]:
            
            if s.has_key(type) and s[type] != date:
                # remove the item from the list
                self.daily.remove(s)
                # rerun the totals method and add it to the new weekly list
                self._totals(stat(s), self.weekly, 'week')
        
        date = self._getdate('week')
        type = 'week'
        for s in self.weekly[:]:
            if s.has_key(type) and s[type] != date:
                # remove the item from the list
                self.weekly.remove(s)
                # rerun the totals method and add it to the new monthly list
                self._totals(stat(s), self.monthly, 'month')

        date = self._getdate('month')
        type = 'month'
        for s in self.monthly[:]:
            if s.has_key(type) and s[type] != date:
                # remove the item from the list
                self.monthly.remove(s)
                # rerun the totals method and add it to the new monthly list
                self._totals(stat(s), self.yearly, 'year')
                continue
            
                
        
class stat:
    user = ''
    windows = 0
    linux = 0
    solaris = 0
    ostype = ''
    def __init__(self, thedata={'Name':''}):
    
        # I am assuming too much should check to make sure those keys exist
        if thedata.has_key('Name') and thedata['Name']:
            self.user = thedata['Name'].lower()
        if thedata.has_key('Windows') and thedata['Windows']:
           self.windows = thedata['Windows']
        if thedata.has_key('Linux') and thedata['Linux']:
            self.linux = thedata['Linux']
        if thedata.has_key('Solaris') and thedata['Solaris']:
            self.solaris = thedata['Solaris']
        if thedata.has_key('ostype') and thedata['ostype']:
            self.ostype = thedata['ostype'].capitalize()
    def printme(self):
        print '%s %s %s %s' % (self.user, self.windows, self.linux, self.solaris)

class tests:
    def test(self):
        p = {'Name':'cosman', 'Solaris':0, 'Windows':0, 'Linux':1, 'ostype':None}
        s = stat(p)
        
        statsobj = usagestats()
        statsobj.updatestats(s)
        print statsobj.getstats('daily')
        

