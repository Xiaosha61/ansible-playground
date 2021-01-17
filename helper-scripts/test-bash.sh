INVENTORY_FILE=$1
if [[ $INVENTORY_FILE != *"inventory"* ]]; then
    echo "Error: $INVENTORY_FILE is not a valid inventory file name!"
    exit 1
else 
    echo "Preparing file $INVENTORY_FILE..."
fi