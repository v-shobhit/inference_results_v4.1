import json
import sys

def create_json(hostnames):
    """
    Creates a JSON file with hostnames and their corresponding ports.

    Parameters:
    - hostnames: List of hostnames.
    """
    ports = [8001, 8002, 8003, 8004]
    data = {}
    for hostname in hostnames:
        # Generate a list of ports for the current hostname
        data[hostname] = ports

    # Save the data to a JSON file
    with open(sys.argv[2], 'w') as file:
        json.dump(data, file, indent=4)

# Example usage
hostnames = sys.argv[1]
hostnames = hostnames.split(',')
create_json(hostnames)

