extends Node

# Prints an array of node names.
func print_node_names(nodes:Array):
	var result:Array = []
	for node in nodes:
		if node != null:
			result.append(node.name)
	print(PoolStringArray(result).join(", "))

# Gets stats from a stats resource.  Requires the property name to begin with stat_.
func get_stats_from(stat_resource:Resource):
	if stat_resource == null: return {}
	var stat_keys:Array = []
	for item in stat_resource.get_property_list():
		if item.name.begins_with("stat_"):
			stat_keys.append(item.name)
	var results:Dictionary = {}
	for key in stat_keys:
		results[key] = stat_resource.get(key)
	return results


# Merges float dictionaries together by adding to repeating values.
func add_float_dictionaries(a:Dictionary, b:Dictionary):
	var results:Dictionary = {}
	for key in a.keys():
		results[key] = a[key]
	for key in b.keys():
		if results.has(key):
			results[key] += b[key]
		else: results[key] = b[key]
	return results


# Multplies a dictionary's values by a multiple.
func multiply_float_dictionary(dict:Dictionary, mult:float=1.0):
	var results:Dictionary = {}
	for key in dict.keys():
		results[key] = dict[key] * mult
	return results
