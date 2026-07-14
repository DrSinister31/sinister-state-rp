import json

with open('C:/Users/Dilla/Desktop/SinisterMap/public/data/pois.json', 'r') as f:
    data = json.load(f)

if 'areas' in data:
    areas = data['areas']
    
    migrations = []
    patrol_zones = []
    
    for a in areas:
        name = a.get('name', '')
        # Assign based on name
        if name in ['South Plains', 'Highland', 'Mudflats', 'Northern Jungle', 'Swamps', 'Tide Pool', 'West Coast', 'Delta Bay', 'North Plains']:
            migrations.append(a)
        else:
            patrol_zones.append(a)
            
    data['migrations'] = migrations
    data['patrol_zones'] = patrol_zones
    del data['areas']
    
    with open('C:/Users/Dilla/Desktop/SinisterMap/public/data/pois.json', 'w') as f:
        json.dump(data, f, indent=2)
    print("Successfully updated pois.json")
else:
    print("No 'areas' found in pois.json")
