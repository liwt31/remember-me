# -*- coding: utf-8 -*-

from sys import getsizeof

from rememberme import memory, top


def test_builtin():
    assert memory(1) == getsizeof(1)
    assert memory([]) == getsizeof([])
    assert memory(()) == getsizeof(())
    assert memory([2]) == getsizeof([2]) + getsizeof(2)

    s = set()
    assert memory(s) == getsizeof(s)
    s.add(None)
    assert memory(s) == getsizeof(s) + getsizeof(None)


def test_iterables():
    sz = 8
    lst = list(range(sz))
    assert memory(lst) == getsizeof(lst) + sum(getsizeof(i) for i in lst)
    assert memory(*lst) == sum(getsizeof(i) for i in lst)


def test_locals():
    a = 1
    b = None
    c = False
    d = dict()
    assert memory(a, b, c, d) == memory()


def test_dag():
    a = [1]
    b = [1]
    c = [a, b]
    assert id(a[0]) == id(b[0])  # interned integer
    assert memory(a) == getsizeof(a) + getsizeof(1)
    assert memory(c) == getsizeof(c) + getsizeof(a) + getsizeof(b) + getsizeof(1)


def test_loop():
    a = [1]
    a.append(a)
    assert memory(a) == getsizeof(a) + getsizeof(1)


def test_top():
    a = [1, 2, 3]
    b = [1, 2]
    c = [1]
    res = top()
    assert [entry[0] for entry in res[:3]] == [a, b, c]

    class Node:
        def __init__(self, data):
            self.data = data

    n = Node(a)
    # the instance is the largest
    assert top(n)[0] == (n, memory(n))
    # the type is the second
    assert top(n)[1] == (Node, memory(Node))


def test_globals():
    g = globals()
    l = [g, 1]
    assert memory(l) == getsizeof(l) + getsizeof(1)


def test_module():
    import os

    l = [os, 1]
    assert memory(l) == getsizeof(l) + getsizeof(1)
