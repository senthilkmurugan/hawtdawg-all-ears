'''
Created on Feb 5, 2024
setting all configuration values here.
@author: user1
'''
# NUMBER of TIME SLOTS 
#250 working days per year. Two years - 500 days. 
# Each day is a simulation time slot
NUM_TIME_SLOTS = 500
#Number of Physicians in the simulation
NUM_PHYS = 100
# Random Seed (if 0 then don't use seed)
SEED = 1000
# setup random number generator with given SEED
import numpy as np
RNG = np.random.default_rng(SEED)


#Patient Rx fill probability once they get prescription
PAT_FILL_PROB = 0.9

#BRANDS
BRANDS = ('V116','PRV','P23','VAX')
#phys rx writing probability for corresponding brands in BRANDS
PHYS_NO_RX_PROB = 0.7 #probability that no BRANDS are written in a patient visit.
PHYS_RX_PROB = (0.3,0.5,0.05,0.15) # when phys decides to prescribe and patient age >= 50,
                                     # use this prescription probability.

GENDER = ('M','F')
CLAIM_TYPE = ('GOVT','COMM')

#Physicial Specialties and the specialty groups
SPECIALTY = ('PCP','SP','OTH')
SPECIALTY_PROB = (0.7,0.2,0.1) # Probablities of occurence of the above physician specialties
SPEC_GROUP = ('PCP','SP','OTH')
#Specialty to speciaty group mapping - dictionary. {specialty : spec_group}
SPEC_GROUP_XREF = {'PCP':'PCP', 
                   'SP':'SP', 'OTH':'OTH'}

# Distribution of patients per physician - tuple of distribution, parameters
PAT_PER_PHYS = ('NORMAL',(2500,300)) #Normal with mean 1200 and sd 300.

#Set a 2d tuple for yearly count of patient visists reference. 
#Columns are patient age group, min_age, max_age, visits per year mean, visits per year sd
#ref National Health statistics report Apr 20 2023
PAT_VISITS_REF1 = (('0_1',0,1,8.24, 1.4),('2_17',2,17,1.3,0.18),('18_44',18,44,1.88,0.15),
                   ('45_49',45,49,3.75, 0.28),
                   ('50_64',50,64,3.75, 0.28),('65_100',65,100,7.1,0.45))

#Set a 2d tuple for number of patients seen per day by phys spec group 
#Columns are phys spec group, pats per day mean, pats per day stddev
PHYS_PATS_PER_DAY_REF1 = {'PCP':[20,5],'SP':[15,5],'OTH':[20,5]}

#LIST OF ZIP3
ZIP3_LIST = [str(x) for x in range(100,200)]

#% of patients by age group (age_group, min age, max age, % of HCP patients)
# reference study.com search for 'what is the age distribution of patients who 
#     make office visits to a doctor or nurse'. This is not authoritative source.
PATS_BY_AGE = (('0_15',0,15,0.15),
               ('15_24',15,24,0.10),
               ('25_44',25,44,0.20),
               ('45_64',18,19,0.15),
               ('65_100',65,85,0.40))



