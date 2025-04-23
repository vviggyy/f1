#!/bin/bash

#change training strategy from base "supervised" to "reinforcement". just VET for now
rename_strategy_gap(){
    
    input=$1
    ext=$2
    #change strategy for person and create new file for reinforcement learning...
    sed -i 's/"supervised"/"realstrategy"/' racesim/input/parameters/pars_$input.ini
    sed 's/"RIC": "realstrategy"/"RIC": "reinforcement"/' racesim/input/parameters/pars_$input.ini > racesim/input/parameters/pars_${input}_${ext}_multi.ini
    sed -i 's/"VET": "realstrategy"/"VET": "reinforcement"/' racesim/input/parameters/pars_${input}_${ext}_multi.ini
    
}

rename_strategy_place(){
    
    input=$1
    ext=$2
    #change strategy for person and create new file for reinforcement learning...
    sed 's/"VET": "reinforcement"/"VET": "reinforcement"/' racesim/input/parameters/pars_${input}_gapOF_multi.ini > racesim/input/parameters/pars_${input}_${ext}_multi.ini
    #reverse changes
    sed -i 's/"realstrategy"/"supervised"/' racesim/input/parameters/pars_$input.ini
    
}

#edit vse training input .ini
SUB=${1#pars_} #will retrieve city_date for input into dqn file
SUB=${SUB%.ini}
echo "Extracted substring: $SUB"

obj_path="machine_learning_rl_training/src/rl_environment_multi_agent.py"
plots_path="racesim/src/mcs_analysis.py"

echo "----- ADJUSTING PARS FILE -----"

#-- GAP OBJ FUNCTION --
rename_strategy_gap "$SUB" "gapOF" #rename the .ini file --> will create a new file with input pars.ini

echo "----- RUNNING GAP OBJ FUNCTION -----"

#note 4 spaces for each indent here
sed -i '635c\        rewards = 0.1 * (self.__calculate_rewards_laptime(t_pitdrive_inlap))' "$obj_path" #replace entire line with this, 2 indents
sed -i '645c\            #rewards += self.__calculate_rewards_final_position()' "$obj_path" #eliminate final position bonus, 3 indents

OUTPUT="out_${SUB}_gapOF_multi.txt"

echo "${SUB}_gapOF"

sed -i "s/race = \".*\"/race = \"${SUB}_gapOF_multi\"/" main_train_rl_agent_dqn.py #stream edit, in place, race = somthing. 
#rl_agent_dqn takes Budapest_2014 instead of just .ini file name. thats why subset is needed
python main_train_rl_agent_dqn.py 

#edit main_racesim input line
sed -i "s/race_pars_file_ = '.*'/race_pars_file_ = 'pars_${SUB}_gapOF_multi.ini'/" main_racesim.py
python main_racesim.py > "out/$OUTPUT" #check main racesim.py for pars ini file...

#replace (undo transformation)
sed -i '635c\        rewards = 0.1 * (self.__calculate_rewards_laptime(t_pitdrive_inlap) + self.__calculate_rewards_position(delta_position))' "$obj_path" #replace entire line with this, 2 indents
sed -i '645c\            rewards += self.__calculate_rewards_final_position()' "$obj_path" #3 indents



#-- PLACE OBJ FUNCTION --

echo "----- RUNNING PLACE OBJ FUNCTION -----"
rename_strategy_place "$SUB" "placeOF" 

sed -i '635c\        rewards = 0.1 * (self.__calculate_rewards_position(delta_position))' "$obj_path"

OUTPUT="out_${SUB}_placeOF_multi.txt"

sed -i "s/race = \".*\"/race = \"${SUB}_placeOF_multi\"/" main_train_rl_agent_dqn.py 
python main_train_rl_agent_dqn.py 

#edit main_racesim input line
sed -i "s/race_pars_file_ = '.*'/race_pars_file_ = 'pars_${SUB}_placeOF_multi.ini'/" main_racesim.py
python main_racesim.py > "out/$OUTPUT"

#reset reward
sed -i '635c\        reward = 0.1 * (self.__calculate_reward_laptime(t_pitdrive_inlap) + self.__calculate_reward_position(delta_position))' "$obj_path" 

echo 0 #exit with rerutn 0
