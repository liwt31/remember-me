# -*- coding: utf-8 -*-
# distutils: language=c++
# cython: language_level=3
# cython: profile=True
# cython: linetrace=True

import sys
import gc
import inspect
from typing import List, Dict, Tuple

cimport cython
from libcpp.unordered_set cimport unordered_set as set
from libcpp.unordered_map cimport unordered_map as map


ctypedef void* optr  # object pointer
ctypedef void* nptr  # node pointer

cdef object getsizeof = sys.getsizeof
cdef object get_referents = gc.get_referents

cdef type module_type = type(sys)

def _foo(): pass

cdef type function_type = type(_foo)


cdef intersection(set[optr]& s1, set[optr]& s2, set[optr]& dst):
    if s2.size() < s1.size():
        intersection(s2, s1, dst)
        return
    # s1.size <= s2.size
    for elem in s1:
        if s2.find(elem) != s2.end():
            dst.insert(elem)
    

@cython.freelist(8)
@cython.no_gc
cdef class Node(object):
    cdef readonly:
        object obj
        list children
    cdef:
        int self_size
        int total_size
        set[optr] included_set

    def __cinit__(self, object obj, bint leaf):
        self.obj = obj
        self.self_size = getsizeof(obj)
        self.total_size = -1  # flag to indicate leaf
        # not a leaf, need to init a lot
        if leaf == 0:
            self.children = []
            self.included_set = set[optr]()
            self.included_set.insert(<optr>obj)
            self.total_size = self.size

    @property
    def size(self):
        return self.self_size if self.total_size < 0 else self.total_size


cdef add_child(Node parent, Node child, map[optr, nptr]* finished_dict):
    parent.children.append(child)
    p_included_set = &parent.included_set
    if child.total_size < 0:
        child_obj = <optr>child.obj
        if p_included_set[0].find(child_obj) != p_included_set[0].end():
            return
        parent.total_size += child.self_size
        p_included_set[0].insert(child_obj)
        return
    parent.total_size += child.total_size
    cdef set[optr] overlap_set = set[optr]()
    intersection(p_included_set[0], child.included_set, overlap_set)
    for obj_id in overlap_set:
        n = <Node>finished_dict[0][obj_id]
        parent.total_size -= n.self_size
    for c in child.included_set:
        p_included_set[0].insert(c)


cdef list _get_referents(obj):
    referents = get_referents(obj)
    # use this to determine ndarray without importing numpy
    if (
        hasattr(obj, "__array_finalize__")
        and hasattr(obj, "base")
        and obj.base is not None
    ):
        referents.append(obj.base)
    return referents

cdef _get_skipset(obj, set[optr] &skip_set):
    if isinstance(obj, function_type):
        if hasattr(obj, "__globals__"):
            skip_set.insert(<optr>obj.__globals__)


cdef class RememberMe(object):
    cdef set[optr] visited_set
    cdef map[optr, nptr] finished_dict

    def __init__(self):
        self.visited_set = set[optr]()
        self.finished_dict = map[optr, nptr]()

    cdef Node local(self, frame):
        values = tuple(frame.f_locals.values())
        node = self.single(values)
        return node

    cdef Node single(self, object obj):
        finished_dict = &self.finished_dict
        cdef list referents = _get_referents(obj)
        # print(obj, referents)
        if len(referents) == 0:
            node = <Node>Node.__new__(Node, obj, True)
            finished_dict[0][<optr>obj] = <nptr>node
            return node
        # these boilerplates are all for better performance
        cdef Node parent = <Node>Node.__new__(Node, obj, False)
        cdef set[optr] skip_set = set[optr]()
        _get_skipset(obj, skip_set)
        for referent in referents:
            if isinstance(referent, module_type):
                continue
            ref_id = <optr>referent
            if skip_set.find(ref_id) != skip_set.end():
                continue
            if finished_dict.find(ref_id) != finished_dict.end():
                finished_node = <Node>finished_dict[0][ref_id]
                add_child(parent, finished_node, finished_dict)
                continue
            if self.visited_set.find(ref_id) != self.visited_set.end():
                # a random way to break cycles
                continue
            self.visited_set.insert(ref_id)
            referent_node = self.single(referent)
            add_child(parent, referent_node, finished_dict)
        finished_dict[0][<optr>obj] = <nptr>parent
        return parent


cdef list map_to_list(map[optr, nptr]& m):
    res = []
    for pair in m:
        node = <Node>pair.second
        obj = node.obj
        sz = node.size
        res.append((obj, sz))
    return res


def memory_node(inst: RememberMe, stack_idx: int, *obj: object) -> Node:
    if len(obj) == 0:
        # the caller frame
        frame = inspect.stack()[stack_idx].frame
        # print(frame)
        return inst.local(frame)
    elif len(obj) == 1:
        return inst.single(obj[0])
    else:
        return inst.single(obj)


def memory(*obj: object) -> int:
    inst = RememberMe()
    # print(obj)
    node = memory_node(inst, 0, *obj)
    if len(obj) != 1:
        return sum([c.size for c in node.children])
    else:
        return node.size


def top(*obj: object) -> List[Tuple[object, int]]:
    inst = RememberMe()
    _ = memory_node(inst, 0, *obj)
    res = map_to_list(inst.finished_dict)
    res.sort(reverse=True, key=lambda x: x[1])
    # remove the size of the tuple from the final result
    if len(obj) != 1:
        res.pop(0)
    return res
