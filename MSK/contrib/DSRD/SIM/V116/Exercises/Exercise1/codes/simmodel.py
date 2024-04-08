'''
Created on Feb 7, 2024
Defining Simulation Model that creates simulation environment
  and defines the flow of events from day 1 to end of simulation.
@author: user1
'''

import sys
sys.path.append('\\\\wpushh01\dinfopln\DSRD\SIM\V116\Exercises\Exercise1\codes')
import sim_config as config
from players.consumer import Consumer
from players.physician import Physician
#print(__spec__)

from random import random
from random import randint
import numpy as np
import math

class SimModel(object):
    '''
    Attributes:  
    N_Time_Slots, time_slot_range - range from 1 to N (used for looping through)
    Phys_Count, Phys_List
    spec_group_list[], org_tag_list(), zip3_list()
    Methods: 
    initialize() - initializes environment at time 0.
    step(date_slot) - specifies what happens on each day slot of the simulation
    report_slot_activities(date_slot) - reports aggregate metrics after end of each day slot. 
    simulate() - loops through each day of simulation.
    report_sim_summary() - reports aggregate metrics after end of simulation. 
    '''
    #Attributes
    # almost all attributes are defined in config file as constants
    def __init__(self):
        self.num_time_slots = config.NUM_TIME_SLOTS
        self.time_slot_range = range(config.NUM_TIME_SLOTS)
        self.num_phys = config.NUM_PHYS
        self.phys_list = []
        self.rng_s = config.RNG # random number generator
        self.brands = config.BRANDS

    #Methods
    def initialize(self):
        '''
        1. Create Phys Count amount of physicians and add to Phys_List. 
           Assign spec_grp, org_tag, zip3
        For each physician:
          2. Call phys.assign_patients()
          3. Call phys.initialize_appointments() 
        '''
        for iphy in range(self.num_phys):
            t_phys_id = 'P'+str(iphy).zfill(6)
            t_specialty = self.rng_s.choice(config.SPECIALTY,p=config.SPECIALTY_PROB)
            t_spec_grp = config.SPEC_GROUP_XREF[t_specialty]
            t_zip3 = self.rng_s.choice(config.ZIP3_LIST)
            t_target_seg = ''
            t_org_tag = ''
            t_physician = Physician(phys_id = t_phys_id, specialty = t_specialty, 
                                    spec_group = t_spec_grp, target_seg = t_target_seg, 
                                    org_tag = t_org_tag, zip3 = t_zip3)
            self.phys_list.append(t_physician)
        
        for phys in self.phys_list:
            phys.assign_patients()
            phys.initialize_appointments()
        pass
    pass

    def step(self,slot_idx):
        '''
        1. For each phys:
            a. For each patient on that slot_idx day
                i. pat.visit_doc()
                ii. phys.decide_rx()
                iii. pat.get_presc()
                iv. pat.fill_rx()
                v. pat.schedule_appointment()
            b. summarize daily rxs for each phys and log it 
        2. Summarize all phys activity for the slot day and log it (report_slot_activity())
        ''' 
        slot_rx_counts = {} # {brand : counts} - PRV, V116, P23, VAX
        slot_rx_filled_counts = {}  # register Rxs filled by patients {brand : counts} - PRV, V116, P23, VAX
        for brnd in config.BRANDS:
            slot_rx_counts[brnd] = 0
            slot_rx_filled_counts[brnd] = 0

        for phys in self.phys_list:
            for pat_id in phys.appointments[slot_idx]:
                # gets first occurence of Customer object with customer_id ==  pat_id.
                # if no such patient exists then returns None.
                pat = next((x for x in phys.patient_list if x.customer_id == pat_id),None)
                if pat == None:
                    continue
                pat.visit_doc(phys.phys_id,slot_idx) #merely logs the visit in corresponding Consumer object
                t_rx = phys.decide_prescription(pat)
                if t_rx != '':
                    slot_rx_counts[t_rx] += 1
                    get_status = pat.get_presc(t_rx,slot_idx)
                    if get_status:
                        fill_status = pat.fill_presc(t_rx,slot_idx)
                        if fill_status:
                            phys.rx_filled_counts[t_rx] += 1
                            slot_rx_filled_counts[t_rx] += 1
                    pass
                pass
                #pat.schedule_doc_appointment(phys.phys_id,new_slot_idx)
            pass
            #Summarize daily rxs for the physician and log it
            # This will be too much of memory or printing - so skip for now.
        pass
        # summarize all phys activity for the slot_idx day and log it.
        self.report_slot_activity(slot_idx,slot_rx_counts,slot_rx_filled_counts) 

    def report_slot_activity(self,slot_idx,rx_counts,rx_filled_counts):
        '''
        Just log that dsys Rxs. Create a formatted string.:
        ''' 
        str1 = "Day {0}: ".format(str(slot_idx))
        if rx_counts == None or rx_filled_counts == None:
            print(str1 +"EMPTY")
            return False
        for brnd in config.BRANDS:
            str1 += brnd + "-" + \
                 str(rx_filled_counts[brnd]) + '/' + str(rx_counts[brnd]) + '; '
        print(str1)
        return True
    
    def simulate(self):
        '''
        1. For each slot in date_slots call step(slot_index) 
        2. Report_aggr_stats()
        '''
        for t_slot_idx in self.time_slot_range:
            self.step(t_slot_idx)
        pass
        self.report_sim_summary()
    
    def report_sim_summary(self):
        sim_rx_counts = {} # {brand : counts} - PRV, V116, P23, VAX
        sim_rx_filled_counts = {}  # register Rxs filled by patients {brand : counts} - PRV, V116, P23, VAX
        for brnd in config.BRANDS:
            sim_rx_counts[brnd] = 0
            sim_rx_filled_counts[brnd] = 0
        for iphys in self.phys_list:
            for brnd2 in config.BRANDS:
                sim_rx_counts[brnd2] += iphys.rx_counts[brnd2]
                sim_rx_filled_counts[brnd2] += iphys.rx_filled_counts[brnd2]
            pass
        pass
        # print or log the simulation summary
        str1 = "**** SIMULATION SUMMARY *****\n"
        str1 += "SLOTS - " + str(self.num_time_slots) + "\n"
        for brnd2 in config.BRANDS:
            str1 += brnd2 + "prescribed / filled - " \
                    + str(sim_rx_counts[brnd2]) + " / " \
                    + str(sim_rx_filled_counts[brnd2]) + "\n"
            pass
        print(str1)
###################

# Main code to run the simulation

def main_run():
    sim_model = SimModel()
    sim_model.initialize()
    sim_model.simulate()
## END OF CODES. 

main_run()


        






