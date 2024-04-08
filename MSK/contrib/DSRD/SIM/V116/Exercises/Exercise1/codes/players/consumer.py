'''
Created on Feb 3, 2024
Defining Consumer Class as part of simple simulation exercise.
@author: user1
'''

#import sys
#sys.path.append('../codes') #UNIX
#sys.path.append('\\\\wpushh01\dinfopln\DSRD\SIM\V116\Exercises\Exercise1\codes')
#print(sys.path)
#print(__spec__)
import sim_config as config
from random import random 
#from .physician import Physician
class Consumer(object):
    '''
    The Consumer class creates attributes and methods relevant for a health care consumer.
    Attributes: 
    Cust_id, age, gender, lat, long, zip, zip3, primary_ins,
    Phys List, Comorbidity List, fill_probability
    Prevnar [Status, Date Taken], P23 [Status, Date Taken], Vax[Status, Date Taken], V116[Status, Date Taken], 
    Transactions [type, source, date, treatment_desc] {ex: Med_Claims, Pharm_Rx, Lab_Claims as Transaction Type}, 
    HC_appointments{appointment_date:doc_id}  
    Methods:
    visit_doc() - logs when a patients visits a doctor
    get_presc() - logs when a patient gets a prescription
    fill_presc()  fills using fill_probabilty and then logs if successful
    schedule_appointment() - used to search physicians availability and take that slot. Log it.
    '''
    # Attributes
    def __init__(self,customer_id, age=0, gender='',
                  zip3='999', ins_primary='', claim_type='',
                  fill_probability=1.0):
        self.customer_id = customer_id
        self.age = age 
        self.age_group_for_visit = ''
        self.visits_per_year_mean = 0
        self.visits_per_year_sd = 0
        self.gender = gender 
        self.zip3 = zip3
        self.ins_primary = ins_primary
        self.claim_type = claim_type
        self.phys_list = []
        self.comorbity_list = []
        self.fill_probability = fill_probability
        # store prescription filling status.
        self.vac_eligibility = True
        self.pvr = [False,[]] # Prevnar - 0 - get status, 1 - list of date_gotten, 2 - 
        self.p23 = [False,[]] # P23 - has status, list of date_taken
        self.vax = [False,[]] # Vaxneuance - has status, list of date_taken
        self.v116 = [False,[]] # V116 - has status, list of date_taken
        self.rx_transactions = [] # this is 2D list. Consider revisiting.
                               #each element is a list of [date,type,drug]
        self.hc_appointments = {} # dictionary of {appointment_date:doc_id}
        self.doc_visits = {} # dict of  {visit_date:doc_id[]}
    
    # Methods
    def set_visit_stats(self):
        for lst in config.PAT_VISITS_REF1:
            if self.age >= lst[1] and self.age <= lst[2]:
                self.age_group_for_visit = lst[0]
                self.visits_per_year_mean = lst[3]
                self.visits_per_year_sd = lst[4]
                break
        pass

    def register_appointment(self,doc_id,appointment_date):
        '''
        registers the doc appointment (i.e., just logging)
        '''
        if appointment_date in self.hc_appointments:
            self.hc_appointments[appointment_date].append(doc_id)
        else:
            self.hc_appointments[appointment_date] = [doc_id]

    def visit_doc(self,doctor_id,visit_date):
        ''' registers when a patient visits the doctor'''
        if visit_date in self.doc_visits:
            self.doc_visits[visit_date].append(doctor_id)
        else:
            self.doc_visits[visit_date] = [doctor_id]
    
    def get_presc(self,drug,presc_date):
        ''' registers the prescribed drug '''
        if drug not in config.BRANDS:
            return False
        self.rx_transactions.append([presc_date,'GET',drug])
        return True

    def fill_presc(self,drug,presc_date):
        ''' fills using fill_probabilty and then logs if successful
            returns True if successfully filled. Sets future vaccine
            eligibility to False if V116 or PVR is filled.
        '''
        if drug not in config.BRANDS:
            return False
        if random() >= self.fill_probability:
            return False  # do not fill and return
        # now start filling.
        if drug == 'PVR':
            self.pvr[0] = True
            self.pvr[1].append(presc_date)
        elif drug == 'V116':
            self.v116[0] = True
            self.v116[1].append(presc_date)
        elif drug == 'P23':
            self.p23[0] = True
            self.p23[1].append(presc_date)
        elif drug == 'VAX':
            self.vax[0] = True
            self.vax[1].append(presc_date)
        self.rx_transactions.append([presc_date,'FILL',drug])
        # if V116 or Prevnar is prescribed then set future vac_eligibility to false
        if drug in ['V116', 'PVR']:
           self.vac_eligibility = False 
        # return true to indicate the prescription was successfully filled.
        return True

    def schedule_doc_appointment(self, doc, appointment_date):
        '''
        used to search physicians availability and take that slot. Log it.
        '''
        #yet to write code. Here interaction with Physician object happens.
        return False

    
