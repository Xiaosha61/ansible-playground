# maybe delete current inventory if exists
# bash helper-scripts/prepare-inventory-file.sh inventory-ec2 
# bash helper-scripts/prepare-inventory-file.sh inventory-ec2 --delete

INVENTORY_FILE=$1

if [[ $INVENTORY_FILE != *"inventory"* ]]; then
    echo "Error: $INVENTORY_FILE is not a valid inventory file name!"
    exit 1
fi

echo "Preparing file $INVENTORY_FILE..."

if test -f "$INVENTORY_FILE"; then
    echo "$INVENTORY_FILE exists."
    if [ "$2" == "--delete" ]; then
        echo "--delete option is set. Deleting the existing $INVENTORY_FILE file..."
        rm $INVENTORY_FILE

        echo "Creating a new $INVENTORY_FILE file..."
        echo "[all]" > $INVENTORY_FILE
    else 
        echo "--delete option is not set. Keep using existing $INVENTORY_FILE..."
    fi
else 
    echo "$INVENTORY_FILE does not exist, creating one..."
    echo "[all]" > $INVENTORY_FILE
fi