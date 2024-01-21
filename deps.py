#!/c/Users/isaac/scoop/shims/python3

import graphviz
import os
import re
import sys

from collections import defaultdict

deps = {}

quotes_re = re.compile("\"[^\"]*.\"")
comment_re = re.compile("#.*")
regex = re.compile("[A-Z]+[a-z]*\\w+")

ignore = ["Component", "TestUtils", "GutHookScript", "GutStringUtils", "RichButton"]
# Simulates the effect of removing the dependency between X and Y if it exists.
simulate_removals = {
}

def get_deps(directory):
    process_dir(directory)

def process_dir(directory):
    dir_list = os.listdir(directory)
    for file in dir_list:
        if file == ".git":
            continue
        if file == ".godot":
            continue
        full_path = os.path.join(directory, file)
        if os.path.isdir(full_path):
            process_dir(full_path)
            continue
        if not file.endswith(".gd"):
            continue
        f = open(full_path)
        name = ""
        results = []
        if file == "skill_manager.gd":
            name = "SkillManager"
        elif file == "online_match.gd":
            name = "OnlineMatch"
        elif file == "global.gd":
            name = "Global"
        elif file == "online.gd":
            name = "Online"
        for line in f.readlines():
            if line.startswith("class_name"):
                name = line.split(' ')[1].strip()
                continue
            else:
                line = re.sub(quotes_re, "", line)
                line = re.sub(comment_re, "", line)
                results.extend(re.findall(regex, line))
        if name:
            if name in ignore:
                continue
            results = sorted(set(results))
            if name in simulate_removals:
                results = [r for r in results if r not in simulate_removals[name]]
            deps[name] = results

class CountCycles:

	def count(self, values, pairs):
		self.graph = defaultdict(list)
		self.visited = defaultdict(lambda: 0)
		self.count = 0
		for var1, var2 in pairs:
			self.add_edge(var1,var2)

		for i in range(len(values)):
			self.depth_first_search(values[i])

		return self.count

	def add_edge(self, var1, var2):
		self.graph[var1].append(var2)

	def depth_first_search(self, var):
		# if cycle is detected
		if self.visited[var] == -1:
			self.count += 1
			print("cycle including %s" % var)
			return

		# if depth first search has been completed on this variable
		if self.visited[var] == 1:
			return

		self.visited[var] = -1

		for neighb in self.graph[var]:
			self.depth_first_search(neighb)

		#mark depth first search on this variable as completed
		self.visited[var] = 1

def main():
    get_deps(sys.argv[1])
    dot = graphviz.Digraph()
    for name in deps:
        dot.node(name)
    pairs = []
    for name in deps:
        for dep in deps[name]:
            if name != dep and dep in deps:
                dot.edge(name, dep)
                pairs.append((name, dep))
    # print(dot.source)
    dot.render()
    cycles = CountCycles()
    print(cycles.count(list(deps.keys()), pairs))

if __name__ == "__main__":
    main()
