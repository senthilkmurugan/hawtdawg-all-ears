'''
Created on Feb 3, 2024
Defining Physician Class as part of simple simulation exercise.
@author: user1
'''
#import sys
#import os
#sys.path.append('../codes')
import sim_config as config
from random import random
from random import randint
import numpy as np
import math

#sys.path.append('./players') # need this in visual code to import consumer
from .consumer import Consumer
#from . import consumer

class Physician(object):
    '''
    Attributes: 
    specialty, spec_group, target_seg, org_tag, optionally -- age, gender
    patient_list, appointments{date_slot : [patient ids]}, max_appointments{date_slot : num_pats}, available_appointment_slots[list of date slots]
    hcp_insurances[insurance ids], Rx_Counts{brand : counts} - Prevnar, P23, Vax, V116
    Methods:
    assign_patients(patient list) - assigns a set of patients to physician
    initialize_appointments() - fill all appointment slots to be used before simulation starts running.
    set_appointment(patient_id, date_slot) - checks if appointment is available on that day and if available assigns the patient to physician’s appointment list and returns true. If appointment is not available returns false. Updates available_appointment_slots[] if all appointments are full for the day.
    decide_prescription(patient_id) - decides if the patient needs prescription and if so which one and then prescribes for the patient (i.e., call get_prescription(brand) of the patient). Then call fill _presc() of the patient. Log the decide counts.
    '''
    #Attributes
    def __init__(self, phys_id, specialty='', spec_group='', target_seg='',
                 org_tag='', zip3=''):
        self.phys_id = phys_id
        self.specialty = specialty
        self.spec_group = spec_group
        self.target_seg = target_seg
        self.org_tag = org_tag
        self.zip3 = zip3
        self.age=0
        self.gender=''
        self.n_pats = 0
        self.patient_list = []  # list of consumers
        self.appointments = {} # {date_slot : [patient_ids]}
        self.max_appointments = {} # {date_slot: num_pats}
        self.available_appointment_slots = [] # list of date slots that has appointments available.
        self.hcp_insurances = [] # list of insurances supported
        self.rx_counts = {} # {brand : counts} - PRV, V116, P23, VAX
        self.rx_filled_counts = {}  # register Rxs filled by patients {brand : counts} - PRV, V116, P23, VAX
        for brnd in config.BRANDS:
            self.rx_counts[brnd] = 0
            self.rx_filled_counts[brnd] = 0
    
    #Methods
    def assign_patients(self):
        ''' generates Consumer objects as patients
            a. Assign patients for each physician (based on patients per physician distribution)
            b. Each of Physician's patient gets same zip3 as the physician
            c. Assign age, gender, claim_type (govt, commercial), ins_tag for each patient
        '''
        rng_s = config.RNG
        if config.PAT_PER_PHYS[0] == "NORMAL":
            self.npats =int(rng_s.normal(config.PAT_PER_PHYS[1][0], 
                                   config.PAT_PER_PHYS[1][1])) 
        
        for pat in range(self.npats):
            t_cust_id = 'C_'+self.phys_id+'_'+str(pat).zfill(5)
            t_age = 0
            while t_age < 17:
                prob_list = [x[3] for x in config.PATS_BY_AGE]
                i1 = rng_s.choice(len(config.PATS_BY_AGE),p=prob_list)
                t_age = rng_s.choice(range(config.PATS_BY_AGE[i1][1],config.PATS_BY_AGE[i1][2]))
            t_gender = rng_s.choice(config.GENDER)
            t_claim_type = rng_s.choice(config.CLAIM_TYPE)
            t_ins_primary = ''
            t_prob = config.PAT_FILL_PROB
            t_zip3 = self.zip3
            t_consumer = Consumer(t_cust_id,t_age,t_gender,t_zip3,
                                  t_ins_primary,t_claim_type,t_prob)
            t_consumer.set_visit_stats()
            self.patient_list.append(t_consumer)
        return
        
    
    def set_appointment(self, patient, date_slot):
        '''
        checks if appointment is available on that day and 
        if available assigns the patient to physicians appointment list 
        and returns true.
        '''
        if date_slot not in self.available_appointment_slots:
            return False  # return False if appointment is not available.
        # proceed when appointments are available for that date.
        #day_appointments = []
        self.appointments[date_slot].append(patient.customer_id)
        patient.register_appointment(self.phys_id,date_slot)
        if self.max_appointments[date_slot] <= len(self.appointments[date_slot]):
            self.available_appointment_slots.remove(date_slot)

        # return true as appointment is successfully set.     
        return True


    def initialize_appointments(self):
        '''
        fill all appointment slots to be used before simulation starts running.
        a. Initializes phys.appointments attribute with date_slot key and empty lists as values
        b. Initializes max_appointments{date_slot : num_pats}, available_appointment_slots[list of date slots]
        c. For each patient of the physician:
            i. If available_appointment_slots[] is empty then break out of the loop.
            ii. Get number of      
        a. Initializes phys.appointments attribute with date_slot key and empty lists as values
        b. Initializes max_appointments{date_slot : num_pats}, available_appointment_slots[list of date slots]
        c. For each patient of the physician:
            i. If available_appointment_slots[] is empty then break out of the loop.
            ii. Get number of total visits per year and project to total slot years (i.e., 2 years)
            iii. Draw random date slot from available_appointment_slots[] and call set_appointment() for the 
                  patient and given date slot. This set_appointment() internally 
                  does the following: Updates physician appointment schedule, 
                  updates available_appointment_slots[]
            iv. Repeat until number of appointemnts needed in step ii. If no more appointments are available, then break out of patient loop [(c) above]total visits per year and project to total slot years (i.e., 2 years)
            iii. Draw random date slot from available_appointment_slots[] and call set_appointment() for the patient and given date slot. 
            This set_appointment() internally does the following:
                    Updates physician appointment schedule, updates available_appointment_slots[]
            iv. Repeat until number of appointemnts needed in step ii. If no more appointments are available, then break out of patient loop [(c) above]
        '''
        rng_s = config.RNG
        apt_mean = config.PHYS_PATS_PER_DAY_REF1[self.spec_group][0]
        apt_sd = config.PHYS_PATS_PER_DAY_REF1[self.spec_group][1]
        for day in range(config.NUM_TIME_SLOTS):
            i_day = int(day)
            #n_max = rng_s.integers(1,int(rng_s.normal(apt_mean,apt_sd)))
            n_max = math.ceil(rng_s.normal(apt_mean,apt_sd))
            self.appointments[i_day] = []
            self.max_appointments[i_day] = n_max
            self.available_appointment_slots.append(i_day)
        
        for pat in self.patient_list:
            if len(self.available_appointment_slots) == 0:
                break
            pat_tot_visits = -1
            while pat_tot_visits < 0:
                pat_tot_visits = math.ceil(rng_s.normal(pat.visits_per_year_mean, 
                                                        pat.visits_per_year_sd)
                                                        *(config.NUM_TIME_SLOTS / 250))
            pass
            n_apt = 0
            while True:
                t_slot = rng_s.choice(self.available_appointment_slots)
                appt_ok = self.set_appointment(pat,t_slot)
                if appt_ok == True:
                    n_apt = n_apt + 1
                if n_apt == pat_tot_visits or len(self.available_appointment_slots) == 0:
                    break
            pass
        pass



    def decide_prescription(self, patient):
        '''
        decides if the patient needs prescription and if so which one 
        and then prescribes for the patient 
        returns the string with BRAND or empty string in no prescription is written.
        Log the decide counts.
        '''
        rng_s = config.RNG
        if (patient.vac_eligibility == False) or \
           (config.PHYS_NO_RX_PROB >= rng_s.random()):
            return ''
        rx_prescribed = ''
        if patient.age < 50: #PRV eligible.
            rx_prescribed = 'PRV'
        else: #eligible for all four brands.
            rx_prescribed = rng_s.choice(config.BRANDS,p=config.PHYS_RX_PROB)
        self.rx_counts[rx_prescribed] += 1 #incrementing prescription decision counts
        return rx_prescribed

