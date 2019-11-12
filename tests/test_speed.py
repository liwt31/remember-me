# -*- coding: utf-8 -*-

import random

from rememberme import memory


class Node:
    def __init__(self):
        self.edge1 = self.edge2 = None

    def link(self, other):
        self.edge1 = other
        other.edge2 = self


# should take about half a minute
def test_speed():
    random.seed(2019)
    nodes = [Node() for i in range(10000)]
    for i in range(10 * len(nodes)):
        node1 = random.choice(nodes)
        node2 = random.choice(nodes)
        # only works after py36
        # node1, node2 = random.choices(nodes, k=2)
        node1.link(node2)
    memory(nodes)
