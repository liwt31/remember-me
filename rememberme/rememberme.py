# -*- coding: utf-8 -*-

import sys
import inspect
import gc
from typing import List, Dict, Tuple


class Node(object):
    def __init__(self, obj: object):
        self.obj = obj
        self.children = []
        self.depth = 0
        self.included_set = {id(obj)}
        self.size = sys.getsizeof(obj)
        self.total_size = self.size

    def add_child(self, child: "Node", finished_dict: Dict):
        self.children.append(child)
        child.depth = min(self.depth + 1, child.depth)
        self.total_size += child.total_size
        overlap_set = self.included_set.intersection(child.included_set)
        for obj_id in overlap_set:
            self.total_size -= finished_dict[obj_id].size
        self.included_set.update(child.included_set)


class RememberMe(object):
    def __init__(self):
        self.visited_set = set()
        self.finished_dict = dict()

    def local(self, frame) -> Node:
        values = tuple(frame.f_locals.values())
        node = self.single(values)
        # subtract the tuple
        node.size = 0
        node.total_size -= sys.getsizeof(values)
        return node

    def _get_skipset(self, obj):
        skip_set = set()
        if inspect.isfunction(obj):
            attr = hasattr(obj, "__globals__")
            if attr is not None:
                skip_set.add(id(getattr(obj, "__globals__")))
        return skip_set

    def _get_referents(self, obj) -> List:
        referents = gc.get_referents(obj)
        # use this to determine ndarray without importing numpy
        if hasattr(obj, "__array_finalize__") and hasattr(obj, "base") and obj.base is not None:
            referents.append(obj.base)
        return referents

    def single(self, obj: object) -> Node:
        parent = Node(obj)
        skip_set = self._get_skipset(obj)
        for referent in self._get_referents(obj):
            if inspect.ismodule(referent):
                continue
            if id(referent) in skip_set:
                continue
            if id(referent) in self.finished_dict:
                finished_node = self.finished_dict[id(referent)]
                parent.add_child(finished_node, self.finished_dict)
                continue
            if id(referent) in self.visited_set:
                continue
            self.visited_set.add(id(referent))
            referent_node = self.single(referent)
            self.finished_dict[id(referent)] = referent_node
            parent.add_child(referent_node, self.finished_dict)
        return parent


def memory(*obj: object) -> int:
    inst = RememberMe()
    if len(obj) == 0:
        # the caller frame
        frame = inspect.stack()[1].frame
        inst = RememberMe()
        return inst.local(frame).total_size
    else:
        return inst.single(obj).total_size - sys.getsizeof(obj)


def top(*obj: object) -> List[Tuple[object, int]]:
    inst = RememberMe()
    if len(obj) == 0:
        frame = inspect.stack()[1].frame
        inst.local(frame)
    elif len(obj) == 1:
        inst.single(obj)
    else:
        node = inst.single(obj)
        # remove the tuple from
        node.total_size = 0
    res = [(node.obj, node.total_size) for node in inst.finished_dict.values()]
    res.sort(reverse=True, key=lambda x: x[1])
    return res
