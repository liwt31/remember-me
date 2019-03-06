# -*- coding: utf-8 -*-
# cython: language_level=3
## cython: profile=True
## cython: linetrace=True

import sys
import gc
import inspect
from typing import List, Dict, Tuple

cimport cython
from cpython.module cimport PyModule_Check
from cpython.function cimport PyFunction_Check
from cpython.object cimport PyCallable_Check, PyObject_CallFunctionObjArgs
from cpython.exc cimport PyErr_CheckSignals

ctypedef Py_ssize_t size_t

cdef object _getsizeof = sys.getsizeof

cdef object _get_referents = gc.get_referents


if PyCallable_Check(_getsizeof) == 0:
    raise ValueError("sys.getsizeof not callable")

if PyCallable_Check(_get_referents) == 0:
    raise ValueError("sys.getsizeof not callable")

cdef inline size_t getsizeof(object obj):
    return PyObject_CallFunctionObjArgs(_getsizeof, <void*>obj, NULL) 


@cython.freelist(16)
@cython.no_gc
cdef class Node(object):
    cdef readonly:
        object obj
        list children
    cdef:
        size_t self_size
        size_t total_size
        set included_set

    # the function is rarely called in the main loop, make it a
    # Python function should be OK
    @property
    def size(self):
        return self.self_size if self.total_size == 0 else self.total_size


cdef inline Node get_leaf_node(object obj):
    cdef Node n = Node()
    n.obj = obj
    n.self_size = getsizeof(obj)
    n.total_size = 0  # flag to indicate leaf
    return n


cdef Node get_nonleaf_node(object obj):
    # not a leaf, need to init a lot
    cdef Node n = Node()
    cdef size_t size = getsizeof(obj)
    n.obj = obj
    n.self_size = size
    n.total_size = size
    n.children = []
    n.included_set = {id(obj), }
    return n

cdef void add_child(Node parent, Node child, dict finished_dict):
    parent.children.append(child)
    p_included_set = parent.included_set
    if child.total_size == 0:
        child_id = id(child.obj)
        if child_id in p_included_set:
            return
        parent.total_size += child.self_size
        p_included_set.add(child_id)
        return
    parent.total_size += child.total_size
    cdef set overlap_set = p_included_set.intersection(child.included_set)
    for obj_id in overlap_set:
        n = <Node>finished_dict[obj_id]
        parent.total_size -= n.self_size
    for c in child.included_set:
        p_included_set.add(c)


cdef inline list get_referents(obj):
    cdef list referents = <list>PyObject_CallFunctionObjArgs(_get_referents, <void*>obj, NULL)
    # use this to determine ndarray without importing numpy
    if (
        hasattr(obj, "__array_finalize__")
        and hasattr(obj, "base")
        and obj.base is not None
    ):
        referents.append(obj.base)
    return referents


cdef class RememberMe(object):
    cdef set skip_set
    cdef set visited_set
    cdef dict finished_dict

    def __init__(self):
        self.skip_set = set()
        self.visited_set = set()
        self.finished_dict = dict()
        for f in inspect.stack():
            self.skip_set.add(id(f.frame.f_globals))

    cdef void update_skipset(self, obj):
        if PyFunction_Check(obj):
            self.skip_set.add(id(obj.__globals__))

    cdef Node local(self, frame):
        values = tuple(frame.f_locals.values())
        node = self.single(values)
        return node

    cdef Node single(self, object obj):
        finished_dict = self.finished_dict
        obj_id = id(obj)
        cdef list referents = get_referents(obj)
        # print(obj, referents)
        if len(referents) == 0:
            node = get_leaf_node(obj)
            finished_dict[obj_id] = node
            return node
        self.update_skipset(obj)
        parent = get_nonleaf_node(obj)
        for referent in referents:
            if PyModule_Check(referent):
                continue
            ref_id = id(referent)
            if ref_id in self.skip_set:
                continue
            if ref_id in finished_dict:
                finished_node = <Node>finished_dict[ref_id]
                add_child(parent, finished_node, finished_dict)
                continue
            if ref_id in self.visited_set:
                # a random way to break cycles
                continue
            self.visited_set.add(ref_id)
            referent_node = self.single(referent)
            add_child(parent, referent_node, finished_dict)
        finished_dict[obj_id] = parent
        # a not very often position
        PyErr_CheckSignals()
        return parent


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
    res = [(node.obj, node.size) for node in inst.finished_dict.values()]
    res.sort(reverse=True, key=lambda x: x[1])
    # remove the size of the tuple from the final result
    if len(obj) != 1:
        res.pop(0)
    return res
