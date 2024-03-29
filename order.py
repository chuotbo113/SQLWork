f = open("IMDBMovie.txt")
print(next(f)) # header
for line in f:
    fields = line.strip().split(",")
        
    # Get unambiguous fields.
    id = fields.pop(0)
    rank = fields.pop(-1)
    year = fields.pop(-1)
        
    # Surround name with quotes.
    name = '"{}"'.format(",".join(fields))
    print("{},{},{},{}".format(id, name, year, rank if rank else 0))
