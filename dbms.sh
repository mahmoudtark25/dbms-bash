#! /usr/bin/bash

# This is a simple database management system using bash scripting and whiptail (for gui) running on Linux machines
# This script is written by: Mahmoud Tarek (github.com/mahmoudtark25)

# Make sure to have whiptail installed on your machine

# To install whiptail on Ubuntu: sudo apt-get install whiptail
# To install whiptail on Fedora: sudo yum install newt
# To install whiptail on Arch: sudo pacman -S newt
# To install whiptail on OpenSUSE: sudo zypper install newt
# To install whiptail on Gentoo: sudo emerge newt
# To install whiptail on Solus: sudo eopkg install newt
# To install whiptail on Void: sudo xbps-install -S newt
# To install whiptail on Alpine: sudo apk add newt

######################################################### General Checks #########################################################
# yes no box
function yesNoBox() {
    local message=$1
    echo $message
    if (whiptail --title "Yes/No Box" --yesno "${message}" 8 78); then
        answer="Yes"
        echo "User selected Yes, exit status $?"
    else
        answer="No"
        echo "User selected No, exit status $?"
    fi
}
# check inputs
function checkInput() {
    if [ -z "$1" ]; then
        input=false
    else
        input=true
    fi
}
# check if input is number
function checkNumber() {
    if [[ $1 =~ ^[0-9]+$ ]]; then
        number=true
    else
        number=false
    fi
}
# check if table exists
function checkExistingTable(){
    if [ -f "$TABLE_NAME" ]; then
        exists=true
    else
        exists=false
    fi
}
# check int data type
function checkInt() {
    if [[ $1 =~ ^[0-9]+$ ]]; then
        int=true
    else
        int=false
    fi
}

# check string data type
function checkString() {
    if [[ $1 =~ ^[a-zA-Z]+$ ]]; then
        string=true
    else
        string=false
    fi
}

####################################################################################################################################################################################
################################################################# database menu operations (Tables SQL operations) #################################################################
####################################################################################################################################################################################
# check if primary key value exists
function checkPrimaryKeyValue() {
    if grep -q "$1" "$TABLE_NAME"; then
        primary_key_value_exists=true
    else
        primary_key_value_exists=false
    fi
}
# get primary key info (name and data type)
function getPrimaryKeyInfo() {
    primary_key=$(head -n 1 $TABLE_NAME | cut -d'|' -f1 | head -1)
    primary_key_column_name=$(echo $primary_key | head -n 1 | cut -d' ' -f1 | head -1)
    primary_key_data_type=$(echo $primary_key | head -n 1 | cut -d' ' -f2 | head -1)
}

# get primary key value
function getPrimaryKeyValue() {
    primary_key_value=$(echo $record | cut -d'|' -f1 | head -1)
}
# get table head columns names and data types
function getTableColumns() {
    table_columns=()
    table_head=$(head -n 1 $TABLE_NAME)
    number_of_columns=$(echo $table_head | head -n 1 | grep -o "|" | wc -l)
    # print column by column
    for i in $(seq 1 $number_of_columns)
    do
        table_columns+=($(echo $table_head | cut -d'|' -f $i | head -1))
    done
}

# NOTE: Update function not completed yet so unexpected issues may occur (but from the first look it seems to be working fine)

################################## update table ##################################
function updateTable() {
    local message="Update another table"
    TABLE_NAME=$(whiptail --title "Update Table" --inputbox "Enter table name" 8 78 3>&1 1>&2 2>&3)
    checkExistingTable
    if ! $exists; then
        whiptail --title "Table Not Exists" --msgbox "No table found with this name" 8 78
        yesNoBox "$message"
        if [ $answer == "Yes" ]; then
            updateTable
        else
            databaseMenu
        fi
    else
        getTableColumns
        record=()
        column_number=0
        for ((i=0; i<${#table_columns[@]}; i+=2))
        do
            j=$(($i+1))
            column_name=${table_columns[$i]}
            echo $column_name
            column_datatype=${table_columns[$j]}
            echo $column_datatype
            # if [ $i == 0 ]; then
            record+=($(whiptail --title "Update Table" --inputbox "Enter a $column_datatype value for $column_name column:" 8 78 3>&1 1>&2 2>&3))
            echo ${record[@]}
            echo ${record[$column_number]}
            if [[ $column_datatype == "int" ]]; then
                echo "here in int"
                checkInt ${record[$column_number]}
                while ! $int; do
                    echo "not int"
                    whiptail --title "Invalid Input" --msgbox "Please enter a valid number" 8 78
                    record[$column_number]=$(whiptail --title "Update Table" --inputbox "Enter a $column_datatype value for $column_name column:" 8 78 3>&1 1>&2 2>&3)
                    checkInt ${record[$column_number]}
                done
            elif [[ $column_datatype == "string" ]]; then
                echo "here in string"
                checkString ${record[$column_number]}
                while ! $string; do
                    echo "not string"
                    whiptail --title "Invalid Input" --msgbox "Please enter a valid string" 8 78
                    record[$column_number]=$(whiptail --title "Update Table" --inputbox "Enter a $column_datatype value for $column_name column:" 8 78 3>&1 1>&2 2>&3)
                    checkString ${record[$column_number]}
                done
            fi
            column_number=$(($column_number+1))
        done
        getPrimaryKeyInfo
        getPrimaryKeyValue
        checkPrimaryKeyValue $primary_key_value
        if ! $primary_key_value_exists; then
            whiptail --title "Primary Key Not Exists" --msgbox "No record found with this primary key value" 8 78
            yesNoBox "$message"
            if [ $answer == "Yes" ]; then
                updateTable
            else
                databaseMenu
            fi
        else
            sed -i "/^$primary_key_value/d" $TABLE_NAME
            echo ${record[@]} >> $TABLE_NAME
            whiptail --title "Record Updated" --msgbox "Record updated successfully" 8 78
            yesNoBox "$message"
            if [ $answer == "Yes" ]; then
                updateTable
            else
                databaseMenu
            fi
        fi
    fi
}
################################# delete from table #################################
function deleteFromTable() {
    local message="Delete from another table"
    TABLE_NAME=$(whiptail --title "Delete From Table" --inputbox "Enter table name" 8 78 3>&1 1>&2 2>&3)
    checkExistingTable
    if ! $exists; then
        whiptail --title "Table Not Exists" --msgbox "No table found with this name" 8 78
        yesNoBox "$message"
        if [ $answer == "Yes" ]; then
            deleteFromTable
        else
            databaseMenu
        fi
    else
        getPrimaryKeyInfo
        primary_key_value=$(whiptail --title "Delete From Table" --inputbox "Enter primary key value" 8 78 3>&1 1>&2 2>&3)
        checkPrimaryKeyValue $primary_key_value
        if ! $primary_key_value_exists; then
            whiptail --title "Primary Key Not Exists" --msgbox "No record found with this primary key value" 8 78
            yesNoBox "$message"
            if [ $answer == "Yes" ]; then
                deleteFromTable
            else
                databaseMenu
            fi
        else
            sed -i "/^$primary_key_value/d" $TABLE_NAME
            whiptail --title "Record Deleted" --msgbox "Record deleted successfully" 8 78
            yesNoBox "$message"
            if [ $answer == "Yes" ]; then
                deleteFromTable
            else
                databaseMenu
            fi
        fi
    fi
}

#################################### insert into table ####################################
function insertIntoTable() {
    local message="Insert into another table"
    TABLE_NAME=$(whiptail --title "Insert Into Table" --inputbox "Enter table name" 8 78 3>&1 1>&2 2>&3)
    checkExistingTable
    if ! $exists; then
        whiptail --title "Table Not Exists" --msgbox "No table found with this name" 8 78
        yesNoBox "$message"
        if [ $answer == "Yes" ]; then
            insertIntoTable
        else
            databaseMenu
        fi
    else
        getTableColumns
        record=()
        column_number=0
        for ((i=0; i<${#table_columns[@]}; i+=2))
        do
            j=$(($i+1))
            column_name=${table_columns[$i]}
            echo $column_name
            column_datatype=${table_columns[$j]}
            echo $column_datatype
            # if [ $i == 0 ]; then
            record+=($(whiptail --title "Insert Into Table" --inputbox "Enter a $column_datatype value for $column_name column:" 8 78 3>&1 1>&2 2>&3))
            echo ${record[@]}
            echo ${record[$column_number]}
            if [[ $column_datatype == "int" ]]; then
                echo "here in int"
                checkInt ${record[$column_number]}
                while ! $int; do
                    echo "not int"
                    whiptail --title "Invalid Input" --msgbox "Please enter a valid number" 8 78
                    record[$column_number]=$(whiptail --title "Insert Into Table" --inputbox "Enter a $column_datatype value for $column_name column:" 8 78 3>&1 1>&2 2>&3)
                    checkInt ${record[$column_number]}
                done
            elif [[ $column_datatype == "string" ]]; then
                echo "here in string"
                checkString ${record[$column_number]}
                while ! $string; do
                    echo "not string"
                    whiptail --title "Invalid Input" --msgbox "Please enter a valid string" 8 78
                    record[$column_number]=$(whiptail --title "Insert Into Table" --inputbox "Enter a $column_datatype value for $column_name column:" 8 78 3>&1 1>&2 2>&3)
                    checkString ${record[$column_number]}
                done
            fi
            # check if primary key value exists
            if [ $column_number == 0 ]; then
                primary_key_value=${record[$column_number]}
                checkPrimaryKeyValue $primary_key_value
                while $primary_key_value_exists; do
                    whiptail --title "Invalid Input" --msgbox "Primary key value already exists" 8 78
                    record[$column_number]=$(whiptail --title "Insert Into Table" --inputbox "Enter a $column_datatype value for $column_name column:" 8 78 3>&1 1>&2 2>&3)
                    checkPrimaryKeyValue ${record[$column_number]}
                done
            fi
            column_number=$(($column_number+1))
        done
        echo ${record[@]} >> $TABLE_NAME
        databaseMenu
    fi
}

################################# select all from table #################################
function selectAllFromTable() {
    local message="Select another table"
    TABLE_NAME=$(whiptail --title "Select Table" --inputbox "Enter table name" 8 78 3>&1 1>&2 2>&3)
    checkExistingTable
    if ! $exists; then
        whiptail --title "Table Not Exists" --msgbox "No table found with this name" 8 78
        yesNoBox "$message"
        if [ $answer == "Yes" ]; then
            selectAllFromTable
        else
            databaseMenu
        fi
    else
        table_data=$(cat $TABLE_NAME)
        whiptail --title "Table Data" --msgbox "$table_data" 20 78 --scrolltext
        databaseMenu
    fi
}
# check column data type
# DATATYPES=("int", "string")
function checkDataType() {
    case $1 in
        "int")
            datatype="int"
            ;;
        "string")
            datatype="string"
            ;;
        *)
            datatype="invalid"
            ;;
    esac
}

# check existing column
function checkExistingColumn() {
    column_exists=false
    for j in "${COLUMNS[@]}" 
    do
        if [[ $j == $column_name ]]; then
            column_exists=true
            break
        fi
    done
}

######################################### create columns #########################################
function createColumns() {
    local message="Create another column"
    column_name=""
    COLUMNS=()
    echo $COLUMNS
    cancel=False
    columns_count=$(whiptail --title "Create Columns" --inputbox "How many columns you want to create in the table? (including primary key column)" 8 78 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
            checkNumber $columns_count
            if ! $number; then
                whiptail --title "Invalid Input" --msgbox "Please enter a valid number" 8 78
                createColumns
            else
                whiptail --title "Enter Columns" --msgbox "Enter ${columns_count} columns.
                    Make sure that THE FIRST COLUMN IS THE PRIMARY KEY" 8 78
                for (( i=1; i<=$columns_count; i++ ))
                do
                    echo $i
                    COLUMN_DATA=$(whiptail --title "Create Columns" --inputbox "Enter column name and data type for column ${i} 
                    in the SQL format: column_name datatype" 8 78 3>&1 1>&2 2>&3)
                    exitstatus=$?
                    if [ $exitstatus = 0 ]; then
                        column_name=$(echo $COLUMN_DATA | cut -d' ' -f1)
                        data_type=$(echo $COLUMN_DATA | cut -d' ' -f2)
                        checkInput $column_name
                        if ! $input; then
                            whiptail --title "Empty Input" --msgbox "Column name cannot be empty" 8 78
                            i=$(($i-1))
                            continue
                        fi
                        checkDataType $data_type
                        if [ $datatype == "invalid" ]; then
                            whiptail --title "Invalid Input" --msgbox "Please enter a valid data type" 8 78
                            i=$(($i-1))
                            continue
                        fi
                        if [ $i == 1 ]; then
                            PRIMARY_KEY=$column_name
                        fi
                        checkExistingColumn $column_name
                        if $column_exists; then
                            whiptail --title "Column Exists" --msgbox "Column already exists" 8 78
                            i=$(($i-1))
                            continue
                        fi

                        COLUMNS+=($column_name)
                        RAW_DATA+="$column_name $datatype|"
                    else
                        cancel=True
                        whiptail --title "Not Created" --msgbox "Table not created!" 8 78
                        break
                    fi
                    echo $i
                done
                if [ $cancel == "False" ]; then
                    touch $TABLE_NAME
                    echo $RAW_DATA >> $TABLE_NAME
                    number_of_chars=$(echo $RAW_DATA | wc -c)
                    border=""
                    for (( i=1; i<$number_of_chars; i++ ))
                    do
                        border+="-"
                    done
                    echo $border >> $TABLE_NAME
                    TABLE_HEADER=$(head -n 1 $TABLE_NAME)
                    TABLE_COLUMNS=$(echo $TABLE_HEADER | awk '{print NF}')
                    echo $TABLE_COLUMNS
                    PRIMARY_KEY=$(echo $TABLE_HEADER | awk '{print $1}')
                    echo $PRIMARY_KEY
                    whiptail --title "Table Created" --msgbox "Table has been created" 8 78
                    echo "Table Created"
                    databaseMenu
                fi
            fi
        
    else
        databaseMenu
    fi
}


################################################## create table ##################################################
function createTable() {
    local message="Create another table"
    TABLE_NAME=$(whiptail --title "Create Table" --inputbox "Enter table name:)" 8 78 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        checkInput $TABLE_NAME
        if ! $input; then
            whiptail --title "Empty Input" --msgbox "Table name cannot be empty" 8 78
            createTable
        else
            checkExistingTable 
            if $exists; then
                whiptail --title "Table Exists" --msgbox "Table already exists" 8 78
                yesNoBox "$message"
                if [ $answer == "Yes" ]; then
                    createTable
                else
                    databaseMenu
                fi
            else
                createColumns $TABLE_NAME
            fi
        fi
    else
        databaseMenu
    fi
}
################################## list tables ##################################
function listTables() {
    ls -p -I "tables_list" | grep -v / > tables_list
    whiptail --textbox tables_list 20 80 --scrolltext
    databaseMenu
}

######################################## drop table ########################################
function dropTable() {
    local message="Drop another table"
    TABLE_NAME=$(whiptail --title "Drop Table" --inputbox "Enter table name" 8 78 3>&1 1>&2 2>&3)
    checkExistingTable
    if ! $exists; then
        whiptail --title "Table Not Exists" --msgbox "No table found with this name" 8 78
        yesNoBox "$message"
        if [ $answer == "Yes" ]; then
            dropTable
        else
            databaseMenu
        fi
    else
        rm $TABLE_NAME
        whiptail --title "Table Dropped" --msgbox "Table has been dropped" 8 78
        databaseMenu
    fi
}

############################## database operations menu ########################################
function databaseMenu() {
    DATABASE_MENU=$(whiptail --title "Database Menu" --menu "Choose an option" 25 78 16 \
    "CREATE" "Create a new table." \
    "LIST" "List all tables." \
    "DROP" "Drop a table." \
    "INSERT" "Insert data into a table." \
    "SELECT" "Select data from a table." \
    "DELETE" "Delete data from a table" \
    "UPDATE" "Update a table." \
    "<-- Back" "Return to the main menu." 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
            case $DATABASE_MENU in
        CREATE)
            createTable
            ;;
        LIST)
            listTables
            ;;
        DROP)
            dropTable
            ;;
        INSERT)
            insertIntoTable
            ;;
        SELECT)
            selectAllFromTable
            ;;
        DELETE)
            deleteFromTable
            ;;
        UPDATE)
            updateTable
            ;;
        "<-- Back")
            cd ..
            mainMenu
            ;;
    esac
    else
        cd ..
        mainMenu
    fi 

}

############################################################################################################################
############################################## Main Menu Operations (Database operations) ##############################################
############################################################################################################################
# check if database exists
function checkExistingDatabase(){
    if [ -d "$DATABASE_NAME" ]; then
        exists=true
    else
        exists=false
    fi
}

################################################ Drop Database ################################################
function dropDatabase(){
    local message="Drop another Database"
    DATABASE_NAME=$(whiptail --title "Drop Database" --inputbox "Enter database name" 8 78 3>&1 1>&2 2>&3)
    checkExistingDatabase
    if ! $exists; then
        whiptail --title "Database Not Exists" --msgbox "No database found with this name" 8 78
        yesNoBox "$message"
        if [ $answer == "Yes" ]; then
            dropDatabase
        else
            mainMenu
        fi
    else
        rm -r $DATABASE_NAME
        whiptail --title "Database Dropped" --msgbox "Database has been dropped" 8 78
        mainMenu
    fi
}
####################################### list all databases #######################################
function listDatabases(){
    ls -d */ > databases_list
    whiptail --textbox databases_list 12 80 --scrolltext
    mainMenu
}

################################################# create New Database #################################################
function createNewDatabase(){
    local message="Create another Database"
    DATABASE_NAME=$(whiptail --title "Create New Database" --inputbox "Enter database name" 8 78 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        checkInput $DATABASE_NAME
        if ! $input; then
            whiptail --title "Empty Input" --msgbox "Database name cannot be empty" 8 78
            createNewDatabase
        else
            checkExistingDatabase
            if $exists; then
                whiptail --title "Database Exists" --msgbox "Database already exists" 8 78
                yesNoBox "$message"
                if [ $answer == "Yes" ]; then
                    createNewDatabase
                    whiptail --title "Database Created" --msgbox "Database has been created" 8 78
                    echo "Database Created"
                    mainMenu
                else
                    mainMenu
                fi
            else
                mkdir $DATABASE_NAME
                whiptail --title "Database Created" --msgbox "Database has been created" 8 78
                mainMenu
            fi
        fi
    else
        mainMenu
    fi
}

################################################# connect to database #################################################
function connectToDatabase() {
    local message="Connect to another Database"
    DATABASE_NAME=$(whiptail --title "Connect To Database" --inputbox "Enter database name" 8 78 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        checkInput $DATABASE_NAME
        if ! $input; then
            whiptail --title "Empty Input" --msgbox "Database name cannot be empty" 8 78
            connectToDatabase
        fi
        checkExistingDatabase
        if ! $exists; then
            whiptail --title "Database Not Exists" --msgbox "No database found with this name" 8 78
            yesNoBox "$message"
            if [ $answer == "Yes" ]; then
                connectToDatabase
            else
                mainMenu
            fi
        else
            {
            for ((i = 0 ; i <= 100 ; i+=5)); do
                sleep 0.1
                echo $i
            done
            } | whiptail --gauge "Please wait while connecting to ${DATABASE_NAME}" 6 50 0
            whiptail --title "Connected" --msgbox "Connected to ${DATABASE_NAME} database. Hit OK to go to database menu." 8 78
            cd $DATABASE_NAME
            databaseMenu
        fi
    else
        mainMenu
        echo "User selected Cancel."
    fi
}

############################################### main menu #################################################
function mainMenu() {
    MAIN_MENU=$(whiptail --title "Main Menu" --menu "Choose an option" 25 78 16 \
    "CREATE" "Create a new database." \
    "LIST" "List all databases." \
    "CONNECT" "Connect to a database." \
    "DROP" "Drop a database." 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        case $MAIN_MENU in
            CREATE)
                createNewDatabase
                ;;
            LIST)
                listDatabases
                ;;
            CONNECT)
                connectToDatabase
                ;;

            DROP)
                dropDatabase
                ;;
        esac
    else
        echo "User selected Cancel."
    fi
}

mainMenu
